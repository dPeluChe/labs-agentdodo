import Foundation

enum PostMapper: Sendable {
    nonisolated static func mapToDomain(_ entity: PostEntity) -> Post {
        return Post(
            id: entity.id,
            text: entity.text,
            status: PostStatus(rawValue: entity.status) ?? .queued,
            createdAt: entity.createdAt,
            remoteId: entity.remoteId,
            accountUsername: entity.accountUsername,
            tone: entity.tone.flatMap { Tone(rawValue: $0) }
        )
    }
    
    nonisolated static func mapToEntity(_ domain: Post) -> PostEntity {
        return PostEntity(
            id: domain.id,
            text: domain.text,
            status: domain.status.rawValue,
            createdAt: domain.createdAt,
            remoteId: domain.remoteId,
            accountUsername: domain.accountUsername,
            tone: domain.tone?.rawValue
        )
    }
}
