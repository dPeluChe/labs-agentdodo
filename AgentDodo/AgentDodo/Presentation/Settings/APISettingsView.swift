import SwiftUI
import Combine

struct APISettingsView: View {
    @StateObject private var viewModel = APISettingsViewModel()
    
    var body: some View {
        Form {
            // X (Twitter) API Section
            xAPISection
            
            // LLM Providers Section
            llmProvidersSection
        }
        .formStyle(.grouped)
        .task {
            await viewModel.checkAllConnections()
        }
    }
    
    // MARK: - X API Section
    
    private var xAPISection: some View {
        Section {
            HStack {
                Image(systemName: "bird")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("X (Twitter)")
                        .font(.headline)
                    Text(viewModel.xConnectionStatus.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                connectionBadge(viewModel.xConnectionStatus)
            }
            
            if viewModel.xConnectionStatus == .disconnected {
                TextField("Client ID", text: $viewModel.xClientId)
                    .textFieldStyle(.roundedBorder)
                
                SecureField("Client Secret", text: $viewModel.xClientSecret)
                    .textFieldStyle(.roundedBorder)
                
                Button("Connect with X") {
                    Task { await viewModel.connectX() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.xClientId.isEmpty || viewModel.xClientSecret.isEmpty)
            } else if viewModel.xConnectionStatus == .connected {
                if let user = viewModel.xUser {
                    HStack {
                        Text("Logged in as")
                            .foregroundStyle(.secondary)
                        Text("@\(user.username)")
                            .fontWeight(.medium)
                    }
                }
                
                Button("Disconnect", role: .destructive) {
                    Task { await viewModel.disconnectX() }
                }
            }
        } header: {
            Text("Social Platform")
        }
    }
    
    // MARK: - LLM Providers Section
    
    private var llmProvidersSection: some View {
        Section {
            // Ollama (Local)
            ollamaRow
            
            Divider()
            
            // Gemini
            geminiRow
            
            Divider()
            
            // OpenAI (Coming Soon)
            openAIRow
        } header: {
            Text("AI Providers")
        } footer: {
            Text("Configure AI providers for writing assistance features")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var ollamaRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "desktopcomputer")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ollama")
                        .font(.headline)
                    Text("Local LLM - Privacy First")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                connectionBadge(viewModel.ollamaStatus)
            }
            
            HStack {
                TextField("Base URL", text: $viewModel.ollamaBaseURL)
                    .textFieldStyle(.roundedBorder)
                
                Button("Test") {
                    Task { await viewModel.testOllama() }
                }
                .buttonStyle(.bordered)
            }
            
            if viewModel.ollamaStatus == .connected, !viewModel.ollamaModels.isEmpty {
                Picker("Model", selection: $viewModel.selectedOllamaModel) {
                    ForEach(viewModel.ollamaModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    private var geminiRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.purple)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Google Gemini")
                        .font(.headline)
                    Text("Cloud AI - Powerful & Fast")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                connectionBadge(viewModel.geminiStatus)
            }
            
            HStack {
                SecureField("API Key", text: $viewModel.geminiApiKey)
                    .textFieldStyle(.roundedBorder)
                
                Button(viewModel.geminiStatus == .connected ? "Update" : "Save") {
                    Task { await viewModel.saveGeminiKey() }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.geminiApiKey.isEmpty)
            }
            
            if viewModel.geminiStatus == .connected {
                Button("Remove API Key", role: .destructive) {
                    Task { await viewModel.removeGeminiKey() }
                }
                .font(.caption)
            }
        }
    }
    
    private var openAIRow: some View {
        HStack {
            Image(systemName: "brain")
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("OpenAI")
                    .font(.headline)
                Text("GPT-4o & More")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("Coming Soon")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Capsule())
        }
        .opacity(0.6)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func connectionBadge(_ status: ConnectionStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Connection Status

enum ConnectionStatus: String {
    case connected = "Connected"
    case disconnected = "Not Connected"
    case checking = "Checking..."
    case error = "Error"
    
    var color: Color {
        switch self {
        case .connected: return .green
        case .disconnected: return .secondary
        case .checking: return .orange
        case .error: return .red
        }
    }
    
    var description: String {
        switch self {
        case .connected: return "Ready to use"
        case .disconnected: return "Configure to enable"
        case .checking: return "Checking connection..."
        case .error: return "Connection failed"
        }
    }
}

// MARK: - ViewModel

@MainActor
class APISettingsViewModel: ObservableObject {
    // X API
    @Published var xConnectionStatus: ConnectionStatus = .checking
    @Published var xClientId: String = ""
    @Published var xClientSecret: String = ""
    @Published var xUser: XUser?
    
    // Ollama
    @Published var ollamaStatus: ConnectionStatus = .checking
    @Published var ollamaBaseURL: String = "http://127.0.0.1:11434"
    @Published var ollamaModels: [String] = []
    @Published var selectedOllamaModel: String = ""
    
    // Gemini
    @Published var geminiStatus: ConnectionStatus = .checking
    @Published var geminiApiKey: String = ""
    
    private let keychain = KeychainManager.shared
    
    // MARK: - Check All Connections
    
    func checkAllConnections() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.checkXConnection() }
            group.addTask { await self.checkOllamaConnection() }
            group.addTask { await self.checkGeminiConnection() }
        }
    }
    
