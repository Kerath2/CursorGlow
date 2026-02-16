import Foundation

enum HighlightSize: String, CaseIterable, Identifiable, Codable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var points: CGFloat {
        switch self {
        case .small: return 30
        case .medium: return 50
        case .large: return 80
        }
    }

    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}
