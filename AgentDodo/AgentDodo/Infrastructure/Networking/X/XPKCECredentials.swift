import Foundation

nonisolated struct XPKCECredentials: Sendable {
    let codeVerifier: String
    let codeChallenge: String
}
