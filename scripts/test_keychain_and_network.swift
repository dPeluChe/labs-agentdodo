#!/usr/bin/env swift

import Foundation

// MARK: - Keychain Test Script
// Test if keychain operations work correctly

// Mock KeychainManager for testing
actor MockKeychainManager {
    private let service = "com.agentdodo.credentials"

    enum Key: String {
        case xApiKey = "x_api_key"
        case xApiSecret = "x_api_secret"
        case xAccessToken = "x_access_token"
        case xAccessTokenSecret = "x_access_token_secret"
    }

    func save(_ value: String, for key: Key) throws {
        let data = value.data(using: .utf8)!

        // Delete existing item first
        try? delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status)
        }
    }

    func retrieve(_ key: Key) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.unableToRetrieve(status)
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    func delete(_ key: Key) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case unableToSave(OSStatus)
    case unableToRetrieve(OSStatus)
    case unableToDelete(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unableToSave(let status):
            return "Unable to save to Keychain: \(status)"
        case .unableToRetrieve(let status):
            return "Unable to retrieve from Keychain: \(status)"
        case .unableToDelete(let status):
            return "Unable to delete from Keychain: \(status)"
        }
    }
}

// Test credentials
let testConsumerKey = "xAoY7l2a8vqxRqdsYLRxV801v"
let testConsumerSecret = "lPu4gVLyNxEyAg7560swfocv3DcYy5MnAKZuTwA5D7kOv8J6Ls"
let testAccessToken = "104845477-Oa7zf2Yjhy4rbrLoDMLmcqtYrpv8h2ax9NjK7Say"
let testAccessTokenSecret = "1x1XOXoUEe6qLsScfyfPSFGACvAZ0Ovq6LnNZNWUIfidP"

print("=== Keychain Test ===\n")

let keychain = MockKeychainManager()

Task {
    do {
        print("1. Saving credentials...")
        try await keychain.save(testConsumerKey, for: .xApiKey)
        try await keychain.save(testConsumerSecret, for: .xApiSecret)
        try await keychain.save(testAccessToken, for: .xAccessToken)
        try await keychain.save(testAccessTokenSecret, for: .xAccessTokenSecret)
        print("✓ Credentials saved successfully\n")

        print("2. Retrieving credentials...")
        let retrievedConsumerKey = try await keychain.retrieve(.xApiKey)
        let retrievedConsumerSecret = try await keychain.retrieve(.xApiSecret)
        let retrievedAccessToken = try await keychain.retrieve(.xAccessToken)
        let retrievedAccessTokenSecret = try await keychain.retrieve(.xAccessTokenSecret)

        print("Consumer Key: \(retrievedConsumerKey?.prefix(10) ?? "nil")...")
        print("Consumer Secret: \(retrievedConsumerSecret?.prefix(10) ?? "nil")...")
        print("Access Token: \(retrievedAccessToken?.prefix(15) ?? "nil")...")
        print("Access Token Secret: \(retrievedAccessTokenSecret?.prefix(10) ?? "nil")...")

        let allRetrieved = retrievedConsumerKey != nil &&
                          retrievedConsumerSecret != nil &&
                          retrievedAccessToken != nil &&
                          retrievedAccessTokenSecret != nil

        print("✓ All credentials retrieved: \(allRetrieved)\n")

        print("3. Testing network connectivity...")
        let testURL = URL(string: "https://httpbin.org/get")!
        let (data, response) = try await URLSession.shared.data(from: testURL)

        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status: \(httpResponse.statusCode)")
            print("✓ Network connectivity works\n")
        }

        print("4. Testing X API connectivity...")
        let xURL = URL(string: "https://api.twitter.com/2/users/me")!
        var request = URLRequest(url: xURL)
        request.httpMethod = "GET"

        // Simple request without auth to test connectivity
        let (xData, xResponse) = try await URLSession.shared.data(from: xURL)

        if let httpResponse = xResponse as? HTTPURLResponse {
            print("X API Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 {
                print("✓ X API reachable (401 Unauthorized expected without auth)")
            } else {
                print("✓ X API reachable")
            }
        }

    } catch {
        print("❌ Error: \(error)")
    }

    exit(0)
}

RunLoop.main.run()
