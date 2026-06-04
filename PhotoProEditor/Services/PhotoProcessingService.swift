import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

final class PhotoProcessingService {
    private let context = CIContext(options: [.cacheIntermediates: true])

    func autoEnhanceSettings(for image: UIImage) -> AdjustmentSettings {
        let hasFace = containsFace(in: image)

        var settings = AdjustmentSettings(
            brightness: 0.08,
            contrast: 1.16,
            saturation: 1.1,
            shadows: 0.28,
            highlights: -0.2,
            warmth: 0.08,
            tint: 0.02,
            sharpness: 0.42,
            vignette: 0.12,
            grain: 0.03,
            blurBackground: hasFace ? 0.28 : 0.08,
            skinSmoothing: hasFace ? 0.34 : 0
        )

        if image.size.width > image.size.height {
            settings.vignette += 0.06
            settings.contrast += 0.04
        }

        return settings
    }

    func render(
        image: UIImage,
        settings: AdjustmentSettings,
        exportQuality: ExportQuality = .high,
        maxPixelDimension: CGFloat? = nil,
        compressOutput: Bool = true
    ) -> UIImage {
        let sourceImage = image.normalizedForEditing().resizedForProcessing(maxPixelDimension: maxPixelDimension)

        guard var current = CIImage(image: sourceImage) else {
            return image
        }

        let originalExtent = current.extent

        current = applyColorControls(to: current, settings: settings)
        current = applyHighlightsAndShadows(to: current, settings: settings)
        current = applyProfessionalToneCurve(to: current, settings: settings)
        current = applyWhiteBalance(to: current, settings: settings)
        current = applyNoiseReduction(to: current, amount: max(settings.skinSmoothing * 0.45, 0.12))
        current = applyBackgroundBlur(to: current, original: sourceImage, amount: settings.blurBackground, extent: originalExtent)
        current = applySkinSmoothing(to: current, amount: settings.skinSmoothing)
        current = applyFaceEnhancement(to: current, original: sourceImage, amount: settings.skinSmoothing, extent: originalExtent)
        current = applySharpness(to: current, amount: settings.sharpness)
        current = applyVignette(to: current, amount: settings.vignette)
        current = applyGrain(to: current, amount: settings.grain, extent: originalExtent)
        current = current.cropped(to: originalExtent)

        guard let cgImage = context.createCGImage(current, from: originalExtent) else {
            return image
        }

        let rendered = UIImage(cgImage: cgImage, scale: sourceImage.scale, orientation: .up)
        guard compressOutput else {
            return rendered
        }

        guard let data = rendered.jpegData(compressionQuality: exportQuality.compressionQuality),
              let compressed = UIImage(data: data) else {
            return rendered
        }
        return compressed
    }

