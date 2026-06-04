import CoreGraphics
import Foundation

enum ExportQuality: String, CaseIterable, Identifiable {
    case high = "High"
    case medium = "Medium"

    var id: String { rawValue }

    var compressionQuality: CGFloat {
        switch self {
        case .high: return 0.96
        case .medium: return 0.82
        }
    }
}
