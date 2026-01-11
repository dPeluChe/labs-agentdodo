import Foundation

struct Post: Identifiable, Equatable {
    let id: UUID
    let text: String
    let status: PostStatus
    let createdAt: Date
    let remoteId: String?
    let tone: Tone?
}

enum PostStatus: String, Codable {
    case queued
    case sent
    case failed
}
