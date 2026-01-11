import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case unauthorized
    case rateLimited(retryAfter: Int?)
    case serverError(message: String?)
    case timeout
    case cancelled
    case noData
    case custom(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidRequest:
            return "Invalid request configuration"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, _):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized - please check your credentials"
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Rate limited - retry after \(seconds) seconds"
            }
            return "Rate limited - please try again later"
        case .serverError(let message):
            return message ?? "Server error occurred"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        case .noData:
            return "No data received"
        case .custom(let message):
            return message
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .rateLimited, .timeout, .serverError:
            return true
        case .httpError(let statusCode, _):
            return statusCode >= 500
        default:
            return false
        }
    }
}
