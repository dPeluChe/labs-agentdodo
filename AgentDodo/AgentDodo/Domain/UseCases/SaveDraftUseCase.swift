import Foundation

protocol SaveDraftUseCase {
    func execute(text: String, tone: Tone, existingDraftId: UUID?) async throws -> Draft
}

class SaveDraftUseCaseImpl: SaveDraftUseCase {
    private let localStore: LocalStoreProtocol
    
    init(localStore: LocalStoreProtocol) {
        self.localStore = localStore
    }
    
    func execute(text: String, tone: Tone, existingDraftId: UUID?) async throws -> Draft {
        let now = Date()
        
        let draft = Draft(
            id: existingDraftId ?? UUID(),
            text: text,
            createdAt: existingDraftId != nil ? now : now,
            updatedAt: now,
            tone: tone,
            attachments: []
        )
        
        try await localStore.saveDraft(draft)
        
        return draft
    }
}
