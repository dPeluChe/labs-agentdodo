import Foundation
import AuthenticationServices
import AppKit

enum XOAuth2AuthError: LocalizedError, Equatable {
    case unableToStart
    case missingCallbackURL
    case missingAuthorizationCode
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .unableToStart:
            return "Unable to start X OAuth session"
        case .missingCallbackURL:
            return "Missing OAuth callback URL"
        case .missingAuthorizationCode:
            return "Missing authorization code in callback URL"
        case .cancelled:
            return "OAuth session cancelled"
        }
    }
}

final class XOAuth2AuthorizationSession: NSObject {
    private var session: ASWebAuthenticationSession?
    
    func start(url: URL, callbackScheme: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error = error as? ASWebAuthenticationSessionError {
                    print("[X OAuth2] Session error: \(error.code) \(error.localizedDescription)")
                } else if let error = error {
                    print("[X OAuth2] Session error: \(error.localizedDescription)")
                }
                
                if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    continuation.resume(throwing: XOAuth2AuthError.cancelled)
                    return
                }
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: XOAuth2AuthError.missingCallbackURL)
                    return
                }
                
                continuation.resume(returning: callbackURL)
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            
            self.session = session
            
            if !session.start() {
                continuation.resume(throwing: XOAuth2AuthError.unableToStart)
            }
        }
    }
}

extension XOAuth2AuthorizationSession: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let window = NSApplication.shared.keyWindow {
            return window
        }
        if let window = NSApplication.shared.windows.first {
            return window
        }
        return ASPresentationAnchor()
    }
}
