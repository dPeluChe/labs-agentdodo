import Foundation
import Combine

@MainActor
class DraftsViewModel: ObservableObject {
    @Published var drafts: [Draft] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let localStore: LocalStoreProtocol
    
    init(localStore: LocalStoreProtocol) {
        self.localStore = localStore
    }
    
    func loadDrafts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            drafts = try await localStore.fetchDrafts()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteDraft(_ draft: Draft) async {
        do {
            try await localStore.deleteDraft(id: draft.id)
            drafts.removeAll { $0.id == draft.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
