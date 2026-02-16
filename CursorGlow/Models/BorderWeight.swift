import Foundation

enum BorderWeight: String, CaseIterable, Identifiable, Codable {
    case thin
    case regular
    case bold

    var id: String { rawValue }

    var lineWidth: CGFloat {
        switch self {
        case .thin: return 1.0
        case .regular: return 2.0
        case .bold: return 4.0
        }
    }

    var displayName: String {
        switch self {
        case .thin: return "Thin"
        case .regular: return "Regular"
        case .bold: return "Bold"
        }
    }
}
