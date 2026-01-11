import Foundation
import UniformTypeIdentifiers

struct MediaAttachment: Identifiable, Equatable {
    let id: UUID
    let localURL: URL
    let type: MediaType
    let createdAt: Date
    
    var fileName: String {
        localURL.lastPathComponent
    }
    
    var fileSize: Int64? {
        try? FileManager.default.attributesOfItem(atPath: localURL.path)[.size] as? Int64
    }
    
    var fileSizeFormatted: String {
        guard let size = fileSize else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

enum MediaType: String, Codable {
    case image
    case video
    case gif
    
    var icon: String {
        switch self {
        case .image: return "photo"
        case .video: return "video"
        case .gif: return "photo.stack"
        }
    }
    
    var maxSize: Int64 {
        switch self {
        case .image: return 5 * 1024 * 1024      // 5MB
        case .video: return 512 * 1024 * 1024   // 512MB
        case .gif: return 15 * 1024 * 1024      // 15MB
        }
    }
    
    static func from(url: URL) -> MediaType? {
        guard let uti = UTType(filenameExtension: url.pathExtension) else { return nil }
        
        if uti.conforms(to: .gif) {
            return .gif
        } else if uti.conforms(to: .image) {
            return .image
        } else if uti.conforms(to: .movie) || uti.conforms(to: .video) {
            return .video
        }
        
        return nil
    }
}
