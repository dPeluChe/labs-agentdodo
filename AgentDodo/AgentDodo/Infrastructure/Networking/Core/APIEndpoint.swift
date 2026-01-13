import Foundation

protocol APIEndpoint: Sendable {
    nonisolated var baseURL: URL { get }
    nonisolated var path: String { get }
    nonisolated var method: HTTPMethod { get }
    nonisolated var headers: [String: String] { get }
    nonisolated var queryItems: [URLQueryItem]? { get }
    nonisolated var body: Data? { get }
    nonisolated var requiresAuth: Bool { get }
    nonisolated var timeout: TimeInterval { get }
}

extension APIEndpoint {
    var headers: [String: String] { [:] }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
    var requiresAuth: Bool { true }
    var timeout: TimeInterval { 30 }
    
    nonisolated var urlRequest: URLRequest? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.timeoutInterval = timeout
        
        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Custom headers
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
}

enum HTTPMethod: String, Sendable {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}
