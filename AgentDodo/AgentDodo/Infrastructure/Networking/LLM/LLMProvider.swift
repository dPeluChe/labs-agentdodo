import Foundation
import Combine

// MARK: - Unified LLM Provider Protocol

protocol LLMProvider {
    var name: String { get }
    var isAvailable: Bool { get async }
    
    func generate(prompt: String, system: String?, options: LLMOptions?) async throws -> String
    func generateStream(prompt: String, system: String?, options: LLMOptions?) -> AsyncThrowingStream<String, Error>
}

// MARK: - Unified Options

struct LLMOptions: Sendable {
    var temperature: Double?
    var maxTokens: Int?
    var topP: Double?
    var stopSequences: [String]?
    
    static let `default` = LLMOptions(temperature: 0.7, maxTokens: 1024)
    static let creative = LLMOptions(temperature: 0.9, maxTokens: 2048)
    static let precise = LLMOptions(temperature: 0.3, maxTokens: 1024)
}

// MARK: - LLM Manager (Unified Interface)

@MainActor
class LLMManager: ObservableObject {
    static let shared = LLMManager()
    
    @Published private(set) var availableProviders: [LLMProviderType] = []
    @Published var selectedProvider: LLMProviderType = .ollama
    @Published var selectedModel: String = "llama3.2"
    
    private init() {}
    
    // MARK: - Provider Types
    
    enum LLMProviderType: String, CaseIterable, Identifiable {
        case ollama = "Ollama"
        case gemini = "Gemini"
        case openai = "OpenAI"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .ollama: return "desktopcomputer"
            case .gemini: return "sparkles"
            case .openai: return "brain"
            }
        }
        
        var description: String {
            switch self {
            case .ollama: return "Local LLM (Privacy-first)"
            case .gemini: return "Google Gemini API"
            case .openai: return "OpenAI API"
            }
        }
    }
    
    // MARK: - Check Availability
    
    func refreshAvailability() async {
        var available: [LLMProviderType] = []
        
        // Check Ollama
        if await OllamaClient.shared.isAvailable() {
            available.append(.ollama)
        }
        
        // Check Gemini
        if await GeminiClient.shared.isConfigured {
            available.append(.gemini)
        }
        
        // Check OpenAI (if implemented)
        // if await OpenAIClient.shared.isConfigured { available.append(.openai) }
        
        await MainActor.run {
            self.availableProviders = available
        }
    }
    
    // MARK: - Generate
    
    func generate(
        prompt: String,
        system: String? = nil,
        options: LLMOptions? = nil
    ) async throws -> String {
        switch selectedProvider {
        case .ollama:
            let response = try await OllamaClient.shared.generate(
                model: selectedModel,
                prompt: prompt,
                system: system,
                options: options.map { OllamaOptions(
                    temperature: $0.temperature,
                    topP: $0.topP,
                    numPredict: $0.maxTokens,
                    stop: $0.stopSequences
                )}
            )
            return response.response
            
        case .gemini:
            let response = try await GeminiClient.shared.generateContent(
                model: selectedModel,
                prompt: prompt,
                systemInstruction: system,
                generationConfig: options.map { GeminiGenerationConfig(
                    temperature: $0.temperature,
                    topP: $0.topP,
                    maxOutputTokens: $0.maxTokens,
                    stopSequences: $0.stopSequences
                )}
            )
            return response.text ?? ""
            
        case .openai:
            throw APIError.custom(message: "OpenAI not yet implemented")
        }
    }
    
    // MARK: - Stream Generate
    
    func generateStream(
        prompt: String,
        system: String? = nil,
        options: LLMOptions? = nil
    ) -> AsyncThrowingStream<String, Error> {
        let provider = selectedProvider
        let model = selectedModel
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    switch provider {
                    case .ollama:
                        let ollamaOptions = options.map { OllamaOptions(
                            temperature: $0.temperature,
                            topP: $0.topP,
                            numPredict: $0.maxTokens,
                            stop: $0.stopSequences
                        )}
                        
                        let stream = await OllamaClient.shared.generateStream(
                            model: model,
                            prompt: prompt,
                            system: system,
                            options: ollamaOptions
                        )
                        
                        for try await chunk in stream {
                            continuation.yield(chunk.response)
                        }
                        
                    case .gemini:
                        let geminiConfig = options.map { GeminiGenerationConfig(
                            temperature: $0.temperature,
                            topP: $0.topP,
                            maxOutputTokens: $0.maxTokens,
                            stopSequences: $0.stopSequences
                        )}
                        
                        let stream = await GeminiClient.shared.generateContentStream(
                            model: model,
                            prompt: prompt,
                            systemInstruction: system,
                            generationConfig: geminiConfig
                        )
                        
                        for try await chunk in stream {
                            if let text = chunk.text {
                                continuation.yield(text)
                            }
                        }
                        
                    case .openai:
                        throw APIError.custom(message: "OpenAI not yet implemented")
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Available Models
    
    func getAvailableModels() async throws -> [String] {
        switch selectedProvider {
        case .ollama:
            let models = try await OllamaClient.shared.listModels()
            return models.map { $0.name }
        case .gemini:
            let models = try await GeminiClient.shared.listModels()
            return models.filter { $0.supportedGenerationMethods?.contains("generateContent") == true }
                .map { $0.name.replacingOccurrences(of: "models/", with: "") }
        case .openai:
            return ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]
        }
    }
}

