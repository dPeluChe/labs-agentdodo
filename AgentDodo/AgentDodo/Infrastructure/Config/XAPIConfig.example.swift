import Foundation

// MARK: - X API Configuration Template
// Copy this file to XAPIConfig.swift and fill in your credentials
// XAPIConfig.swift is gitignored for security

enum XAPIConfig {
    // OAuth 1.0a Credentials (User Context)
    static let consumerKey = "YOUR_CONSUMER_KEY"
    static let consumerSecret = "YOUR_CONSUMER_SECRET"
    static let accessToken = "YOUR_ACCESS_TOKEN"
    static let accessTokenSecret = "YOUR_ACCESS_TOKEN_SECRET"
    
    // App-only Bearer Token (for read-only operations)
    static let bearerToken = "YOUR_BEARER_TOKEN"
    
    // App Info
    static let appName = "AgentDodo"
    static let appId = "YOUR_APP_ID"
}
