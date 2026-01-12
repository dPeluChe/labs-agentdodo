import Foundation
import SwiftData

@Model
final class DraftEntity {
    @Attribute(.unique) var id: UUID
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var tone: String
    
    // Store attachments as JSON Data to avoid CoreData Array<String> issues
    @Attribute(.externalStorage) var attachmentsData: Data?
    
    var attachments: [String] {
        get {
            guard let data = attachmentsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            attachmentsData = try? JSONEncoder().encode(newValue)
        }
    }
    
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
        self.attachmentsData = try? JSONEncoder().encode(attachments)
    }
}
