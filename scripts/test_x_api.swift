#!/usr/bin/env swift

import Foundation
import CryptoKit

// X API OAuth 1.0a Test Script
// Run with: swift scripts/test_x_api.swift

// MARK: - Credentials
let consumerKey = "xAoY7l2a8vqxRqdsYLRxV801v"
let consumerSecret = "lPu4gVLyNxEyAg7560swfocv3DcYy5MnAKZuTwA5D7kOv8J6Ls"
let accessToken = "104845477-Oa7zf2Yjhy4rbrLoDMLmcqtYrpv8h2ax9NjK7Say"
let accessTokenSecret = "1x1XOXoUEe6qLsScfyfPSFGACvAZ0Ovq6LnNZNWUIfidP"

// MARK: - Helper Functions

func percentEncode(_ string: String) -> String {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-._~")
    return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
}

func generateNonce() -> String {
    let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<32).map { _ in characters.randomElement()! })
}

func generateTimestamp() -> String {
    String(Int(Date().timeIntervalSince1970))
}

func generateOAuthSignature(
    httpMethod: String,
    baseURL: String,
    parameters: [String: String]
) -> String {
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
    
    print("Signature Base String:")
    print(signatureBaseString)
    print("")
    
    // Create signing key
    let signingKey = "\(percentEncode(consumerSecret))&\(percentEncode(accessTokenSecret))"
    
    // Generate HMAC-SHA1 signature
    let key = SymmetricKey(data: Data(signingKey.utf8))
    let signature = HMAC<Insecure.SHA1>.authenticationCode(
        for: Data(signatureBaseString.utf8),
        using: key
    )
    
    return Data(signature).base64EncodedString()
}

func buildAuthorizationHeader(
    httpMethod: String,
    url: URL
) -> String {
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
    
    // Get base URL without query string
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
    let queryItems = components.queryItems ?? []
    components.queryItems = nil
    let baseURL = components.url!.absoluteString
    
    // Add query parameters to signature params
    var allParams = oauthParams
    for item in queryItems {
        if let value = item.value {
            allParams[item.name] = value
        }
    }
    
    // Generate signature
    let signature = generateOAuthSignature(
        httpMethod: httpMethod,
        baseURL: baseURL,
        parameters: allParams
    )
    
    oauthParams["oauth_signature"] = signature
    
    // Build header string
    let headerParams = oauthParams
        .sorted { $0.key < $1.key }
        .map { "\(percentEncode($0.key))=\"\(percentEncode($0.value))\"" }
        .joined(separator: ", ")
    
    return "OAuth \(headerParams)"
}

// MARK: - Test Functions

func testGetMe() async {
    print("=== Testing GET /2/users/me ===\n")
    
    let url = URL(string: "https://api.twitter.com/2/users/me?user.fields=profile_image_url,description,public_metrics")!
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    let authHeader = buildAuthorizationHeader(httpMethod: "GET", url: url)
    print("Authorization Header:")
    print(authHeader)
    print("")
    
    request.setValue(authHeader, forHTTPHeaderField: "Authorization")
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            print("Response:")
            print(prettyString)
        } else if let responseString = String(data: data, encoding: .utf8) {
            print("Response (raw):")
            print(responseString)
        }
    } catch {
        print("Error: \(error)")
    }
}

func testPostTweet() async {
    print("\n=== Testing POST /2/tweets ===\n")
    
    let url = URL(string: "https://api.twitter.com/2/tweets")!
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let authHeader = buildAuthorizationHeader(httpMethod: "POST", url: url)
    print("Authorization Header:")
    print(authHeader)
    print("")
    
    request.setValue(authHeader, forHTTPHeaderField: "Authorization")
    
    // Tweet body
    let tweetText = "Test from AgentDodo 🐦 \(Date())"
    let body = ["text": tweetText]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    print("Tweet text: \(tweetText)")
    print("")
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            print("Response:")
            print(prettyString)
        } else if let responseString = String(data: data, encoding: .utf8) {
            print("Response (raw):")
            print(responseString)
        }
    } catch {
        print("Error: \(error)")
    }
}

// MARK: - Main

print("X API OAuth 1.0a Test\n")
print("Consumer Key: \(consumerKey.prefix(10))...")
print("Access Token: \(accessToken.prefix(15))...")
print("")

// Run tests
Task {
    await testGetMe()
    // Test posting:
    await testPostTweet()
    exit(0)
}

RunLoop.main.run()