// MARK: - AI Assistant Use Cases

enum AIAssistantTask {
    case improveWriting(text: String, tone: String)
    case generateVariations(text: String, count: Int)
    case summarize(text: String)
    case translate(text: String, targetLanguage: String)
    case checkGrammar(text: String)
    case suggestHashtags(text: String)
    case expandIdea(text: String)
    
    var systemPrompt: String {
        switch self {
        case .improveWriting(_, let tone):
            return """
            You are a social media writing assistant. Improve the given text to be more engaging while maintaining a \(tone) tone.
            Keep it concise (under 280 characters for tweets). Output only the improved text, no explanations.
            """
        case .generateVariations(_, let count):
            return """
            You are a creative writing assistant. Generate \(count) different variations of the given text.
            Each variation should have a unique angle or style. Keep each under 280 characters.
            Output only the variations, numbered 1 to \(count), no explanations.
            """
        case .summarize:
            return """
            You are a text summarizer. Summarize the given text concisely while preserving key information.
            Keep it under 280 characters. Output only the summary, no explanations.
            """
        case .translate(_, let targetLanguage):
            return """
            You are a translator. Translate the given text to \(targetLanguage).
            Maintain the original tone and style. Output only the translation, no explanations.
            """
        case .checkGrammar:
            return """
            You are a grammar checker. Correct any grammar, spelling, or punctuation errors in the given text.
            Output only the corrected text, no explanations.
            """
        case .suggestHashtags:
            return """
            You are a social media expert. Suggest 3-5 relevant hashtags for the given text.
            Output only the hashtags separated by spaces, no explanations.
            """
        case .expandIdea:
            return """
            You are a creative writing assistant. Expand the given idea into a full social media post.
            Keep it engaging and under 280 characters. Output only the expanded text, no explanations.
            """
        }
    }
    
    var prompt: String {
        switch self {
        case .improveWriting(let text, _),
             .summarize(let text),
             .checkGrammar(let text),
             .suggestHashtags(let text),
             .expandIdea(let text):
            return text
        case .generateVariations(let text, _):
            return text
        case .translate(let text, _):
            return text
        }
    }
}

extension LLMManager {
    func execute(_ task: AIAssistantTask, options: LLMOptions? = nil) async throws -> String {
        return try await generate(
            prompt: task.prompt,
            system: task.systemPrompt,
            options: options ?? .default
        )
    }
}
