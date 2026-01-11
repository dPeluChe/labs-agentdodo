import Foundation

struct Draft: Identifiable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
    let updatedAt: Date
    let tone: Tone
    let attachments: [String] // Paths to local files
}
