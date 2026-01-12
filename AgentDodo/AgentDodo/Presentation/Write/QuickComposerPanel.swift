import SwiftUI
import AppKit
import Combine

// MARK: - Quick Composer Panel Controller

class QuickComposerPanelController: NSObject, ObservableObject {
    static let shared = QuickComposerPanelController()
    
    private var panel: NSPanel?
    @Published var isVisible = false
    
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
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
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
        
        // Set minimum size
        panel.minSize = NSSize(width: 420, height: 350)
        panel.maxSize = NSSize(width: 700, height: 600)
        
        // Create the SwiftUI content
        let contentView = MainComposerView(onDismiss: { [weak self] in
            self?.hide()
        })
        
        panel.contentView = NSHostingView(rootView: contentView)
        
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
        .onAppear {
            isEditorFocused = true
        }
    }
    
    // MARK: - Mini Sidebar
    
    private var miniSidebar: some View {
        VStack(spacing: 4) {
            // App Icon
            Image(systemName: "bird.fill")
                .font(.system(size: 20))
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            // Section buttons
            ForEach(ComposerSection.allCases, id: \.self) { section in
                sidebarButton(section)
            }
            
            Spacer()
            
            // Settings
            Button {
                MenuBarController.shared.openMainWindow()
                onDismiss()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help("Settings")
            
            // Close
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help("Close (Esc)")
            .keyboardShortcut(.escape, modifiers: [])
            .padding(.bottom, 8)
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
                        ForEach(viewModel.drafts, id: \.self) { draft in
                            draftRow(draft)
                        }
                    }
                }
            }
        }
    }
    
    private func draftRow(_ draft: String) -> some View {
        Button {
            viewModel.text = draft
            currentSection = .compose
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(draft)
                    .lineLimit(2)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                
                Text("\(draft.count) characters")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider()
            
            // History list
            if viewModel.history.isEmpty {
                emptyState(icon: "clock", title: "No posts yet", subtitle: "Your posted content will appear here")
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.history, id: \.self) { post in
                            historyRow(post)
                        }
                    }
                }
            }
        }
    }
    
    private func historyRow(_ post: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post)
                .lineLimit(2)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text("Posted")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.02))
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
}

// MARK: - Composer Section

enum ComposerSection: CaseIterable {
    case compose
    case drafts
    case history
    
    var title: String {
        switch self {
        case .compose: return "Compose"
        case .drafts: return "Drafts"
        case .history: return "History"
        }
    }
    
    var icon: String {
        switch self {
        case .compose: return "square.and.pencil"
        case .drafts: return "doc.text"
        case .history: return "clock"
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
    @Published var drafts: [String] = [
        "Draft idea about SwiftUI animations...",
        "Thread about async/await patterns",
        "Quick tip for macOS developers"
    ]
    @Published var history: [String] = [
        "Just shipped a new feature! 🚀",
        "SwiftUI is amazing for building native apps"
    ]
    
    var canPost: Bool {
        !text.isEmpty && text.count <= 280
    }
    
    func post() async {
        guard canPost else { return }
        
        isPosting = true
        
        // Simulate posting
        try? await Task.sleep(for: .milliseconds(500))
        
        // Add to history
        history.insert(text, at: 0)
        
        showSuccessFeedback = true
        isPosting = false
        
        try? await Task.sleep(for: .seconds(1))
        showSuccessFeedback = false
    }
    
    func saveDraft() async {
        guard !text.isEmpty else { return }
        
        isSaving = true
        
        try? await Task.sleep(for: .milliseconds(300))
        
        drafts.insert(text, at: 0)
        
        isSaving = false
    }
}
