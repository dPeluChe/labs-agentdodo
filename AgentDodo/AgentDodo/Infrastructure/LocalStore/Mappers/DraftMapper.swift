import Foundation

enum DraftMapper {
    static func mapToDomain(_ entity: DraftEntity) -> Draft {
        return Draft(
            id: entity.id,
            text: entity.text,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            tone: Tone(rawValue: entity.tone) ?? .neutral,
            attachments: entity.attachments
        )
    }
    
    static func mapToEntity(_ domain: Draft) -> DraftEntity {
        return DraftEntity(
            id: domain.id,
            text: domain.text,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt,
            tone: domain.tone.rawValue,
            attachments: domain.attachments
        )
    }
}
