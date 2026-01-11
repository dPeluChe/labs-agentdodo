import Foundation
import SwiftData

/// A thread-safe actor for handling SwiftData operations
@ModelActor
actor LocalStore: LocalStoreProtocol {
    
    // MARK: - Posts
    
    func savePost(_ post: Post) throws {
        let entity = PostMapper.mapToEntity(post)
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func fetchPosts() throws -> [Post] {
        let descriptor = FetchDescriptor<PostEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let entities = try modelContext.fetch(descriptor)
        return entities.map { PostMapper.mapToDomain($0) }
    }
    
    // MARK: - Drafts
    
    func saveDraft(_ draft: Draft) throws {
        // Check if exists to update, or insert new
        let id = draft.id
        let descriptor = FetchDescriptor<DraftEntity>(predicate: #Predicate { $0.id == id })
        
        if let existing = try modelContext.fetch(descriptor).first {
            existing.text = draft.text
            existing.updatedAt = Date()
            existing.tone = draft.tone.rawValue
            existing.attachments = draft.attachments
        } else {
            let entity = DraftMapper.mapToEntity(draft)
            modelContext.insert(entity)
        }
        
        try modelContext.save()
    }
    
    func fetchDrafts() throws -> [Draft] {
        let descriptor = FetchDescriptor<DraftEntity>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        let entities = try modelContext.fetch(descriptor)
        return entities.map { DraftMapper.mapToDomain($0) }
    }
    
    func deleteDraft(id: UUID) throws {
        let descriptor = FetchDescriptor<DraftEntity>(predicate: #Predicate { $0.id == id })
        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try modelContext.save()
        }
    }
}
