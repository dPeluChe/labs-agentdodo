import Foundation

actor OllamaClient {
    private let keychain: KeychainManager
    private var baseURL: URL
    
    static let shared = OllamaClient()
    
    private init() {
        self.keychain = KeychainManager.shared
        self.baseURL = URL(string: "http://127.0.0.1:11434")!
    }
    
    // MARK: - Configuration
    
    func configure(baseURL: String) async throws {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        self.baseURL = url
        try await keychain.save(baseURL, for: .ollamaBaseURL)
    }
    
    func loadConfiguration() async {
        if let saved = try? await keychain.retrieve(.ollamaBaseURL),
           let url = URL(string: saved) {
            self.baseURL = url
        }
    }
    
    // MARK: - Health Check
    
    func isAvailable() async -> Bool {
        let url = baseURL.appendingPathComponent("api/tags")
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    // MARK: - List Models
    
    func listModels() async throws -> [OllamaModel] {
        let url = baseURL.appendingPathComponent("api/tags")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(OllamaModelsResponse.self, from: data)
        return result.models
    }
    
    // MARK: - Generate (Non-Streaming)
    
    func generate(
        model: String,
        prompt: String,
        system: String? = nil,
        options: OllamaOptions? = nil
    ) async throws -> OllamaGenerateResponse {
        let url = baseURL.appendingPathComponent("api/generate")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false
        ]
        
        if let system = system {
            body["system"] = system
        }
        
        if let options = options {
            body["options"] = options.dictionary
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
    }
    
    // MARK: - Generate (Streaming)
    
    func generateStream(
        model: String,
        prompt: String,
        system: String? = nil,
        options: OllamaOptions? = nil
    ) -> AsyncThrowingStream<OllamaStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let url = baseURL.appendingPathComponent("api/generate")
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                var body: [String: Any] = [
                    "model": model,
                    "prompt": prompt,
                    "stream": true
                ]
                
                if let system = system {
                    body["system"] = system
                }
                
                if let options = options {
                    body["options"] = options.dictionary
                }
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }
                    
                    for try await line in bytes.lines {
                        guard !line.isEmpty else { continue }
                        
                        if let data = line.data(using: .utf8) {
                            let chunk = try JSONDecoder().decode(OllamaStreamChunk.self, from: data)
                            continuation.yield(chunk)
                            
                            if chunk.done {
                                break
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Chat (Non-Streaming)
    
    func chat(
        model: String,
        messages: [OllamaChatMessage],
        options: OllamaOptions? = nil
    ) async throws -> OllamaChatResponse {
        let url = baseURL.appendingPathComponent("api/chat")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "model": model,
            "messages": messages.map { $0.dictionary },
            "stream": false
        ]
        
        if let options = options {
            body["options"] = options.dictionary
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(OllamaChatResponse.self, from: data)
    }
    
    // MARK: - Chat (Streaming)
    
    func chatStream(
        model: String,
        messages: [OllamaChatMessage],
        options: OllamaOptions? = nil
    ) -> AsyncThrowingStream<OllamaChatStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let url = baseURL.appendingPathComponent("api/chat")
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                var body: [String: Any] = [
                    "model": model,
                    "messages": messages.map { $0.dictionary },
                    "stream": true
                ]
                
                if let options = options {
                    body["options"] = options.dictionary
                }
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }
                    
                    for try await line in bytes.lines {
                        guard !line.isEmpty else { continue }
                        
                        if let data = line.data(using: .utf8) {
                            let chunk = try JSONDecoder().decode(OllamaChatStreamChunk.self, from: data)
                            continuation.yield(chunk)
                            
                            if chunk.done {
                                break
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Embeddings
    
    func embeddings(model: String, prompt: String) async throws -> [Double] {
        let url = baseURL.appendingPathComponent("api/embeddings")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "prompt": prompt
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(OllamaEmbeddingsResponse.self, from: data)
        return result.embedding
    }
}

// MARK: - Models

struct OllamaModelsResponse: Decodable, Sendable {
    let models: [OllamaModel]
}

struct OllamaModel: Decodable, Identifiable, Sendable {
    let name: String
    let modifiedAt: String?
    let size: Int64?
    let digest: String?
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case modifiedAt = "modified_at"
        case size
        case digest
    }
}

struct OllamaGenerateResponse: Decodable, Sendable {
    let model: String
    let createdAt: String
    let response: String
    let done: Bool
    let totalDuration: Int64?
    let evalCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case response
        case done
        case totalDuration = "total_duration"
        case evalCount = "eval_count"
    }
}

struct OllamaStreamChunk: Decodable, Sendable {
    let model: String
    let createdAt: String?
    let response: String
    let done: Bool
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case response
        case done
    }
}

struct OllamaChatMessage: Sendable {
    let role: String // "system", "user", "assistant"
    let content: String
    
    var dictionary: [String: String] {
        ["role": role, "content": content]
    }
    
    static func system(_ content: String) -> OllamaChatMessage {
        OllamaChatMessage(role: "system", content: content)
    }
    
    static func user(_ content: String) -> OllamaChatMessage {
        OllamaChatMessage(role: "user", content: content)
    }
    
    static func assistant(_ content: String) -> OllamaChatMessage {
        OllamaChatMessage(role: "assistant", content: content)
    }
}

struct OllamaChatResponse: Decodable, Sendable {
    let model: String
    let createdAt: String
    let message: OllamaChatResponseMessage
    let done: Bool
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case message
        case done
    }
}

struct OllamaChatResponseMessage: Decodable, Sendable {
    let role: String
    let content: String
}

struct OllamaChatStreamChunk: Decodable, Sendable {
    let model: String
    let createdAt: String?
    let message: OllamaChatResponseMessage?
    let done: Bool
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case message
        case done
    }
}

struct OllamaEmbeddingsResponse: Decodable, Sendable {
    let embedding: [Double]
}

struct OllamaOptions: Sendable {
    var temperature: Double?
    var topP: Double?
    var topK: Int?
    var numPredict: Int?
    var stop: [String]?
    var seed: Int?
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [:]
        if let temperature = temperature { dict["temperature"] = temperature }
        if let topP = topP { dict["top_p"] = topP }
        if let topK = topK { dict["top_k"] = topK }
        if let numPredict = numPredict { dict["num_predict"] = numPredict }
        if let stop = stop { dict["stop"] = stop }
        if let seed = seed { dict["seed"] = seed }
        return dict
    }
}
