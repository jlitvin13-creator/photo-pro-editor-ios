import Foundation

struct AdjustmentSettings: Equatable {
    var brightness: Double = 0
    var contrast: Double = 1
    var saturation: Double = 1
    var shadows: Double = 0
    var highlights: Double = 0
    var warmth: Double = 0
    var tint: Double = 0
    var sharpness: Double = 0
    var vignette: Double = 0
    var grain: Double = 0
    var blurBackground: Double = 0
    var skinSmoothing: Double = 0
}

extension AdjustmentSettings {
    static let original = AdjustmentSettings()
}
