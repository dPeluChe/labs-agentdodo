import SwiftUI
import AppKit
import Combine
import SwiftData

// MARK: - Quick Composer Panel Controller

class QuickComposerPanelController: NSObject, ObservableObject {
    static let shared = QuickComposerPanelController()
    
    private var panel: NSPanel?
    @Published var isVisible = false
    
    var modelContainer: ModelContainer?
    
    private override init() {
        super.init()
    }
    
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func show() {
        if panel == nil {
            createPanel()
        }
        
        panel?.makeKeyAndOrderFront(nil)
        panel?.center()
        isVisible = true
        
        // Activate app to bring focus
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hide() {
        panel?.orderOut(nil)
        isVisible = false
    }
    
    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 450),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "Agent Dodo"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = .clear
        
        // Hide standard window buttons
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Set minimum size
        panel.minSize = NSSize(width: 450, height: 380)
        panel.maxSize = NSSize(width: 800, height: 700)
        
        // Create the SwiftUI content with model container
        let contentView = MainComposerView(onDismiss: { [weak self] in
            self?.hide()
        })
        
        if let container = modelContainer {
            panel.contentView = NSHostingView(rootView: contentView.modelContainer(container))
        } else {
            panel.contentView = NSHostingView(rootView: contentView)
        }
        
        self.panel = panel
    }
}

// MARK: - Main Composer View (Primary App Interface)

struct MainComposerView: View {
    @StateObject private var viewModel = MainComposerViewModel()
    @FocusState private var isEditorFocused: Bool
    @State private var currentSection: ComposerSection = .compose
    
    let onDismiss: () -> Void
    
    private let characterLimit = 280
    
