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
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "Quick Post"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = .clear
        
        // Set minimum size
        panel.minSize = NSSize(width: 400, height: 280)
        panel.maxSize = NSSize(width: 600, height: 500)
        
        // Create the SwiftUI content
        let contentView = QuickComposerContent(onDismiss: { [weak self] in
            self?.hide()
        })
        
        panel.contentView = NSHostingView(rootView: contentView)
        
        self.panel = panel
    }
}

// MARK: - Quick Composer Content View

struct QuickComposerContent: View {
    @StateObject private var viewModel = QuickComposerViewModel()
    @FocusState private var isEditorFocused: Bool
    
    let onDismiss: () -> Void
    
    private let characterLimit = 280
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            dragHandle
            
            // Status Toast
            if viewModel.showSuccessFeedback {
                successToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Editor
            TextEditor(text: $viewModel.text)
                .font(.system(size: 16))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .focused($isEditorFocused)
                .overlay(alignment: .topLeading) {
                    if viewModel.text.isEmpty {
                        Text("Quick thought...")
                            .font(.system(size: 16))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
            
            Divider()
            
            // Bottom Bar
            bottomBar
        }
        .frame(minWidth: 400, minHeight: 280)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .padding(8)
        .onAppear {
            isEditorFocused = true
        }
    }
    
    // MARK: - Components
    
    private var dragHandle: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    private var successToast: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
            Text("Posted!")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.green)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.vertical, 8)
    }
    
    private var bottomBar: some View {
        HStack(spacing: 12) {
            // Character Counter
            characterCounter
            
            Spacer()
            
            // Cancel
            Button("Cancel") {
                onDismiss()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.escape, modifiers: [])
            
            // Post
            Button {
                Task {
                    await viewModel.post()
                    if viewModel.showSuccessFeedback {
                        try? await Task.sleep(for: .seconds(1))
                        viewModel.text = ""
                        onDismiss()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isPosting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .fontWeight(.semibold)
                    }
                    Text("Post")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isTextValid || viewModel.isPosting)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var characterCounter: some View {
        CharacterCounterView(count: viewModel.text.count, limit: characterLimit, size: 18)
    }
}

// MARK: - Quick Composer ViewModel

@MainActor
class QuickComposerViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var isPosting: Bool = false
    @Published var showSuccessFeedback: Bool = false
    
    var isTextValid: Bool {
        !text.isEmpty && text.count <= 280
    }
    
    func post() async {
        guard isTextValid else { return }
        
        isPosting = true
        
        // Simulate posting (replace with real API later)
        try? await Task.sleep(for: .milliseconds(500))
        
        showSuccessFeedback = true
        isPosting = false
        
        // Auto-hide feedback
        try? await Task.sleep(for: .seconds(2))
        showSuccessFeedback = false
    }
}
