import SwiftUI
import UniformTypeIdentifiers

struct ComposerView: View {
    @StateObject var viewModel: ComposerViewModel
    @FocusState private var isEditorFocused: Bool
    @State private var isDropTargeted = false
    
    init(viewModel: ComposerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    private let characterLimit = 280
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Writing Area - Clean & Minimal
            VStack(spacing: 0) {
                // Floating Status Toast
                statusToast
                
                // Distraction-free Editor
                TextEditor(text: $viewModel.text)
                    .font(.system(size: 18, weight: .regular, design: .default))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 40)
                    .padding(.top, 30)
                    .padding(.bottom, viewModel.mediaAttachments.isEmpty ? 80 : 160)
                    .focused($isEditorFocused)
                    .overlay(alignment: .topLeading) {
                        if viewModel.text.isEmpty && viewModel.mediaAttachments.isEmpty {
                            Text("What's on your mind?")
                                .font(.system(size: 18))
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 45)
                                .padding(.top, 38)
                                .allowsHitTesting(false)
                        }
                    }
                
                // Media Attachments Preview
                if !viewModel.mediaAttachments.isEmpty {
                    mediaPreviewBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ultraThinMaterial)
            
            // Drop Overlay
            if isDropTargeted {
                dropOverlay
            }
            
            // Floating Bottom Bar
            floatingToolbar
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                characterIndicator
            }
            
            ToolbarItem(placement: .primaryAction) {
                if viewModel.canAddMedia {
                    Button {
                        // File picker would go here
                    } label: {
                        Image(systemName: "photo.badge.plus")
                    }
                    .help("Add Media")
                }
            }
        }
        .onDrop(of: [.image, .movie, .fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            isEditorFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickComposerNewPost)) { _ in
            viewModel.clearComposer()
        }
    }
    
    // MARK: - Drop Handling
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        Task { @MainActor in
                            viewModel.addMedia(from: [url])
                        }
                    }
                }
            }
        }
        return true
    }
    
    private var dropOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 40))
            Text("Drop to attach")
                .font(.headline)
        }
        .foregroundStyle(.tint)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Media Preview Bar
    
    private var mediaPreviewBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.mediaAttachments) { attachment in
                    MediaThumbnailView(attachment: attachment) {
                        viewModel.removeMedia(attachment)
                    }
                }
                
                // Add more button
                if viewModel.canAddMedia {
                    Button {
                        // File picker
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.title3)
                        }
                        .frame(width: 60, height: 60)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Status Toast (Minimal)
    
    @ViewBuilder
    private var statusToast: some View {
        if viewModel.showSuccessFeedback {
            toastView(icon: "checkmark.circle.fill", text: "Posted", color: .green)
                .transition(.move(edge: .top).combined(with: .opacity))
        } else if viewModel.showDraftSavedFeedback {
            toastView(icon: "checkmark", text: "Saved", color: .secondary)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    private func toastView(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(color)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.top, 12)
    }
    
    // MARK: - Character Indicator (Toolbar)
    
    private var characterIndicator: some View {
        CharacterCounterView(count: viewModel.characterCount, limit: characterLimit)
    }
    
    // MARK: - Floating Toolbar
    
    private var floatingToolbar: some View {
        HStack(spacing: 12) {
            // Tone Selector (Icon only)
            toneSelector
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                // Save Draft
                Button {
                    Task { await viewModel.saveDraft() }
                } label: {
                    Group {
                        if viewModel.isSavingDraft {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                    }
                    .frame(width: 20, height: 20)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canSaveDraft || viewModel.isSavingDraft)
                .keyboardShortcut("s", modifiers: .command)
                .help("Save Draft (⌘S)")
                
                // Post Button
                Button {
                    Task { await viewModel.post() }
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
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isTextValid || viewModel.isPosting)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
    
    // MARK: - Tone Selector (Compact)
    
    private var toneSelector: some View {
        Menu {
            ForEach(Tone.allCases) { tone in
                Button {
                    viewModel.selectedTone = tone
                } label: {
                    Label(tone.rawValue, systemImage: tone.icon)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel.selectedTone.icon)
                    .font(.system(size: 14))
                Text(viewModel.selectedTone.rawValue)
                    .font(.subheadline)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
    }
}
