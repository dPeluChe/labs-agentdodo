import Foundation
import CryptoKit

// MARK: - X API OAuth 1.0a Client
// Uses consumer key/secret + access token/secret for authentication

actor XOAuth1Client {
    private let keychain: KeychainManager
    
    // OAuth 1.0a credentials
    private var consumerKey: String?
    private var consumerSecret: String?
    private var accessToken: String?
    private var accessTokenSecret: String?
    
    static let shared = XOAuth1Client()
    
    private init() {
        self.keychain = KeychainManager.shared
    }
    
    // MARK: - Configuration
    
    func configure(
        consumerKey: String,
        consumerSecret: String,
        accessToken: String,
        accessTokenSecret: String
    ) async throws {
        print("[XOAuth1Client] Configuring with consumer key: \(consumerKey.prefix(10))...")
        
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.accessToken = accessToken
        self.accessTokenSecret = accessTokenSecret
        
        // Store in keychain for persistence
        try await keychain.save(consumerKey, for: .xApiKey)
        try await keychain.save(consumerSecret, for: .xApiSecret)
        try await keychain.save(accessToken, for: .xAccessToken)
        try await keychain.save(accessTokenSecret, for: .xAccessTokenSecret)
        
        print("[XOAuth1Client] Configuration saved to keychain successfully")
    }
    
    func loadCredentials() async {
        consumerKey = try? await keychain.retrieve(.xApiKey)
        consumerSecret = try? await keychain.retrieve(.xApiSecret)
        accessToken = try? await keychain.retrieve(.xAccessToken)
        accessTokenSecret = try? await keychain.retrieve(.xAccessTokenSecret)
        
        print("[XOAuth1Client] Loaded credentials - isConfigured: \(isConfigured)")
    }
    
    var isConfigured: Bool {
        consumerKey != nil && consumerSecret != nil && accessToken != nil && accessTokenSecret != nil
    }
    
    // MARK: - OAuth 1.0a Signature Generation
    
    private func generateOAuthSignature(
        httpMethod: String,
        baseURL: String,
        parameters: [String: String]
    ) -> String? {
        guard let consumerSecret = consumerSecret,
              let tokenSecret = accessTokenSecret else {
            return nil
        }
        
        // Sort parameters alphabetically
        let sortedParams = parameters.sorted { $0.key < $1.key }
        let parameterString = sortedParams
            .map { "\(percentEncode($0.key))=\(percentEncode($0.value))" }
            .joined(separator: "&")
        
        // Create signature base string
        let signatureBaseString = [
            httpMethod.uppercased(),
            percentEncode(baseURL),
            percentEncode(parameterString)
        ].joined(separator: "&")
        
        // Create signing key
        let signingKey = "\(percentEncode(consumerSecret))&\(percentEncode(tokenSecret))"
        
        // Generate HMAC-SHA1 signature
        let key = SymmetricKey(data: Data(signingKey.utf8))
        let signature = HMAC<Insecure.SHA1>.authenticationCode(
            for: Data(signatureBaseString.utf8),
            using: key
        )
        
        return Data(signature).base64EncodedString()
    }
    
    private func percentEncode(_ string: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
    
    private func generateNonce() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in characters.randomElement()! })
    }
    
    private func generateTimestamp() -> String {
        String(Int(Date().timeIntervalSince1970))
    }
    
    // MARK: - Build Authorization Header
    
    private func buildAuthorizationHeader(
        httpMethod: String,
        url: URL,
        additionalParams: [String: String] = [:]
    ) -> String? {
        guard let consumerKey = consumerKey,
              let accessToken = accessToken else {
            return nil
        }
        
        let nonce = generateNonce()
        let timestamp = generateTimestamp()
        
        // OAuth parameters
        var oauthParams: [String: String] = [
            "oauth_consumer_key": consumerKey,
            "oauth_nonce": nonce,
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": timestamp,
            "oauth_token": accessToken,
            "oauth_version": "1.0"
        ]
        
        // Combine with additional parameters for signature
        var allParams = oauthParams
        additionalParams.forEach { allParams[$0.key] = $0.value }
        
        // Get base URL without query string
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        components.queryItems = nil
        let baseURL = components.url!.absoluteString
        
        // Add query parameters to signature params
        for item in queryItems {
            if let value = item.value {
                allParams[item.name] = value
            }
        }
        
        // Generate signature
        guard let signature = generateOAuthSignature(
            httpMethod: httpMethod,
            baseURL: baseURL,
            parameters: allParams
        ) else {
            return nil
        }
        
        oauthParams["oauth_signature"] = signature
        
        // Build header string
        let headerParams = oauthParams
            .sorted { $0.key < $1.key }
            .map { "\(percentEncode($0.key))=\"\(percentEncode($0.value))\"" }
            .joined(separator: ", ")
        
        return "OAuth \(headerParams)"
    }
    
    // MARK: - API Methods
    
    func postTweet(text: String) async throws -> XOAuth1TweetResponse {
        guard isConfigured else {
            throw XOAuth1Error.notConfigured
        }
        
        let url = URL(string: "https://api.twitter.com/2/tweets")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build OAuth header
        guard let authHeader = buildAuthorizationHeader(httpMethod: "POST", url: url) else {
            throw XOAuth1Error.signatureError
        }
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        // Body
        let body = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw XOAuth1Error.invalidResponse
        }
        
        if httpResponse.statusCode == 201 {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(XOAuth1TweetResponse.self, from: data)
        } else {
            // Try to parse error
            if let errorResponse = try? JSONDecoder().decode(XOAuth1ErrorResponse.self, from: data) {
                throw XOAuth1Error.apiError(
                    code: httpResponse.statusCode,
                    message: errorResponse.detail ?? errorResponse.title ?? "Unknown error"
                )
            }
            throw XOAuth1Error.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    func getMe() async throws -> XOAuth1UserResponse {
        guard isConfigured else {
            throw XOAuth1Error.notConfigured
        }
        
        let url = URL(string: "https://api.twitter.com/2/users/me?user.fields=profile_image_url,description,public_metrics")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        guard let authHeader = buildAuthorizationHeader(httpMethod: "GET", url: url) else {
            throw XOAuth1Error.signatureError
        }
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw XOAuth1Error.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw XOAuth1Error.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(XOAuth1UserResponse.self, from: data)
    }
    
    func deleteTweet(id: String) async throws {
        guard isConfigured else {
            throw XOAuth1Error.notConfigured
        }
        
        let url = URL(string: "https://api.twitter.com/2/tweets/\(id)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        guard let authHeader = buildAuthorizationHeader(httpMethod: "DELETE", url: url) else {
            throw XOAuth1Error.signatureError
        }
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw XOAuth1Error.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw XOAuth1Error.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    func verifyCredentials() async throws -> Bool {
        do {
            _ = try await getMe()
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Response Models

struct XOAuth1TweetResponse: Decodable, Sendable {
    let data: XOAuth1TweetData
}

struct XOAuth1TweetData: Decodable, Sendable {
    let id: String
    let text: String
}

struct XOAuth1UserResponse: Decodable, Sendable {
    let data: XOAuth1UserData
}

struct XOAuth1UserData: Decodable, Sendable {
    let id: String
    let name: String
    let username: String
    let profileImageUrl: String?
    let description: String?
    let publicMetrics: XOAuth1PublicMetrics?
}

struct XOAuth1PublicMetrics: Decodable, Sendable {
    let followersCount: Int?
    let followingCount: Int?
    let tweetCount: Int?
    let listedCount: Int?
}

struct XOAuth1ErrorResponse: Decodable, Sendable {
    let title: String?
    let detail: String?
    let type: String?
    let status: Int?
}

// MARK: - Errors

enum XOAuth1Error: LocalizedError, Sendable {
    case notConfigured
    case signatureError
    case invalidResponse
    case httpError(statusCode: Int)
    case apiError(code: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "X API credentials not configured"
        case .signatureError:
            return "Failed to generate OAuth signature"
        case .invalidResponse:
            return "Invalid response from X API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(_, let message):
            return message
        }
    }
}
