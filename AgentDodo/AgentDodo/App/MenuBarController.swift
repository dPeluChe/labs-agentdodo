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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Quick Compose
            quickComposeSection
            
            Divider()
            
            // Recent Drafts
            recentDraftsSection
            
            Divider()
            
            // Footer Actions
            footerActions
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Image(systemName: "bird.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            
            Text("Agent Dodo")
                .font(.headline)
            
            Spacer()
            
            // Connection status indicator
            Circle()
                .fill(viewModel.isConnected ? .green : .secondary)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Quick Compose
    
    private var quickComposeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Post")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            
            HStack(spacing: 8) {
                TextField("What's happening?", text: $viewModel.quickText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(3...5)
                    .focused($isTextFieldFocused)
                
                Button {
                    Task {
                        await viewModel.quickPost()
                        if viewModel.postSuccess {
                            controller.closePopover()
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .foregroundColor(viewModel.canPost ? .accentColor : .secondary)
                .disabled(!viewModel.canPost || viewModel.isPosting)
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
            
            // Character count
            HStack {
                Spacer()
                Text("\(280 - viewModel.quickText.count)")
                    .font(.caption2)
                    .foregroundStyle(viewModel.quickText.count > 260 ? .orange : .secondary)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Recent Drafts
    
    private var recentDraftsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Drafts")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            
            if viewModel.recentDrafts.isEmpty {
                Text("No drafts yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.recentDrafts.prefix(3), id: \.self) { draft in
                    Button {
                        viewModel.quickText = draft
                    } label: {
                        Text(draft)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(Color.primary.opacity(0.05))
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Footer
    
    private var footerActions: some View {
        HStack(spacing: 12) {
            Button {
                controller.showQuickComposer()
            } label: {
                Label("Expand", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button {
                controller.openMainWindow()
            } label: {
                Label("Open App", systemImage: "macwindow")
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
    }
}

// MARK: - Menu Bar ViewModel

@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var quickText: String = ""
    @Published var isPosting: Bool = false
    @Published var postSuccess: Bool = false
    @Published var isConnected: Bool = false
    @Published var recentDrafts: [String] = []
    
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
}
