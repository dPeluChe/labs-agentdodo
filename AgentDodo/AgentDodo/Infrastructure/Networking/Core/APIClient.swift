import Foundation

actor APIClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    static let shared = APIClient()
    
    init(configuration: URLSessionConfiguration = .default) {
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        
        self.session = URLSession(configuration: configuration)
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Generic Request
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard var request = endpoint.urlRequest else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await performRequest(request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        try validateResponse(httpResponse, data: data)
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Request without response body
    
    func request(_ endpoint: APIEndpoint) async throws {
        guard let request = endpoint.urlRequest else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await performRequest(request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        try validateResponse(httpResponse, data: data)
    }
    
    // MARK: - Streaming Request (for LLM APIs)
    
    func stream<T: Decodable>(_ endpoint: APIEndpoint) -> AsyncThrowingStream<T, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard let request = endpoint.urlRequest else {
                    continuation.finish(throwing: APIError.invalidURL)
                    return
                }
                
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: APIError.httpError(statusCode: httpResponse.statusCode, data: nil))
                        return
                    }
                    
                    for try await line in bytes.lines {
                        // Handle SSE format (data: {...})
                        let cleanLine = line.hasPrefix("data: ") ? String(line.dropFirst(6)) : line
                        
                        guard !cleanLine.isEmpty, cleanLine != "[DONE]" else { continue }
                        
                        if let data = cleanLine.data(using: .utf8) {
                            do {
                                let decoded = try self.decoder.decode(T.self, from: data)
                                continuation.yield(decoded)
                            } catch {
                                // Skip malformed lines in stream
                                continue
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: APIError.networkError(error))
                }
            }
        }
    }
    
    // MARK: - Upload Request (for media)
    
    func upload<T: Decodable>(
        _ endpoint: APIEndpoint,
        fileData: Data,
        fileName: String,
        mimeType: String
    ) async throws -> T {
        guard var components = URLComponents(
            url: endpoint.baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        ) else {
            throw APIError.invalidURL
        }
        components.queryItems = endpoint.queryItems
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = 120 // Longer timeout for uploads
        
        // Multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, response) = try await performRequest(request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        try validateResponse(httpResponse, data: data)
        
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Private Helpers
    
    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw APIError.timeout
            case .cancelled:
                throw APIError.cancelled
            case .notConnectedToInternet, .networkConnectionLost:
                throw APIError.networkError(error)
            default:
                throw APIError.networkError(error)
            }
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    private func validateResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            throw APIError.rateLimited(retryAfter: retryAfter)
        case 500...599:
            let message = String(data: data, encoding: .utf8)
            throw APIError.serverError(message: message)
        default:
            throw APIError.httpError(statusCode: response.statusCode, data: data)
        }
    }
}