    private func applyColorControls(to image: CIImage, settings: AdjustmentSettings) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = Float(settings.brightness * 0.24)
        filter.contrast = Float(settings.contrast)
        filter.saturation = Float(settings.saturation)
        return filter.outputImage ?? image
    }

    private func applyProfessionalToneCurve(to image: CIImage, settings: AdjustmentSettings) -> CIImage {
        let lift = max(settings.shadows, 0) * 0.08
        let shoulder = max(-settings.highlights, 0) * 0.08
        let contrastPush = max(settings.contrast - 1, 0) * 0.04

        guard lift > 0.001 || shoulder > 0.001 || contrastPush > 0.001 else {
            return image
        }

        let filter = CIFilter(name: "CIToneCurve")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(x: 0, y: lift), forKey: "inputPoint0")
        filter?.setValue(CIVector(x: 0.25, y: 0.25 + lift * 0.6), forKey: "inputPoint1")
        filter?.setValue(CIVector(x: 0.5, y: 0.5 + contrastPush), forKey: "inputPoint2")
        filter?.setValue(CIVector(x: 0.75, y: 0.75 - shoulder * 0.45), forKey: "inputPoint3")
        filter?.setValue(CIVector(x: 1, y: 1 - shoulder), forKey: "inputPoint4")
        return filter?.outputImage ?? image
    }

    private func applyHighlightsAndShadows(to image: CIImage, settings: AdjustmentSettings) -> CIImage {
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = image
        filter.shadowAmount = Float(1 + settings.shadows * 0.75)
        filter.highlightAmount = Float(max(0.25, 1 + settings.highlights * 0.65))
        return filter.outputImage ?? image
    }

    private func applyWhiteBalance(to image: CIImage, settings: AdjustmentSettings) -> CIImage {
        guard abs(settings.warmth) > 0.001 || abs(settings.tint) > 0.001 else {
            return image
        }

        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        filter.neutral = CIVector(x: 6500 + settings.warmth * 1700, y: settings.tint * 90)
        filter.targetNeutral = CIVector(x: 6500, y: 0)
        return filter.outputImage ?? image
    }

    private func applyNoiseReduction(to image: CIImage, amount: Double) -> CIImage {
        let filter = CIFilter.noiseReduction()
        filter.inputImage = image
        filter.noiseLevel = Float(min(max(amount, 0), 0.8) * 0.04)
        filter.sharpness = 0.38
        return filter.outputImage ?? image
    }

    private func applySharpness(to image: CIImage, amount: Double) -> CIImage {
        guard amount > 0.001 else { return image }

        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.radius = Float(1 + amount * 2.8)
        filter.intensity = Float(amount * 0.8)
        return filter.outputImage ?? image
    }

    private func applyVignette(to image: CIImage, amount: Double) -> CIImage {
        guard amount > 0.001 else { return image }

        let filter = CIFilter.vignette()
        filter.inputImage = image
        filter.radius = Float(1.2 + (1 - amount) * 1.8)
        filter.intensity = Float(amount * 1.2)
        return filter.outputImage ?? image
    }

    private func applyGrain(to image: CIImage, amount: Double, extent: CGRect) -> CIImage {
        guard amount > 0.001,
              let random = CIFilter(name: "CIRandomGenerator")?.outputImage?.cropped(to: extent) else {
            return image
        }

        let monochrome = CIFilter.colorControls()
        monochrome.inputImage = random
        monochrome.saturation = 0
        monochrome.brightness = 0
        monochrome.contrast = Float(1.4 + amount * 2)

        let alpha = CIFilter.colorMatrix()
        alpha.inputImage = monochrome.outputImage
        alpha.aVector = CIVector(x: 0, y: 0, z: 0, w: amount * 0.18)

        let blend = CIFilter.softLightBlendMode()
        blend.inputImage = alpha.outputImage
        blend.backgroundImage = image
        return blend.outputImage?.cropped(to: extent) ?? image
    }

    private func applyBackgroundBlur(to image: CIImage, original: UIImage, amount: Double, extent: CGRect) -> CIImage {
        guard amount > 0.001,
              let mask = personMask(for: original, extent: extent) else {
            return image
        }

        let blur = CIFilter.gaussianBlur()
        blur.inputImage = image.clampedToExtent()
        blur.radius = Float(2 + amount * 12)

        let blend = CIFilter.blendWithMask()
        blend.inputImage = image
        blend.backgroundImage = blur.outputImage?.cropped(to: extent)
        blend.maskImage = mask
        return blend.outputImage?.cropped(to: extent) ?? image
    }

    private func applySkinSmoothing(to image: CIImage, amount: Double) -> CIImage {
        guard amount > 0.001 else { return image }

        let smooth = CIFilter.noiseReduction()
        smooth.inputImage = image
        smooth.noiseLevel = Float(amount * 0.06)
        smooth.sharpness = Float(max(0.1, 0.45 - amount * 0.25))

        let color = CIFilter.colorControls()
        color.inputImage = smooth.outputImage ?? image
        color.saturation = Float(1 - amount * 0.05)
        color.contrast = Float(1 - amount * 0.04)
        return color.outputImage ?? image
    }

    private func applyFaceEnhancement(to image: CIImage, original: UIImage, amount: Double, extent: CGRect) -> CIImage {
        let features = faceFeatures(in: original)
        guard !features.isEmpty else { return image }

        var current = image
        let faceLift = max(0.12, amount * 0.26)

        for feature in features {
            current = blendAdjustedImage(
                current,
                adjusted: exposureAdjusted(current, ev: faceLift),
                center: CGPoint(x: feature.bounds.midX, y: feature.bounds.midY),
                innerRadius: min(feature.bounds.width, feature.bounds.height) * 0.24,
                outerRadius: max(feature.bounds.width, feature.bounds.height) * 0.72,
                extent: extent
            )

            let eyeDetail = unsharpImage(current, radius: 1.2, intensity: 0.48)
            if feature.hasLeftEyePosition {
                current = blendAdjustedImage(
                    current,
                    adjusted: eyeDetail,
                    center: feature.leftEyePosition,
                    innerRadius: feature.bounds.width * 0.035,
                    outerRadius: feature.bounds.width * 0.12,
                    extent: extent
                )
            }

            if feature.hasRightEyePosition {
                current = blendAdjustedImage(
                    current,
                    adjusted: eyeDetail,
                    center: feature.rightEyePosition,
                    innerRadius: feature.bounds.width * 0.035,
                    outerRadius: feature.bounds.width * 0.12,
                    extent: extent
                )
            }
        }

        return current
    }

    private func exposureAdjusted(_ image: CIImage, ev: Double) -> CIImage {
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = image
        filter.ev = Float(ev)
        return filter.outputImage ?? image
    }

    private func unsharpImage(_ image: CIImage, radius: Double, intensity: Double) -> CIImage {
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.radius = Float(radius)
        filter.intensity = Float(intensity)
        return filter.outputImage ?? image
    }

    private func blendAdjustedImage(
        _ image: CIImage,
        adjusted: CIImage,
        center: CGPoint,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        extent: CGRect
    ) -> CIImage {
        let gradient = CIFilter.radialGradient()
        gradient.center = center
        gradient.radius0 = Float(innerRadius)
        gradient.radius1 = Float(outerRadius)
        gradient.color0 = CIColor(red: 1, green: 1, blue: 1, alpha: 1)
        gradient.color1 = CIColor(red: 0, green: 0, blue: 0, alpha: 0)

        let blend = CIFilter.blendWithMask()
        blend.inputImage = adjusted
        blend.backgroundImage = image
        blend.maskImage = gradient.outputImage?.cropped(to: extent)
        return blend.outputImage?.cropped(to: extent) ?? image
    }

    private func personMask(for image: UIImage, extent: CGRect) -> CIImage? {
        guard let cgImage = image.normalizedForEditing().cgImage else { return nil }

        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            guard let pixelBuffer = request.results?.first?.pixelBuffer else { return nil }
            let mask = CIImage(cvPixelBuffer: pixelBuffer)
            let scaleX = extent.width / mask.extent.width
            let scaleY = extent.height / mask.extent.height
            return mask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        } catch {
            return nil
        }
    }

    private func containsFace(in image: UIImage) -> Bool {
        !faceFeatures(in: image).isEmpty
    }

    private func faceFeatures(in image: UIImage) -> [CIFaceFeature] {
        guard let ciImage = CIImage(image: image.normalizedForEditing()) else {
            return []
        }

        let detector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: context,
            options: [CIDetectorAccuracy: CIDetectorAccuracyLow]
        )
        return detector?.features(in: ciImage).compactMap { $0 as? CIFaceFeature } ?? []
    }
}

private extension UIImage {
    func normalizedForEditing() -> UIImage {
        guard imageOrientation != .up else { return self }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func resizedForProcessing(maxPixelDimension: CGFloat?) -> UIImage {
        guard let maxPixelDimension else { return self }

        let longestSide = max(size.width, size.height)
        guard longestSide > maxPixelDimension else { return self }

        let scaleRatio = maxPixelDimension / longestSide
        let targetSize = CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
