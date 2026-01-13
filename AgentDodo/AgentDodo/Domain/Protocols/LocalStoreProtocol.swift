import Foundation

protocol LocalStoreProtocol {
    func savePost(_ post: Post) async throws
    func fetchPosts() async throws -> [Post]
    
    func saveDraft(_ draft: Draft) async throws
    func fetchDrafts() async throws -> [Draft]
    func deleteDraft(id: UUID) async throws
    func deleteAllDrafts() async throws
}
