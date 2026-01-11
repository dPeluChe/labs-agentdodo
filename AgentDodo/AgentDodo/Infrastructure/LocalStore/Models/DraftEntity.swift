import Foundation
import SwiftData

@Model
final class DraftEntity {
    @Attribute(.unique) var id: UUID
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var tone: String
    var attachments: [String]
    
    init(id: UUID = UUID(), 
         text: String, 
         createdAt: Date = Date(), 
         updatedAt: Date = Date(), 
         tone: String = "Neutral", 
         attachments: [String] = []) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tone = tone
        self.attachments = attachments
    }
}
