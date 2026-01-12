import Foundation

actor GeminiClient {
    private let keychain: KeychainManager
    private let baseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta")!
    
    static let shared = GeminiClient()
    
    private init() {
        self.keychain = KeychainManager.shared
    }
    
    // MARK: - Configuration
    
    func configure(apiKey: String) async throws {
        try await keychain.save(apiKey, for: .geminiApiKey)
    }
    
    private func getAPIKey() async throws -> String {
        guard let key = try await keychain.retrieve(.geminiApiKey) else {
            throw APIError.unauthorized
        }
        return key
    }
    
    var isConfigured: Bool {
        get async {
            do {
                return try await keychain.retrieve(.geminiApiKey) != nil
            } catch {
                return false
            }
        }
    }
    
    // MARK: - List Models
    
    func listModels() async throws -> [GeminiModel] {
        let apiKey = try await getAPIKey()
        let url = baseURL.appendingPathComponent("models")
            .appending(queryItems: [URLQueryItem(name: "key", value: apiKey)])
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(GeminiModelsResponse.self, from: data)
        return result.models
    }
    
    // MARK: - Generate Content (Non-Streaming)
    
    func generateContent(
        model: String = "gemini-pro",
        prompt: String,
        systemInstruction: String? = nil,
        generationConfig: GeminiGenerationConfig? = nil,
        safetySettings: [GeminiSafetySetting]? = nil
    ) async throws -> GeminiResponse {
        let apiKey = try await getAPIKey()
        let url = baseURL
            .appendingPathComponent("models/\(model):generateContent")
            .appending(queryItems: [URLQueryItem(name: "key", value: apiKey)])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        
        if let systemInstruction = systemInstruction {
            body["systemInstruction"] = ["parts": [["text": systemInstruction]]]
        }
        
        if let config = generationConfig {
            body["generationConfig"] = config.dictionary
        }
        
        if let safety = safetySettings {
            body["safetySettings"] = safety.map { $0.dictionary }
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 400 {
            if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                throw APIError.custom(message: errorResponse.error.message)
            }
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return try JSONDecoder().decode(GeminiResponse.self, from: data)
    }
    
    // MARK: - Generate Content (Streaming)
    
    func generateContentStream(
        model: String = "gemini-pro",
        prompt: String,
        systemInstruction: String? = nil,
        generationConfig: GeminiGenerationConfig? = nil
    ) -> AsyncThrowingStream<GeminiStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let apiKey = try await getAPIKey()
                    let url = baseURL
                        .appendingPathComponent("models/\(model):streamGenerateContent")
                        .appending(queryItems: [
                            URLQueryItem(name: "key", value: apiKey),
                            URLQueryItem(name: "alt", value: "sse")
                        ])
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    var body: [String: Any] = [
                        "contents": [
                            ["parts": [["text": prompt]]]
                        ]
                    ]
                    
                    if let systemInstruction = systemInstruction {
                        body["systemInstruction"] = ["parts": [["text": systemInstruction]]]
                    }
                    
                    if let config = generationConfig {
                        body["generationConfig"] = config.dictionary
                    }
                    
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }
                    
                    for try await line in bytes.lines {
                        // Handle SSE format
                        let cleanLine = line.hasPrefix("data: ") ? String(line.dropFirst(6)) : line
                        
                        guard !cleanLine.isEmpty else { continue }
                        
                        if let data = cleanLine.data(using: .utf8) {
                            do {
                                let chunk = try JSONDecoder().decode(GeminiStreamChunk.self, from: data)
                                continuation.yield(chunk)
                            } catch {
                                continue
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
    
    // MARK: - Chat (Multi-turn)
    
    func chat(
        model: String = "gemini-pro",
        messages: [GeminiChatMessage],
        systemInstruction: String? = nil,
        generationConfig: GeminiGenerationConfig? = nil
    ) async throws -> GeminiResponse {
        let apiKey = try await getAPIKey()
        let url = baseURL
            .appendingPathComponent("models/\(model):generateContent")
            .appending(queryItems: [URLQueryItem(name: "key", value: apiKey)])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "contents": messages.map { $0.dictionary }
        ]
        
        if let systemInstruction = systemInstruction {
            body["systemInstruction"] = ["parts": [["text": systemInstruction]]]
        }
        
        if let config = generationConfig {
            body["generationConfig"] = config.dictionary
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(GeminiResponse.self, from: data)
    }
    
    // MARK: - Count Tokens
    
    func countTokens(model: String = "gemini-pro", text: String) async throws -> Int {
        let apiKey = try await getAPIKey()
        let url = baseURL
            .appendingPathComponent("models/\(model):countTokens")
            .appending(queryItems: [URLQueryItem(name: "key", value: apiKey)])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [["parts": [["text": text]]]]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(GeminiTokenCountResponse.self, from: data)
        return result.totalTokens
    }
    
    // MARK: - Embeddings
    
    func embedContent(model: String = "embedding-001", text: String) async throws -> [Double] {
        let apiKey = try await getAPIKey()
        let url = baseURL
            .appendingPathComponent("models/\(model):embedContent")
            .appending(queryItems: [URLQueryItem(name: "key", value: apiKey)])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "models/\(model)",
            "content": ["parts": [["text": text]]]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(GeminiEmbeddingResponse.self, from: data)
        return result.embedding.values
    }
}

// MARK: - Models

struct GeminiModelsResponse: Decodable, Sendable {
    let models: [GeminiModel]
}

struct GeminiModel: Decodable, Identifiable, Sendable {
    let name: String
    let displayName: String?
    let description: String?
    let inputTokenLimit: Int?
    let outputTokenLimit: Int?
    let supportedGenerationMethods: [String]?
    
    var id: String { name }
}

struct GeminiResponse: Decodable, Sendable {
    let candidates: [GeminiCandidate]?
    let promptFeedback: GeminiPromptFeedback?
    let usageMetadata: GeminiUsageMetadata?
    
    var text: String? {
        candidates?.first?.content.parts.first?.text
    }
}

struct GeminiCandidate: Decodable, Sendable {
    let content: GeminiContent
    let finishReason: String?
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiContent: Decodable, Sendable {
    let parts: [GeminiPart]
    let role: String?
}

struct GeminiPart: Decodable, Sendable {
    let text: String?
}

struct GeminiPromptFeedback: Decodable, Sendable {
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiSafetyRating: Decodable, Sendable {
    let category: String
    let probability: String
}

struct GeminiUsageMetadata: Decodable, Sendable {
    let promptTokenCount: Int?
    let candidatesTokenCount: Int?
    let totalTokenCount: Int?
}

struct GeminiStreamChunk: Decodable, Sendable {
    let candidates: [GeminiCandidate]?
    
    var text: String? {
        candidates?.first?.content.parts.first?.text
    }
}

struct GeminiChatMessage: Sendable {
    let role: String // "user" or "model"
    let text: String
    
    var dictionary: [String: Any] {
        [
            "role": role,
            "parts": [["text": text]]
        ]
    }
    
    static func user(_ text: String) -> GeminiChatMessage {
        GeminiChatMessage(role: "user", text: text)
    }
    
    static func model(_ text: String) -> GeminiChatMessage {
        GeminiChatMessage(role: "model", text: text)
    }
}

struct GeminiGenerationConfig: Sendable {
    var temperature: Double?
    var topP: Double?
    var topK: Int?
    var maxOutputTokens: Int?
    var stopSequences: [String]?
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [:]
        if let temperature = temperature { dict["temperature"] = temperature }
        if let topP = topP { dict["topP"] = topP }
        if let topK = topK { dict["topK"] = topK }
        if let maxOutputTokens = maxOutputTokens { dict["maxOutputTokens"] = maxOutputTokens }
        if let stopSequences = stopSequences { dict["stopSequences"] = stopSequences }
        return dict
    }
}

struct GeminiSafetySetting: Sendable {
    let category: GeminiHarmCategory
    let threshold: GeminiHarmBlockThreshold
    
    var dictionary: [String: String] {
        [
            "category": category.rawValue,
            "threshold": threshold.rawValue
        ]
    }
}

enum GeminiHarmCategory: String, Sendable {
    case harassment = "HARM_CATEGORY_HARASSMENT"
    case hateSpeech = "HARM_CATEGORY_HATE_SPEECH"
    case sexuallyExplicit = "HARM_CATEGORY_SEXUALLY_EXPLICIT"
    case dangerousContent = "HARM_CATEGORY_DANGEROUS_CONTENT"
}

enum GeminiHarmBlockThreshold: String, Sendable {
    case blockNone = "BLOCK_NONE"
    case blockLowAndAbove = "BLOCK_LOW_AND_ABOVE"
    case blockMediumAndAbove = "BLOCK_MEDIUM_AND_ABOVE"
    case blockOnlyHigh = "BLOCK_ONLY_HIGH"
}

struct GeminiTokenCountResponse: Decodable, Sendable {
    let totalTokens: Int
}

struct GeminiEmbeddingResponse: Decodable, Sendable {
    let embedding: GeminiEmbedding
}

struct GeminiEmbedding: Decodable, Sendable {
    let values: [Double]
}

struct GeminiErrorResponse: Decodable, Sendable {
    let error: GeminiError
}

struct GeminiError: Decodable, Sendable {
    let code: Int
    let message: String
    let status: String
}
