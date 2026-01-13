import Foundation

protocol CreatePostUseCase {
    func execute(text: String, tone: Tone) async throws -> Post
}

class CreatePostUseCaseImpl: CreatePostUseCase {
    private let localStore: LocalStoreProtocol
    
    init(localStore: LocalStoreProtocol) {
        self.localStore = localStore
    }
    
    func execute(text: String, tone: Tone) async throws -> Post {
        // 1. Validation
        guard !text.isEmpty else {
            throw PostError.emptyText
        }
        
        guard text.count <= 280 else {
            throw PostError.tooLong
        }
        
        // 2. Create Post Object
        let post = Post(
            id: UUID(),
            text: text,
            status: .sent, // Since it's mock for now, we mark as sent
            createdAt: Date(),
            remoteId: "mock_\(UUID().uuidString)",
            accountUsername: nil,
            tone: tone
        )
        
        // 3. Persist
        try await localStore.savePost(post)
        
        return post
    }
}

enum PostError: LocalizedError {
    case emptyText
    case tooLong
    
    var errorDescription: String? {
        switch self {
        case .emptyText: return "Post cannot be empty."
        case .tooLong: return "Post is too long (max 280 characters)."
        }
    }
}
