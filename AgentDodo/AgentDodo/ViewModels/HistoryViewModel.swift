import Foundation
import Combine

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let localStore: LocalStoreProtocol
    
    init(localStore: LocalStoreProtocol) {
        self.localStore = localStore
    }
    
    func loadPosts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            posts = try await localStore.fetchPosts()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
