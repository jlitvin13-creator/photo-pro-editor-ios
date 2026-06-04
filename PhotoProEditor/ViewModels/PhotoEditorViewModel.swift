import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class PhotoEditorViewModel: ObservableObject {
    @Published var originalImage: UIImage?
    @Published var previewImage: UIImage?
    @Published var settings = AdjustmentSettings.original
    @Published var selectedPreset: PhotoPreset?
    @Published var exportQuality: ExportQuality = .high
    @Published var isProcessing = false
    @Published var showOriginal = false
    @Published var statusMessage: String?

    private let processingService = PhotoProcessingService()
    private let libraryService = PhotoLibraryService()
    private var renderTask: Task<Void, Never>?
    private var history: [AdjustmentSettings] = [.original]
    private var historyIndex = 0

    var canUndo: Bool { historyIndex > 0 }
    var canRedo: Bool { historyIndex < history.count - 1 }
    var hasImage: Bool { originalImage != nil }

    func loadImage(_ image: UIImage) {
        renderTask?.cancel()
        originalImage = image
        previewImage = image
        settings = .original
        selectedPreset = nil
        history = [.original]
        historyIndex = 0
        statusMessage = nil
    }

    func autoEnhance() {
        guard let originalImage else { return }
        selectedPreset = nil
        settings = processingService.autoEnhanceSettings(for: originalImage)
        commitHistory()
        renderPreview()
    }

    func applyPreset(_ preset: PhotoPreset) {
        selectedPreset = preset
        settings = preset.settings
        commitHistory()
        renderPreview()
    }

    func setAdjustment(_ control: AdjustmentControl, value: Double) {
        selectedPreset = nil
        settings[control] = value
        renderPreview()
    }

    func finishAdjustmentChange() {
        commitHistory()
    }

    func undo() {
        guard canUndo else { return }
        historyIndex -= 1
        settings = history[historyIndex]
        selectedPreset = nil
        renderPreview()
    }

    func redo() {
        guard canRedo else { return }
        historyIndex += 1
        settings = history[historyIndex]
        selectedPreset = nil
        renderPreview()
    }

    func reset() {
        settings = .original
        selectedPreset = nil
        commitHistory()
        renderPreview()
    }

    func saveToGallery() {
        guard let image = finalImageForExport() else { return }
        isProcessing = true
        libraryService.save(image) { [weak self] result in
            Task { @MainActor in
                self?.isProcessing = false
                switch result {
                case .success:
                    self?.statusMessage = "Saved to Photos"
                case .failure(let error):
                    self?.statusMessage = error.localizedDescription
                }
            }
        }
    }

    func finalImageForExport() -> UIImage? {
        guard let originalImage else { return nil }
        return processingService.render(image: originalImage, settings: settings, exportQuality: exportQuality)
    }

    private func renderPreview() {
        guard let originalImage else { return }
        let currentSettings = settings

        renderTask?.cancel()
        isProcessing = true

        renderTask = Task.detached(priority: .userInitiated) { [processingService, exportQuality] in
            let image = processingService.render(
                image: originalImage,
                settings: currentSettings,
                exportQuality: exportQuality,
                maxPixelDimension: 1800,
                compressOutput: false
            )
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.previewImage = image
                self.isProcessing = false
            }
        }
    }

    private func commitHistory() {
        guard history.indices.contains(historyIndex), history[historyIndex] != settings else { return }

        if historyIndex < history.count - 1 {
            history.removeSubrange((historyIndex + 1)..<history.count)
        }

        history.append(settings)
        historyIndex = history.count - 1
    }
}
