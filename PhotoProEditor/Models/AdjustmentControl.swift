import Foundation

enum AdjustmentControl: String, CaseIterable, Identifiable {
    case brightness = "Brightness"
    case contrast = "Contrast"
    case saturation = "Saturation"
    case shadows = "Shadows"
    case highlights = "Highlights"
    case warmth = "Warmth"
    case tint = "Tint"
    case sharpness = "Sharpness"
    case vignette = "Vignette"
    case grain = "Grain"
    case blurBackground = "Blur background"
    case skinSmoothing = "Skin smoothing"

    var id: String { rawValue }

    var range: ClosedRange<Double> {
        switch self {
        case .contrast: return 0.65...1.65
        case .saturation: return 0...2
        case .sharpness: return 0...1.5
        case .vignette, .grain, .blurBackground, .skinSmoothing: return 0...1
        default: return -1...1
        }
    }

    var neutralValue: Double {
        switch self {
        case .contrast, .saturation: return 1
        default: return 0
        }
    }
}

extension AdjustmentSettings {
    subscript(control: AdjustmentControl) -> Double {
        get {
            switch control {
            case .brightness: return brightness
            case .contrast: return contrast
            case .saturation: return saturation
            case .shadows: return shadows
            case .highlights: return highlights
            case .warmth: return warmth
            case .tint: return tint
            case .sharpness: return sharpness
            case .vignette: return vignette
            case .grain: return grain
            case .blurBackground: return blurBackground
            case .skinSmoothing: return skinSmoothing
            }
        }
        set {
            switch control {
            case .brightness: brightness = newValue
            case .contrast: contrast = newValue
            case .saturation: saturation = newValue
            case .shadows: shadows = newValue
            case .highlights: highlights = newValue
            case .warmth: warmth = newValue
            case .tint: tint = newValue
            case .sharpness: sharpness = newValue
            case .vignette: vignette = newValue
            case .grain: grain = newValue
            case .blurBackground: blurBackground = newValue
            case .skinSmoothing: skinSmoothing = newValue
            }
        }
    }
}
