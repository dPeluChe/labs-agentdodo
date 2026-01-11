import Foundation
import Combine
import UniformTypeIdentifiers

@MainActor
class ComposerViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var selectedTone: Tone = .neutral
    @Published var isPosting: Bool = false
    @Published var isSavingDraft: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccessFeedback: Bool = false
    @Published var showDraftSavedFeedback: Bool = false
    @Published var mediaAttachments: [MediaAttachment] = []
    
    var characterCount: Int {
        text.count
    }
    
    var isTextValid: Bool {
        !text.isEmpty && text.count <= 280
    }
    
    var canSaveDraft: Bool {
        !text.isEmpty || !mediaAttachments.isEmpty
    }
    
    var isEditingDraft: Bool {
        currentDraftId != nil
    }
    
    var canAddMedia: Bool {
        mediaAttachments.count < 4
    }
    
    private let createPostUseCase: CreatePostUseCase
    private let saveDraftUseCase: SaveDraftUseCase?
    private(set) var currentDraftId: UUID?
    
    init(createPostUseCase: CreatePostUseCase, saveDraftUseCase: SaveDraftUseCase? = nil, draft: Draft? = nil) {
        self.createPostUseCase = createPostUseCase
        self.saveDraftUseCase = saveDraftUseCase
        
        // Load draft if provided
        if let draft = draft {
            self.text = draft.text
            self.selectedTone = draft.tone
            self.currentDraftId = draft.id
        }
    }
    
    // MARK: - Media Handling
    
    func addMedia(from urls: [URL]) {
        for url in urls where canAddMedia {
            guard let mediaType = MediaType.from(url: url) else { continue }
            
            let attachment = MediaAttachment(
                id: UUID(),
                localURL: url,
                type: mediaType,
                createdAt: Date()
            )
            
            mediaAttachments.append(attachment)
        }
    }
    
    func removeMedia(_ attachment: MediaAttachment) {
        mediaAttachments.removeAll { $0.id == attachment.id }
    }
    
    func post() async {
        guard isTextValid else { return }
        
        isPosting = true
        errorMessage = nil
        
        do {
            _ = try await createPostUseCase.execute(text: text, tone: selectedTone)
            text = ""
            currentDraftId = nil
            showSuccessFeedback = true
            
            // Auto hide success after 2 seconds
            try? await Task.sleep(for: .seconds(2))
            showSuccessFeedback = false
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isPosting = false
    }
    
    func saveDraft() async {
        guard canSaveDraft, let saveDraftUseCase else { return }
        
        isSavingDraft = true
        errorMessage = nil
        
        do {
            let draft = try await saveDraftUseCase.execute(
                text: text,
                tone: selectedTone,
                existingDraftId: currentDraftId
            )
            currentDraftId = draft.id
            showDraftSavedFeedback = true
            
            // Auto hide after 2 seconds
            try? await Task.sleep(for: .seconds(2))
            showDraftSavedFeedback = false
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSavingDraft = false
    }
    
    func clearComposer() {
        text = ""
        selectedTone = .neutral
        currentDraftId = nil
    }
}
