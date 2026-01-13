import Foundation
import CryptoKit
import AuthenticationServices

actor XAPIClient {
    private let apiClient: APIClient
    private let keychain: KeychainManager
    
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiresAt: Date?
    
    static let shared = XAPIClient()
    
    private init() {
        self.apiClient = APIClient.shared
        self.keychain = KeychainManager.shared
    }
    
    // MARK: - OAuth 2.0 PKCE
    
    nonisolated static func generatePKCE() -> XPKCECredentials {
        // Generate random code verifier (43-128 characters)
        let verifier = generateRandomString(length: 64)
        
        // Create code challenge using SHA256
        let challengeData = Data(verifier.utf8)
        let hashed = SHA256.hash(data: challengeData)
        let challenge = Data(hashed).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        return XPKCECredentials(codeVerifier: verifier, codeChallenge: challenge)
    }
    
    nonisolated private static func generateRandomString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    nonisolated func getAuthorizationURL(
        clientId: String,
        redirectURI: String,
        scopes: [XScope] = [.tweetRead, .tweetWrite, .usersRead, .offlineAccess]
    ) -> (url: URL, pkce: XPKCECredentials)? {
        let pkce = Self.generatePKCE()
        
        let endpoint = XAPIEndpoint.authorize(
            clientId: clientId,
            redirectURI: redirectURI,
            codeChallenge: pkce.codeChallenge,
            scopes: scopes
        )
        
        guard let request = endpoint.urlRequest else { return nil }
        
        return (request.url!, pkce)
    }
    
    func exchangeCodeForToken(
        clientId: String,
        code: String,
        codeVerifier: String,
        redirectURI: String
    ) async throws -> XTokenResponse {
        let endpoint = XAPIEndpoint.token(
            clientId: clientId,
            code: code,
            codeVerifier: codeVerifier,
            redirectURI: redirectURI
        )
        
        let response: XTokenResponse = try await apiClient.request(endpoint)
        
        // Store tokens securely
        try await keychain.save(response.accessToken, for: .xAccessToken)
        if let refresh = response.refreshToken {
            try await keychain.save(refresh, for: .xRefreshToken)
        }
        
        self.accessToken = response.accessToken
        self.refreshToken = response.refreshToken
        self.tokenExpiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        
        return response
    }
    
    func refreshAccessToken() async throws {
        guard let clientId = try await keychain.retrieve(.xClientId),
              let refreshToken = try await keychain.retrieve(.xRefreshToken) else {
            throw APIError.unauthorized
        }
        
        let endpoint = XAPIEndpoint.refreshToken(clientId: clientId, refreshToken: refreshToken)
        let response: XTokenResponse = try await apiClient.request(endpoint)
        
        // Update stored tokens
        try await keychain.save(response.accessToken, for: .xAccessToken)
        if let refresh = response.refreshToken {
            try await keychain.save(refresh, for: .xRefreshToken)
        }
        
        self.accessToken = response.accessToken
        self.refreshToken = response.refreshToken
        self.tokenExpiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))
    }
    
    func logout() async throws {
        if let token = accessToken {
            let endpoint = XAPIEndpoint.revokeToken(token: token)
            try? await apiClient.request(endpoint)
        }
        
        try await keychain.delete(.xAccessToken)
        try await keychain.delete(.xRefreshToken)
        
        accessToken = nil
        refreshToken = nil
        tokenExpiresAt = nil
    }
    
    // MARK: - Token Management
    
    private func getValidAccessToken() async throws -> String {
        // Check if we have a valid token
        if let token = accessToken, let expiresAt = tokenExpiresAt, expiresAt > Date() {
            return token
        }
        
        // Try to load from keychain
        if let token = try await keychain.retrieve(.xAccessToken) {
            accessToken = token
            return token
        }
        
        // Try to refresh
        try await refreshAccessToken()
        
        guard let token = accessToken else {
            throw APIError.unauthorized
        }
        
        return token
    }
    
    // MARK: - API Methods
    
    func getMe() async throws -> XUser {
        let token = try await getValidAccessToken()
        let endpoint = XAPIEndpoint.getMe
        let response: XUserResponse = try await authenticatedRequest(endpoint, token: token)
        return response.data
    }
    
    func createTweet(text: String, replyTo: String? = nil) async throws -> XTweet {
        let token = try await getValidAccessToken()
        let endpoint = XAPIEndpoint.createTweet(text: text, replyTo: replyTo)
        let response: XTweetResponse = try await authenticatedRequest(endpoint, token: token)
        return response.data
    }
    
    func deleteTweet(id: String) async throws {
        let token = try await getValidAccessToken()
        let endpoint = XAPIEndpoint.deleteTweet(id: id)
        _ = try await authenticatedRequest(endpoint, token: token) as XDeleteResponse
    }
    
    func getUserTweets(userId: String, maxResults: Int = 10) async throws -> [XTweet] {
        let token = try await getValidAccessToken()
        let endpoint = XAPIEndpoint.getUserTweets(userId: userId, maxResults: maxResults)
        let response: XTweetsResponse = try await authenticatedRequest(endpoint, token: token)
        return response.data ?? []
    }
    
    func getHomeTimeline(maxResults: Int = 20, paginationToken: String? = nil) async throws -> XTweetsResponse {
        let token = try await getValidAccessToken()
        let endpoint = XAPIEndpoint.homeTimeline(maxResults: maxResults, paginationToken: paginationToken)
        return try await authenticatedRequest(endpoint, token: token)
    }
    
    func getMentions(userId: String, maxResults: Int = 20) async throws -> [XTweet] {
        let token = try await getValidAccessToken()
        let endpoint = XAPIEndpoint.mentions(userId: userId, maxResults: maxResults)
        let response: XTweetsResponse = try await authenticatedRequest(endpoint, token: token)
        return response.data ?? []
    }
    
    // MARK: - Authenticated Request Helper
    
    private func authenticatedRequest<T: Decodable>(_ endpoint: APIEndpoint, token: String) async throws -> T {
        guard let request = endpoint.urlRequest else {
            throw APIError.invalidURL
        }
        
        var mutableRequest = request
        
        mutableRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: mutableRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            // Token expired, try to refresh
            try await refreshAccessToken()
            return try await authenticatedRequest(endpoint, token: accessToken!)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Connection Status
    
    var isAuthenticated: Bool {
        get async {
            do {
                return try await keychain.retrieve(.xAccessToken) != nil
            } catch {
                return false
            }
        }
    }
}

