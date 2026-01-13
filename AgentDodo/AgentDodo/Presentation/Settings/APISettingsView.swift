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
                
                SecureField("Client Secret (Optional)", text: $viewModel.xClientSecret)
                    .textFieldStyle(.roundedBorder)
                
                Button("Connect with X") {
                    Task { await viewModel.connectX() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.xClientId.isEmpty)
            } else if viewModel.xConnectionStatus == .connected {
                if let user = viewModel.xUser {
                    HStack {
                        Text("Logged in as")
                            .foregroundStyle(.secondary)
                        Text("@\(user.username)")
                            .fontWeight(.medium)
                    }
                } else if !viewModel.xUsername.isEmpty {
                    HStack {
                        Text("Logged in as")
                            .foregroundStyle(.secondary)
                        Text("@\(viewModel.xUsername)")
                            .fontWeight(.medium)
                    }
                }
                
                Button("Disconnect", role: .destructive) {
                    Task { await viewModel.disconnectX() }
                }
                
                Button("Reset X Credentials", role: .destructive) {
                    Task { await viewModel.resetXCredentials() }
                }
                .font(.caption)
            } else {
                Button("Reset X Credentials", role: .destructive) {
                    Task { await viewModel.resetXCredentials() }
                }
                .font(.caption)
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
    @Published var xConnectionStatus: ConnectionStatus = .disconnected
    @Published var xClientId: String = ""
    @Published var xClientSecret: String = ""
    @Published var xUser: XUser?
    @Published var xUsername: String = ""
    
    // Ollama
    @Published var ollamaStatus: ConnectionStatus = .disconnected
    @Published var ollamaBaseURL: String = "http://127.0.0.1:11434"
    @Published var ollamaModels: [String] = []
    @Published var selectedOllamaModel: String = ""
    
    // Gemini
    @Published var geminiStatus: ConnectionStatus = .disconnected
    @Published var geminiApiKey: String = ""
    
    private let keychain = KeychainManager.shared
    private var oauthSession: XOAuth2AuthorizationSession?
    private let xRedirectURI = "agentdodo://auth/callback"
    private let xCallbackScheme = "agentdodo"
    
    // MARK: - Check All Connections (Only when explicitly triggered)
    
    func checkAllConnections() async {
        await loadXCredentialsIfNeeded()
        // Check X only if credentials exist
        await checkXConnection()
        // Check Gemini only (no network call needed)
        await checkGeminiConnection()
        // Don't auto-check Ollama - requires manual test
    }
    
    // MARK: - X API
    
    private func loadXCredentialsIfNeeded() async {
        if xClientId.isEmpty {
            if let stored = try? await keychain.retrieve(.xClientId) {
                xClientId = stored
            } else if !XAPIConfig.clientID.isEmpty {
                xClientId = XAPIConfig.clientID
            }
        }
        
        if xClientSecret.isEmpty {
            if let stored = try? await keychain.retrieve(.xClientSecret) {
                xClientSecret = stored
            } else if !XAPIConfig.clientSecret.isEmpty {
                xClientSecret = XAPIConfig.clientSecret
            }
        }
        
        if xClientId == XAPIConfig.consumerKey {
            xClientId = XAPIConfig.clientID
        }
        
        if xUsername.isEmpty {
            if let stored = try? await keychain.retrieve(.xUsername) {
                xUsername = stored
            }
        }
    }
    
    private func checkXConnection() async {
        xConnectionStatus = .checking
        
        let isAuth = await XAPIClient.shared.isAuthenticated
        if isAuth {
            do {
                let user = try await XAPIClient.shared.getMe()
                xUser = user
                xUsername = user.username
                try? await keychain.save(user.username, for: .xUsername)
                xConnectionStatus = .connected
            } catch {
                xConnectionStatus = .error
            }
        } else {
            xConnectionStatus = .disconnected
        }
    }
    
    func connectX() async {
        xConnectionStatus = .checking
        
        // Save credentials to keychain
        do {
            try await keychain.save(xClientId, for: .xClientId)
            try await keychain.save(xClientSecret, for: .xClientSecret)
            
            let resolvedClientId = xClientId == XAPIConfig.consumerKey ? XAPIConfig.clientID : xClientId
            guard let auth = XAPIClient.shared.getAuthorizationURL(
                clientId: resolvedClientId,
                redirectURI: xRedirectURI
            ) else {
                throw XOAuth2AuthError.unableToStart
            }
            
            print("[X OAuth2] Client ID prefix: \(resolvedClientId.prefix(8))")
            print("[X OAuth2] Auth URL: \(auth.url.absoluteString)")
            let session = XOAuth2AuthorizationSession()
            oauthSession = session
            
            let callbackURL = try await session.start(
                url: auth.url,
                callbackScheme: xCallbackScheme
            )
            
            print("[X OAuth2] Callback URL: \(callbackURL.absoluteString)")
            guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "code" })?
                .value else {
                let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?
                    .map { "\($0.name)=\($0.value ?? "")" }
                    .joined(separator: "&") ?? ""
                print("[X OAuth2] Callback query items: \(items)")
                throw XOAuth2AuthError.missingAuthorizationCode
            }
            
            _ = try await XAPIClient.shared.exchangeCodeForToken(
                clientId: resolvedClientId,
                code: code,
                codeVerifier: auth.pkce.codeVerifier,
                redirectURI: xRedirectURI
            )
            
            let user = try await XAPIClient.shared.getMe()
            xUser = user
            xUsername = user.username
            try? await keychain.save(user.username, for: .xUsername)
            xConnectionStatus = .connected
        } catch {
            if let authError = error as? XOAuth2AuthError, authError == .cancelled {
                xConnectionStatus = .disconnected
            } else {
                xConnectionStatus = .error
            }
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
    
    func resetXCredentials() async {
        do {
            try await keychain.delete(.xClientId)
            try await keychain.delete(.xClientSecret)
            try await keychain.delete(.xAccessToken)
            try await keychain.delete(.xRefreshToken)
            try await keychain.delete(.xUsername)
            xClientId = ""
            xClientSecret = ""
            xUser = nil
            xUsername = ""
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
