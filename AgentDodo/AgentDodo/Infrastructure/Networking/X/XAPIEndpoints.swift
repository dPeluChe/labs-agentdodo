import Foundation

enum XAPIEndpoint: APIEndpoint {
    // OAuth 2.0 PKCE
    case authorize(clientId: String, redirectURI: String, codeChallenge: String, scopes: [XScope])
    case token(clientId: String, code: String, codeVerifier: String, redirectURI: String)
    case refreshToken(clientId: String, refreshToken: String)
    case revokeToken(token: String)
    
    // Tweets
    case createTweet(text: String, replyTo: String?)
    case deleteTweet(id: String)
    case getTweet(id: String)
    case getUserTweets(userId: String, maxResults: Int)
    
    // Users
    case getMe
    case getUser(id: String)
    case getUserByUsername(username: String)
    
    // Media
    case uploadMediaInit(totalBytes: Int, mediaType: String)
    case uploadMediaAppend(mediaId: String, segmentIndex: Int)
    case uploadMediaFinalize(mediaId: String)
    
    // Timeline
    case homeTimeline(maxResults: Int, paginationToken: String?)
    case mentions(userId: String, maxResults: Int)
    
    var baseURL: URL {
        switch self {
        case .authorize:
            return URL(string: "https://twitter.com")!
        case .uploadMediaInit, .uploadMediaAppend, .uploadMediaFinalize:
            return URL(string: "https://upload.twitter.com")!
        default:
            return URL(string: "https://api.twitter.com")!
        }
    }
    
    var path: String {
        switch self {
        case .authorize:
            return "/i/oauth2/authorize"
        case .token, .refreshToken:
            return "/2/oauth2/token"
        case .revokeToken:
            return "/2/oauth2/revoke"
        case .createTweet, .deleteTweet:
            return "/2/tweets"
        case .getTweet(let id):
            return "/2/tweets/\(id)"
        case .getUserTweets(let userId, _):
            return "/2/users/\(userId)/tweets"
        case .getMe:
            return "/2/users/me"
        case .getUser(let id):
            return "/2/users/\(id)"
        case .getUserByUsername(let username):
            return "/2/users/by/username/\(username)"
        case .uploadMediaInit, .uploadMediaAppend, .uploadMediaFinalize:
            return "/1.1/media/upload.json"
        case .homeTimeline:
            return "/2/tweets/search/recent"
        case .mentions(let userId, _):
            return "/2/users/\(userId)/mentions"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .authorize, .getTweet, .getUserTweets, .getMe, .getUser, .getUserByUsername, .homeTimeline, .mentions:
            return .GET
        case .token, .refreshToken, .revokeToken, .createTweet, .uploadMediaInit, .uploadMediaAppend, .uploadMediaFinalize:
            return .POST
        case .deleteTweet:
            return .DELETE
        }
    }
    
    var headers: [String: String] {
        switch self {
        case .token, .refreshToken, .revokeToken:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        default:
            return ["Content-Type": "application/json"]
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .authorize(let clientId, let redirectURI, let codeChallenge, let scopes):
            return [
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "redirect_uri", value: redirectURI),
                URLQueryItem(name: "scope", value: scopes.map(\.rawValue).joined(separator: " ")),
                URLQueryItem(name: "state", value: UUID().uuidString),
                URLQueryItem(name: "code_challenge", value: codeChallenge),
                URLQueryItem(name: "code_challenge_method", value: "S256")
            ]
        case .getUserTweets(_, let maxResults):
            return [
                URLQueryItem(name: "max_results", value: "\(maxResults)"),
                URLQueryItem(name: "tweet.fields", value: "created_at,public_metrics,entities")
            ]
        case .homeTimeline(let maxResults, let paginationToken):
            var items = [
                URLQueryItem(name: "max_results", value: "\(maxResults)"),
                URLQueryItem(name: "tweet.fields", value: "created_at,author_id,public_metrics")
            ]
            if let token = paginationToken {
                items.append(URLQueryItem(name: "pagination_token", value: token))
            }
            return items
        case .mentions(_, let maxResults):
            return [
                URLQueryItem(name: "max_results", value: "\(maxResults)"),
                URLQueryItem(name: "tweet.fields", value: "created_at,author_id")
            ]
        case .getMe:
            return [
                URLQueryItem(name: "user.fields", value: "profile_image_url,description,public_metrics")
            ]
        default:
            return nil
        }
    }
    
    var body: Data? {
        switch self {
        case .token(let clientId, let code, let codeVerifier, let redirectURI):
            let params = [
                "grant_type": "authorization_code",
                "client_id": clientId,
                "code": code,
                "redirect_uri": redirectURI,
                "code_verifier": codeVerifier
            ]
            return params.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
            
        case .refreshToken(let clientId, let refreshToken):
            let params = [
                "grant_type": "refresh_token",
                "client_id": clientId,
                "refresh_token": refreshToken
            ]
            return params.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
            
        case .revokeToken(let token):
            return "token=\(token)".data(using: .utf8)
            
        case .createTweet(let text, let replyTo):
            var payload: [String: Any] = ["text": text]
            if let replyTo = replyTo {
                payload["reply"] = ["in_reply_to_tweet_id": replyTo]
            }
            return try? JSONSerialization.data(withJSONObject: payload)
            
        case .uploadMediaInit(let totalBytes, let mediaType):
            let params = [
                "command": "INIT",
                "total_bytes": "\(totalBytes)",
                "media_type": mediaType
            ]
            return params.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
            
        case .uploadMediaFinalize(let mediaId):
            return "command=FINALIZE&media_id=\(mediaId)".data(using: .utf8)
            
        default:
            return nil
        }
    }
    
    var requiresAuth: Bool {
        switch self {
        case .authorize, .token, .refreshToken:
            return false
        default:
            return true
        }
    }
    
    var timeout: TimeInterval {
        switch self {
        case .uploadMediaInit, .uploadMediaAppend, .uploadMediaFinalize:
            return 120
        default:
            return 30
        }
    }
}

// MARK: - X API Scopes

enum XScope: String {
    case tweetRead = "tweet.read"
    case tweetWrite = "tweet.write"
    case usersRead = "users.read"
    case offlineAccess = "offline.access"
    case likesRead = "like.read"
    case likesWrite = "like.write"
    case followsRead = "follows.read"
    case followsWrite = "follows.write"
    case bookmarkRead = "bookmark.read"
    case bookmarkWrite = "bookmark.write"
}