    var body: some View {
        HStack(spacing: 0) {
            // Mini Sidebar
            miniSidebar
            
            // Main Content
            mainContent
        }
        .frame(minWidth: 420, minHeight: 350)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .padding(6)
        .overlay(alignment: .top) {
            // Toast notifications
            if viewModel.showSaveFeedback {
                toastView(icon: "checkmark.circle.fill", text: "Draft saved", color: .green)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if viewModel.showSuccessFeedback {
                toastView(icon: "paperplane.fill", text: "Posted!", color: .accentColor)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if viewModel.showErrorFeedback {
                toastView(icon: "exclamationmark.triangle.fill", text: viewModel.errorMessage, color: .red)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.showSaveFeedback)
        .animation(.spring(response: 0.3), value: viewModel.showSuccessFeedback)
        .animation(.spring(response: 0.3), value: viewModel.showErrorFeedback)
        .onAppear {
            isEditorFocused = true
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    private func toastView(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.top, 20)
    }
    
    // MARK: - Mini Sidebar
    
    private var miniSidebar: some View {
        VStack(spacing: 4) {
            // App Icon + Close button
            HStack(spacing: 0) {
                Image(systemName: "bird.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.tint)
            }
            .frame(width: 36, height: 36)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Section buttons
            ForEach(ComposerSection.allCases, id: \.self) { section in
                sidebarButton(section)
            }
            
            Spacer()
            
            // Settings section button
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    currentSection = .settings
                }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(currentSection == .settings ? .accentColor : .secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        currentSection == .settings ? Color.accentColor.opacity(0.15) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            }
            .buttonStyle(.plain)
            .help("Settings")
            
            // Close
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color.secondary.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Close (Esc)")
            .keyboardShortcut(.escape, modifiers: [])
            .padding(.bottom, 10)
        }
        .frame(width: 52)
        .background(Color.primary.opacity(0.03))
    }
    
    private func sidebarButton(_ section: ComposerSection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                currentSection = section
            }
        } label: {
            Image(systemName: section.icon)
                .font(.system(size: 14))
                .foregroundColor(currentSection == section ? .accentColor : .secondary)
                .frame(width: 32, height: 32)
                .background(
                    currentSection == section ? Color.accentColor.opacity(0.15) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .buttonStyle(.plain)
        .help(section.title)
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        switch currentSection {
        case .compose:
            composeView
        case .drafts:
            draftsView
        case .history:
            historyView
        case .settings:
            settingsView
        }
    }
    
    // MARK: - Compose View
    
    private var composeView: some View {
        VStack(spacing: 0) {
            // Header
            composeHeader
            
            // Editor
            TextEditor(text: $viewModel.text)
                .font(.system(size: 15))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .focused($isEditorFocused)
                .overlay(alignment: .topLeading) {
                    if viewModel.text.isEmpty {
                        Text("What's on your mind?")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                }
            
            // Progress bar
            progressBar
                .padding(.horizontal, 16)
            
            Divider()
                .padding(.top, 8)
            
            // Bottom Bar
            composeBottomBar
        }
    }
    
    private var composeHeader: some View {
        HStack(spacing: 8) {
            Text("New Post")
                .font(.subheadline.weight(.medium))
            
            Spacer()
            
            // Character count badge
            Text("\(characterLimit - viewModel.text.count)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(charCountColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(charCountColor.opacity(0.1), in: Capsule())
            
            // Tone selector
            Menu {
                ForEach(Tone.allCases, id: \.self) { tone in
                    Button {
                        viewModel.selectedTone = tone
                    } label: {
                        Label(tone.rawValue, systemImage: tone.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.selectedTone.icon)
                        .font(.system(size: 12))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1), in: Capsule())
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private var charCountColor: Color {
        let remaining = characterLimit - viewModel.text.count
        if remaining < 0 { return .red }
        if remaining < 20 { return .orange }
        return .secondary
    }
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                
                Rectangle()
                    .fill(progressColor)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 2)
        .clipShape(Capsule())
        .animation(.easeOut(duration: 0.15), value: viewModel.text.count)
    }
    
    private var progress: CGFloat {
        min(CGFloat(viewModel.text.count) / CGFloat(characterLimit), 1.0)
    }
    
    private var progressColor: Color {
        let remaining = characterLimit - viewModel.text.count
        if remaining < 0 { return .red }
        if remaining < 20 { return .orange }
        return .accentColor
    }
    
    private var composeBottomBar: some View {
        HStack(spacing: 10) {
            // Save Draft (custom pill)
            Button {
                Task { await viewModel.saveDraft() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 11))
                    Text("Save")
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .disabled(viewModel.text.isEmpty)
            .keyboardShortcut("s", modifiers: .command)
            
            Spacer()
            
            // Post (custom accent pill)
            Button {
                Task {
                    await viewModel.post()
                    if viewModel.showSuccessFeedback {
                        try? await Task.sleep(for: .seconds(1))
                        viewModel.text = ""
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    if viewModel.isPosting {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 11, weight: .bold))
                    }
                    Text("Post")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(viewModel.canPost ? Color.accentColor : Color.secondary.opacity(0.3), in: Capsule())
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canPost || viewModel.isPosting)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Drafts View
    
    private var draftsView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Drafts")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(viewModel.drafts.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1), in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider()
            
            // Drafts list
            if viewModel.drafts.isEmpty {
                emptyState(icon: "doc.text", title: "No drafts", subtitle: "Saved drafts will appear here")
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.drafts) { draft in
                            draftRow(draft)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    private func draftRow(_ draft: Draft) -> some View {
        Button {
            viewModel.loadDraft(draft)
            currentSection = .compose
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(draft.text)
                    .lineLimit(2)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 8) {
                    Text("\(draft.text.count) chars")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Text(draft.updatedAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.02))
    }
    
    // MARK: - History View
    
    private var historyView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(viewModel.posts.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1), in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider()
            
            // History list
            if viewModel.posts.isEmpty {
                emptyState(icon: "clock", title: "No posts yet", subtitle: "Your posted content will appear here")
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.posts) { post in
                            historyRow(post)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    private func historyRow(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post.text)
                .lineLimit(2)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 8) {
                Image(systemName: statusIcon(post.status))
                    .font(.system(size: 10))
                    .foregroundStyle(statusColor(post.status))
                Text(post.status.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(post.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.02))
    }
    
    private func statusIcon(_ status: PostStatus) -> String {
        switch status {
        case .queued: return "clock"
        case .sent: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }
    
    private func statusColor(_ status: PostStatus) -> Color {
        switch status {
        case .queued: return .orange
        case .sent: return .green
        case .failed: return .red
        }
    }
    
    // MARK: - Empty State
    
    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Settings View
    
    private var settingsView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // API Connections
                    settingsSection(title: "Connections") {
                        VStack(spacing: 8) {
                            Button {
                                print("[Settings] X button tapped")
                                Task {
                                    print("[Settings] Starting X API configuration...")
                                    await viewModel.configureXAPI()
                                    print("[Settings] X API configuration completed")
                                }
                            } label: {
                                settingsRow(
                                    icon: "network",
                                    title: "X (Twitter)",
                                    subtitle: viewModel.isXConfigured ? "Connected" : "Tap to configure",
                                    status: viewModel.isXConfigured ? .connected : .disconnected
                                )
                            }
                            .buttonStyle(.plain)
                            
                            if viewModel.isXConfigured {
                                Button {
                                    Task { await viewModel.testXPost() }
                                } label: {
                                    HStack {
                                        Image(systemName: "paperplane")
                                            .foregroundColor(.accentColor)
                                        Text("Send Test Tweet")
                                            .font(.caption)
                                            .foregroundColor(.accentColor)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        settingsRow(icon: "cpu", title: "Ollama", subtitle: "localhost:11434", status: .connected)
                        settingsRow(icon: "sparkles", title: "Gemini", subtitle: "Not configured", status: .disconnected)
                    }
                    
                    // Preferences
                    settingsSection(title: "Preferences") {
                        Toggle(isOn: .constant(true)) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                Text("Auto-save drafts")
                                    .font(.subheadline)
                            }
                        }
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        
                        Toggle(isOn: .constant(false)) {
                            HStack {
                                Image(systemName: "bell")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                Text("Post notifications")
                                    .font(.subheadline)
                            }
                        }
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                    
                    // About
                    settingsSection(title: "About") {
                        HStack {
                            Text("Version")
                                .font(.subheadline)
                            Spacer()
                            Text("1.0.0")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
            }
        }
    }
    
    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 12) {
                content()
            }
            .padding(12)
            .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private func settingsRow(icon: String, title: String, subtitle: String, status: ConnectionStatus) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Circle()
                .fill(status == .connected ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Composer Section

enum ComposerSection: CaseIterable {
    case compose
    case drafts
    case history
    case settings
    
    var title: String {
        switch self {
        case .compose: return "Compose"
        case .drafts: return "Drafts"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .compose: return "square.and.pencil"
        case .drafts: return "doc.text"
        case .history: return "clock"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Shared Composer State (Singleton for Menu Bar + Main Composer sync)

@MainActor
class SharedComposerState: ObservableObject {
    static let shared = SharedComposerState()
    
    @Published var drafts: [Draft] = []
    @Published var posts: [Post] = []
    
    private var localStore: LocalStore?
    
    private init() {}
    
    func configure(with container: ModelContainer) {
        self.localStore = LocalStore(modelContainer: container)
        Task { await loadData() }
    }
    
    func loadData() async {
        guard let store = localStore else { return }
        do {
            drafts = try await store.fetchDrafts()
            posts = try await store.fetchPosts()
        } catch {
            print("Error loading data: \(error)")
        }
    }
    
    func saveDraft(text: String, tone: Tone) async {
        guard let store = localStore, !text.isEmpty else { return }
        
        let draft = Draft(
            id: UUID(),
            text: text,
            createdAt: Date(),
            updatedAt: Date(),
            tone: tone,
            attachments: []
        )
        
        do {
            try await store.saveDraft(draft)
            await loadData()
        } catch {
            print("Error saving draft: \(error)")
        }
    }
    
    func createPost(text: String, tone: Tone) async {
        guard let store = localStore, !text.isEmpty else { return }
        
        let post = Post(
            id: UUID(),
            text: text,
            status: .queued,
            createdAt: Date(),
            remoteId: nil,
            tone: tone
        )
        
        do {
            try await store.savePost(post)
            await loadData()
        } catch {
            print("Error creating post: \(error)")
        }
    }
}

// MARK: - Main Composer ViewModel

@MainActor
class MainComposerViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var selectedTone: Tone = .neutral
    @Published var isPosting: Bool = false
    @Published var isSaving: Bool = false
    @Published var showSuccessFeedback: Bool = false
    @Published var showSaveFeedback: Bool = false
    @Published var showErrorFeedback: Bool = false
    @Published var errorMessage: String = ""
    @Published var isXConfigured: Bool = false
    
    private let sharedState = SharedComposerState.shared
    private let xClient = XOAuth1Client.shared
    
    var drafts: [Draft] { sharedState.drafts }
    var posts: [Post] { sharedState.posts }
    
    var canPost: Bool {
        !text.isEmpty && text.count <= 280
    }
    
    func loadData() async {
        await sharedState.loadData()
        await xClient.loadCredentials()
        isXConfigured = await xClient.isConfigured
        objectWillChange.send()
    }
    
    func post() async {
        guard canPost else { return }
        
        isPosting = true
        
        do {
            // Try to post to X API
            if await xClient.isConfigured {
                let response = try await xClient.postTweet(text: text)
                print("Posted tweet with ID: \(response.data.id)")
                
                // Save to local history with remote ID
                await sharedState.createPost(text: text, tone: selectedTone)
            } else {
                // Just save locally if not configured
                await sharedState.createPost(text: text, tone: selectedTone)
            }
            
            showSuccessFeedback = true
            text = ""
            isPosting = false
            objectWillChange.send()
            
            try? await Task.sleep(for: .seconds(1.5))
            showSuccessFeedback = false
            
        } catch {
            isPosting = false
            errorMessage = error.localizedDescription
            showErrorFeedback = true
            
            try? await Task.sleep(for: .seconds(3))
            showErrorFeedback = false
        }
    }
    
    func saveDraft() async {
        guard !text.isEmpty else { return }
        
        isSaving = true
        
        await sharedState.saveDraft(text: text, tone: selectedTone)
        
        showSaveFeedback = true
        isSaving = false
        objectWillChange.send()
        
        try? await Task.sleep(for: .seconds(1))
        showSaveFeedback = false
    }
    
    func loadDraft(_ draft: Draft) {
        text = draft.text
        selectedTone = draft.tone
    }
    
    func configureXAPI() async {
        do {
            try await xClient.configure(
                consumerKey: XAPIConfig.consumerKey,
                consumerSecret: XAPIConfig.consumerSecret,
                accessToken: XAPIConfig.accessToken,
                accessTokenSecret: XAPIConfig.accessTokenSecret
            )
            isXConfigured = true
            showSaveFeedback = true
            print("X API configured successfully")
            
            try? await Task.sleep(for: .seconds(1.5))
            showSaveFeedback = false
        } catch {
            errorMessage = "Failed to configure X: \(error.localizedDescription)"
            showErrorFeedback = true
            print("Failed to configure X API: \(error)")
            
            try? await Task.sleep(for: .seconds(3))
            showErrorFeedback = false
        }
    }
    
    func testXPost() async {
        guard await xClient.isConfigured else {
            errorMessage = "X API not configured"
            showErrorFeedback = true
            try? await Task.sleep(for: .seconds(2))
            showErrorFeedback = false
            return
        }
        
        do {
            let response = try await xClient.postTweet(text: "Test from AgentDodo 🐦")
            print("Posted tweet: \(response.data.id)")
            showSuccessFeedback = true
            try? await Task.sleep(for: .seconds(1.5))
            showSuccessFeedback = false
        } catch {
            errorMessage = error.localizedDescription
            showErrorFeedback = true
            print("Post failed: \(error)")
            try? await Task.sleep(for: .seconds(3))
            showErrorFeedback = false
        }
    }
}