// MARK: - Response Models

nonisolated struct XTokenResponse: Decodable, Sendable {
    let tokenType: String
    let expiresIn: Int
    let accessToken: String
    let refreshToken: String?
    let scope: String
}

nonisolated struct XUserResponse: Decodable, Sendable {
    let data: XUser
}

nonisolated struct XUser: Decodable, Identifiable, Sendable {
    let id: String
    let name: String
    let username: String
    let profileImageUrl: String?
    let description: String?
    let publicMetrics: XPublicMetrics?
}

nonisolated struct XPublicMetrics: Decodable, Sendable {
    let followersCount: Int?
    let followingCount: Int?
    let tweetCount: Int?
    let listedCount: Int?
}

nonisolated struct XTweetResponse: Decodable, Sendable {
    let data: XTweet
}

nonisolated struct XTweetsResponse: Decodable, Sendable {
    let data: [XTweet]?
    let meta: XMeta?
}

nonisolated struct XTweet: Decodable, Identifiable, Sendable {
    let id: String
    let text: String
    let authorId: String?
    let createdAt: String?
    let publicMetrics: XTweetMetrics?
}

nonisolated struct XTweetMetrics: Decodable, Sendable {
    let retweetCount: Int?
    let replyCount: Int?
    let likeCount: Int?
    let quoteCount: Int?
    let impressionCount: Int?
}

nonisolated struct XMeta: Decodable, Sendable {
    let resultCount: Int?
    let nextToken: String?
    let previousToken: String?
}

nonisolated struct XDeleteResponse: Decodable, Sendable {
    let data: XDeleteData
}

nonisolated struct XDeleteData: Decodable, Sendable {
    let deleted: Bool
}
