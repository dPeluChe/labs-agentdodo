import SwiftUI
import AppKit
import Combine

class MenuBarController: NSObject, ObservableObject {
    static let shared = MenuBarController()
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    @Published var isPopoverShown = false
    
    private override init() {
        super.init()
    }
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bird.fill", accessibilityDescription: "Agent Dodo")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        setupPopover()
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(rootView: MenuBarContentView(controller: self))
    }
    
    @objc func togglePopover() {
        if let popover = popover, let button = statusItem?.button {
            if popover.isShown {
                popover.performClose(nil)
                isPopoverShown = false
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                isPopoverShown = true
                
                // Focus the popover
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func closePopover() {
        popover?.performClose(nil)
        isPopoverShown = false
    }
    
    func showQuickComposer() {
        closePopover()
        QuickComposerPanelController.shared.show()
    }
    
    func openMainWindow() {
        closePopover()
        NSApp.activate(ignoringOtherApps: true)
        
        // Find and focus the main window
        for window in NSApp.windows {
            if window.title.isEmpty || window.title == "Agent Dodo" {
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
    }
}

// MARK: - Menu Bar Content View

struct MenuBarContentView: View {
    @ObservedObject var controller: MenuBarController
    @StateObject private var viewModel = MenuBarViewModel()
    @FocusState private var isTextFieldFocused: Bool
    @State private var showDrafts = false
    
    private let characterLimit = 280
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with char count
            header
            
            Divider()
            
            // Main Content (Compose or Drafts)
            if showDrafts {
                draftsListView
            } else {
                quickComposeSection
            }
            
            Divider()
            
            // Footer Actions (Icons only)
            footerActions
        }
        .frame(width: 300)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "bird.fill")
                .font(.system(size: 16))
                .foregroundStyle(.tint)
            
            Text(showDrafts ? "Drafts" : "Quick Post")
                .font(.subheadline.weight(.medium))
            
            Spacer()
            
            // Character count (only in compose mode)
            if !showDrafts {
                Text("\(characterLimit - viewModel.quickText.count)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(charCountColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(charCountColor.opacity(0.1), in: Capsule())
            }
            
            // Connection indicator
            Circle()
                .fill(viewModel.isConnected ? .green : .orange)
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    private var charCountColor: Color {
        let remaining = characterLimit - viewModel.quickText.count
        if remaining < 0 { return .red }
        if remaining < 20 { return .orange }
        return .secondary
    }
    
    // MARK: - Quick Compose
    
    private var quickComposeSection: some View {
        VStack(spacing: 0) {
            // Text Editor
            TextEditor(text: $viewModel.quickText)
                .font(.system(size: 14))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100, maxHeight: 150)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .focused($isTextFieldFocused)
                .overlay(alignment: .topLeading) {
                    if viewModel.quickText.isEmpty {
                        Text("What's happening?")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                }
            
            // Progress bar
            progressBar
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            
            // Action buttons row
            HStack(spacing: 8) {
                // Save Draft button (custom pill style)
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
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .disabled(viewModel.quickText.isEmpty)
                .help("Save Draft (⌘S)")
                .keyboardShortcut("s", modifiers: .command)
                
                Spacer()
                
                // Post button (custom accent pill)
                Button {
                    Task {
                        await viewModel.quickPost()
                        if viewModel.postSuccess {
                            controller.closePopover()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if viewModel.isPosting {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 11, weight: .bold))
                        }
                        Text("Post")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(viewModel.canPost ? Color.accentColor : Color.secondary.opacity(0.3), in: Capsule())
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canPost || viewModel.isPosting)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                
                // Progress
                Rectangle()
                    .fill(progressColor)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 3)
        .clipShape(Capsule())
        .animation(.easeOut(duration: 0.15), value: viewModel.quickText.count)
    }
    
    private var progress: CGFloat {
        min(CGFloat(viewModel.quickText.count) / CGFloat(characterLimit), 1.0)
    }
    
    private var progressColor: Color {
        let remaining = characterLimit - viewModel.quickText.count
        if remaining < 0 { return .red }
        if remaining < 20 { return .orange }
        return .accentColor
    }
    
    // MARK: - Drafts List
    
    private var draftsListView: some View {
        VStack(spacing: 0) {
            if viewModel.recentDrafts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No drafts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.recentDrafts, id: \.self) { draft in
                            Button {
                                viewModel.quickText = draft
                                showDrafts = false
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(draft)
                                        .lineLimit(2)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    
                                    Text("\(draft.count) chars")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(Color.primary.opacity(0.03))
                        }
                    }
                }
                .frame(height: 150)
            }
        }
    }
    
    // MARK: - Footer (Icons only)
    
    private var footerActions: some View {
        HStack(spacing: 8) {
            // Drafts toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDrafts.toggle()
                }
            } label: {
                Image(systemName: showDrafts ? "square.and.pencil" : "doc.text")
                    .font(.system(size: 14))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.bordered)
            .help(showDrafts ? "Compose" : "Drafts")
            
            Spacer()
            
            // Expand
            Button {
                controller.showQuickComposer()
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.bordered)
            .help("Expand (⌘⇧N)")
            
            // Open App
            Button {
                controller.openMainWindow()
            } label: {
                Image(systemName: "macwindow")
                    .font(.system(size: 14))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderedProminent)
            .help("Open App")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Menu Bar ViewModel

@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var quickText: String = ""
    @Published var isPosting: Bool = false
    @Published var isSaving: Bool = false
    @Published var postSuccess: Bool = false
    @Published var saveSuccess: Bool = false
    @Published var isConnected: Bool = false
    @Published var recentDrafts: [String] = [
        "Draft idea about SwiftUI animations...",
        "Thread about async/await patterns",
        "Quick tip for macOS developers"
    ]
    
    var canPost: Bool {
        !quickText.isEmpty && quickText.count <= 280
    }
    
    func quickPost() async {
        guard canPost else { return }
        
        isPosting = true
        
        // Simulate posting (replace with real API)
        try? await Task.sleep(for: .milliseconds(500))
        
        postSuccess = true
        quickText = ""
        isPosting = false
        
        // Reset success after delay
        try? await Task.sleep(for: .seconds(1))
        postSuccess = false
    }
    
    func saveDraft() async {
        guard !quickText.isEmpty else { return }
        
        isSaving = true
        
        // Simulate saving (replace with real persistence)
        try? await Task.sleep(for: .milliseconds(300))
        
        // Add to drafts list
        recentDrafts.insert(quickText, at: 0)
        if recentDrafts.count > 10 {
            recentDrafts.removeLast()
        }
        
        saveSuccess = true
        isSaving = false
        
        // Reset success after delay
        try? await Task.sleep(for: .seconds(1))
        saveSuccess = false
    }
}
