import Foundation

enum Tone: String, CaseIterable, Codable, Identifiable {
    case casual = "Casual"
    case professional = "Professional"
    case spicy = "Spicy"
    case neutral = "Neutral"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .casual: return "figure.run"
        case .professional: return "briefcase.fill"
        case .spicy: return "flame.fill"
        case .neutral: return "bubble.left"
        }
    }
}
