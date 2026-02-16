import Foundation

enum HighlightShape: String, CaseIterable, Identifiable, Codable {
    case circle
    case rhombus
    case roundedSquare
    case squircle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .circle: return "Circle"
        case .rhombus: return "Rhombus"
        case .roundedSquare: return "Rounded Sq."
        case .squircle: return "Squircle"
        }
    }
}
