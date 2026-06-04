import Foundation

enum PhotoPreset: String, CaseIterable, Identifiable {
    case natural = "Natural"
    case portraitPro = "Portrait Pro"
    case cinematic = "Cinematic"
    case instagramClean = "Instagram Clean"
    case moody = "Moody"
    case warmFilm = "Warm Film"
    case coldUrban = "Cold Urban"
    case blackWhite = "Black & White"
    case luxuryLook = "Luxury Look"
    case softSkin = "Soft Skin"

    var id: String { rawValue }

    var settings: AdjustmentSettings {
        switch self {
        case .natural:
            return AdjustmentSettings(brightness: 0.04, contrast: 1.08, saturation: 1.08, shadows: 0.18, highlights: -0.12, warmth: 0.08, tint: 0, sharpness: 0.28, vignette: 0.05)
        case .portraitPro:
            return AdjustmentSettings(brightness: 0.08, contrast: 1.1, saturation: 1.04, shadows: 0.24, highlights: -0.18, warmth: 0.12, tint: 0.03, sharpness: 0.2, vignette: 0.12, blurBackground: 0.32, skinSmoothing: 0.45)
        case .cinematic:
            return AdjustmentSettings(brightness: -0.02, contrast: 1.22, saturation: 0.92, shadows: 0.08, highlights: -0.25, warmth: -0.08, tint: 0.08, sharpness: 0.36, vignette: 0.32, grain: 0.12, blurBackground: 0.18)
        case .instagramClean:
            return AdjustmentSettings(brightness: 0.12, contrast: 1.12, saturation: 1.12, shadows: 0.26, highlights: -0.16, warmth: 0.06, sharpness: 0.24, vignette: 0.03, skinSmoothing: 0.16)
        case .moody:
            return AdjustmentSettings(brightness: -0.1, contrast: 1.28, saturation: 0.82, shadows: -0.18, highlights: -0.22, warmth: -0.04, tint: 0.05, sharpness: 0.3, vignette: 0.45, grain: 0.18)
        case .warmFilm:
            return AdjustmentSettings(brightness: 0.05, contrast: 1.04, saturation: 0.96, shadows: 0.1, highlights: -0.2, warmth: 0.36, tint: 0.06, sharpness: 0.12, vignette: 0.18, grain: 0.22)
        case .coldUrban:
            return AdjustmentSettings(brightness: -0.02, contrast: 1.2, saturation: 0.88, shadows: 0.02, highlights: -0.18, warmth: -0.34, tint: 0.04, sharpness: 0.42, vignette: 0.25, grain: 0.08)
        case .blackWhite:
            return AdjustmentSettings(brightness: 0.02, contrast: 1.35, saturation: 0, shadows: 0.12, highlights: -0.18, sharpness: 0.5, vignette: 0.36, grain: 0.14)
        case .luxuryLook:
            return AdjustmentSettings(brightness: 0.06, contrast: 1.24, saturation: 1.02, shadows: 0.14, highlights: -0.24, warmth: 0.16, tint: 0.08, sharpness: 0.38, vignette: 0.28, grain: 0.05, blurBackground: 0.2, skinSmoothing: 0.2)
        case .softSkin:
            return AdjustmentSettings(brightness: 0.1, contrast: 1.02, saturation: 1.02, shadows: 0.22, highlights: -0.12, warmth: 0.12, tint: 0.04, sharpness: 0.08, vignette: 0.08, blurBackground: 0.22, skinSmoothing: 0.62)
        }
    }
}
