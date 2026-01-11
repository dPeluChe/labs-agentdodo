import Foundation
import SwiftData

@Model
final class PostEntity {
    @Attribute(.unique) var id: UUID
    var text: String
    var status: String // Raw value of PostStatus
    var createdAt: Date
    var remoteId: String?
    var tone: String?
    
    init(id: UUID = UUID(), 
         text: String, 
         status: String, 
         createdAt: Date = Date(), 
         remoteId: String? = nil, 
         tone: String? = nil) {
        self.id = id
        self.text = text
        self.status = status
        self.createdAt = createdAt
        self.remoteId = remoteId
        self.tone = tone
    }
}