    // MARK: - X API
    
    private func checkXConnection() async {
        xConnectionStatus = .checking
        
        let isAuth = await XAPIClient.shared.isAuthenticated
        if isAuth {
            do {
                let user = try await XAPIClient.shared.getMe()
                xUser = user
                xConnectionStatus = .connected
            } catch {
                xConnectionStatus = .error
            }
        } else {
            xConnectionStatus = .disconnected
        }
    }
    
    func connectX() async {
        // Save credentials to keychain
        do {
            try await keychain.save(xClientId, for: .xClientId)
            try await keychain.save(xClientSecret, for: .xClientSecret)
            
            // OAuth flow would be triggered here
            // For now, just update status
            xConnectionStatus = .disconnected
        } catch {
            xConnectionStatus = .error
        }
    }
    
    func disconnectX() async {
        do {
            try await XAPIClient.shared.logout()
            xUser = nil
            xConnectionStatus = .disconnected
        } catch {
            xConnectionStatus = .error
        }
    }
    
    // MARK: - Ollama
    
    private func checkOllamaConnection() async {
        ollamaStatus = .checking
        
        await OllamaClient.shared.loadConfiguration()
        
        if await OllamaClient.shared.isAvailable() {
            ollamaStatus = .connected
            await loadOllamaModels()
        } else {
            ollamaStatus = .disconnected
        }
    }
    
    func testOllama() async {
        ollamaStatus = .checking
        
        do {
            try await OllamaClient.shared.configure(baseURL: ollamaBaseURL)
            
            if await OllamaClient.shared.isAvailable() {
                ollamaStatus = .connected
                await loadOllamaModels()
            } else {
                ollamaStatus = .error
            }
        } catch {
            ollamaStatus = .error
        }
    }
    
    private func loadOllamaModels() async {
        do {
            let models = try await OllamaClient.shared.listModels()
            ollamaModels = models.map { $0.name }
            if !ollamaModels.isEmpty && selectedOllamaModel.isEmpty {
                selectedOllamaModel = ollamaModels[0]
            }
        } catch {
            ollamaModels = []
        }
    }
    
    // MARK: - Gemini
    
    private func checkGeminiConnection() async {
        geminiStatus = .checking
        
        if await GeminiClient.shared.isConfigured {
            geminiStatus = .connected
        } else {
            geminiStatus = .disconnected
        }
    }
    
    func saveGeminiKey() async {
        do {
            try await GeminiClient.shared.configure(apiKey: geminiApiKey)
            geminiStatus = .connected
            geminiApiKey = "" // Clear from memory
        } catch {
            geminiStatus = .error
        }
    }
    
    func removeGeminiKey() async {
        do {
            try await keychain.delete(.geminiApiKey)
            geminiStatus = .disconnected
        } catch {
            geminiStatus = .error
        }
    }
}
