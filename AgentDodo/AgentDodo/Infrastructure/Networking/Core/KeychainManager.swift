import Foundation
import Security

actor KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.agentdodo.credentials"
    
    private init() {}
    
    // MARK: - Keys
    
    enum Key: String {
        case xClientId = "x_client_id"
        case xClientSecret = "x_client_secret"
        case xAccessToken = "x_access_token"
        case xRefreshToken = "x_refresh_token"
        case xApiKey = "x_api_key"
        case xApiSecret = "x_api_secret"
        case xAccessTokenSecret = "x_access_token_secret"
        case geminiApiKey = "gemini_api_key"
        case ollamaBaseURL = "ollama_base_url"
        case openAIApiKey = "openai_api_key"
    }
    
    // MARK: - Save
    
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
    
    // MARK: - Retrieve
    
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
    
    // MARK: - Delete
    
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
    
    // MARK: - Check if exists
    
    func exists(_ key: Key) -> Bool {
        do {
            return try retrieve(key) != nil
        } catch {
            return false
        }
    }
    
    // MARK: - Clear All
    
    func clearAll() throws {
        for key in [Key.xClientId, .xClientSecret, .xAccessToken, .xRefreshToken, .geminiApiKey, .ollamaBaseURL, .openAIApiKey] {
            try delete(key)
        }
    }
}

// MARK: - Keychain Error

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
