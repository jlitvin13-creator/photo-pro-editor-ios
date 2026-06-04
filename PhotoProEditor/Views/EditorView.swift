import PhotosUI
import SwiftUI
import UIKit

struct EditorView: View {
    @StateObject private var viewModel = PhotoEditorViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isShowingCamera = false
    @State private var isShowingShareSheet = false
    @State private var selectedTool: ToolTab = .presets

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color(red: 0.08, green: 0.09, blue: 0.1)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if viewModel.hasImage {
                    previewArea
                    toolPanel
                } else {
                    emptyEditor
                }
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraPicker { image in
                viewModel.loadImage(image)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let image = viewModel.finalImageForExport() {
                ShareSheet(items: [image])
            }
        }
        .alert("Photo Editor", isPresented: Binding(
            get: { viewModel.statusMessage != nil },
            set: { if !$0 { viewModel.statusMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.statusMessage ?? "")
        }
        .onChange(of: selectedPhotoItem) { item in
            Task {
                guard let data = try? await item?.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                await MainActor.run {
                    viewModel.loadImage(image)
                    selectedPhotoItem = nil
                }
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Text("Pro Auto Edit")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            if viewModel.hasImage {
                iconButton(systemName: "arrow.uturn.backward", disabled: !viewModel.canUndo) {
                    viewModel.undo()
                }
                iconButton(systemName: "arrow.uturn.forward", disabled: !viewModel.canRedo) {
                    viewModel.redo()
                }
                iconButton(systemName: "arrow.counterclockwise") {
                    viewModel.reset()
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var emptyEditor: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "camera.aperture")
                .font(.system(size: 66, weight: .light))
                .foregroundStyle(.white.opacity(0.86))

            VStack(spacing: 8) {
                Text("Load a photo")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Choose a shot and apply a clean professional edit in one tap.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)
            }

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Gallery", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryToolButtonStyle())

                Button {
                    isShowingCamera = true
                } label: {
                    Label("Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryToolButtonStyle())
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
            }
            .padding(.horizontal, 18)

            Spacer()
        }
    }

    private var previewArea: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black

                if let image = viewModel.showOriginal ? viewModel.originalImage : viewModel.previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.18), value: viewModel.showOriginal)
                }

                VStack {
                    HStack {
                        Text(viewModel.showOriginal ? "Before" : "After")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.55), in: Capsule())
                        Spacer()
                    }
                    Spacer()
                }
                .padding(14)

                if viewModel.isProcessing {
                    ProgressView()
                        .tint(.white)
                        .padding(18)
                        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 12)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in viewModel.showOriginal = true }
                    .onEnded { _ in viewModel.showOriginal = false }
            )
        }
        .frame(maxHeight: .infinity)
    }

    private var toolPanel: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    viewModel.autoEnhance()
                } label: {
                    Label("Auto Enhance", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryToolButtonStyle())

                Button {
                    viewModel.showOriginal.toggle()
                } label: {
                    Label("Before / After", systemImage: "rectangle.lefthalf.filled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryToolButtonStyle())
            }

            Picker("Tools", selection: $selectedTool) {
                ForEach(ToolTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch selectedTool {
                case .presets:
                    presetScroller
                case .adjust:
                    adjustmentsList
                case .export:
                    exportPanel
                }
            }
            .frame(height: 182)
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.black.opacity(0.72))
    }

    private var presetScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PhotoPreset.allCases) { preset in
                    Button {
                        viewModel.applyPreset(preset)
                    } label: {
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(presetGradient(for: preset))
                                .frame(width: 86, height: 104)
                                .overlay(alignment: .bottomLeading) {
                                    Image(systemName: preset == .blackWhite ? "circle.lefthalf.filled" : "camera.filters")
                                        .font(.body.weight(.semibold))
                                        .padding(10)
                                }
                            Text(preset.rawValue)
                                .font(.caption2.weight(.medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 92)
                        .overlay {
                            if viewModel.selectedPreset == preset {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var adjustmentsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ForEach(AdjustmentControl.allCases) { control in
                    VStack(spacing: 6) {
                        HStack {
                            Text(control.rawValue)
                                .font(.caption.weight(.semibold))
                            Spacer()
                            Text(valueText(for: control))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.58))
                        }

                        Slider(
                            value: Binding(
                                get: { viewModel.settings[control] },
                                set: { viewModel.setAdjustment(control, value: $0) }
                            ),
                            in: control.range,
                            onEditingChanged: { isEditing in
                                if !isEditing { viewModel.finishAdjustmentChange() }
                            }
                        )
                        .tint(.white)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private var exportPanel: some View {
        VStack(spacing: 14) {
            Picker("Quality", selection: $viewModel.exportQuality) {
                ForEach(ExportQuality.allCases) { quality in
                    Text(quality.rawValue).tag(quality)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Button {
                    viewModel.saveToGallery()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryToolButtonStyle())

                Button {
                    isShowingShareSheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryToolButtonStyle())
            }

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Replace", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryToolButtonStyle())

                Button {
                    isShowingCamera = true
                } label: {
                    Label("Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryToolButtonStyle())
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
            }
        }
    }

    private func iconButton(systemName: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(disabled ? 0.05 : 0.12), in: Circle())
        }
        .foregroundStyle(.white.opacity(disabled ? 0.32 : 0.95))
        .disabled(disabled)
    }

    private func valueText(for control: AdjustmentControl) -> String {
        let value = viewModel.settings[control]
        if control == .contrast || control == .saturation {
            return String(format: "%.2f", value)
        }
        return String(format: "%+.2f", value)
    }

    private func presetGradient(for preset: PhotoPreset) -> LinearGradient {
        switch preset {
        case .natural:
            return LinearGradient(colors: [.green.opacity(0.55), .cyan.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .portraitPro:
            return LinearGradient(colors: [.pink.opacity(0.62), .orange.opacity(0.42)], startPoint: .top, endPoint: .bottom)
        case .cinematic:
            return LinearGradient(colors: [.teal.opacity(0.75), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .instagramClean:
            return LinearGradient(colors: [.white.opacity(0.72), .mint.opacity(0.42)], startPoint: .top, endPoint: .bottom)
        case .moody:
            return LinearGradient(colors: [.gray.opacity(0.7), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .warmFilm:
            return LinearGradient(colors: [.yellow.opacity(0.55), .red.opacity(0.36)], startPoint: .top, endPoint: .bottom)
        case .coldUrban:
            return LinearGradient(colors: [.blue.opacity(0.62), .gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blackWhite:
            return LinearGradient(colors: [.white.opacity(0.72), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .luxuryLook:
            return LinearGradient(colors: [.purple.opacity(0.5), .yellow.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .softSkin:
            return LinearGradient(colors: [.pink.opacity(0.48), .white.opacity(0.5)], startPoint: .top, endPoint: .bottom)
        }
    }
}

private enum ToolTab: String, CaseIterable, Identifiable {
    case presets
    case adjust
    case export

    var id: String { rawValue }

    var title: String {
        switch self {
        case .presets: return "Presets"
        case .adjust: return "Adjust"
        case .export: return "Export"
        }
    }

    var icon: String {
        switch self {
        case .presets: return "camera.filters"
        case .adjust: return "slider.horizontal.3"
        case .export: return "square.and.arrow.up"
        }
    }
}

private struct PrimaryToolButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? Color.white.opacity(0.78) : Color.white, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SecondaryToolButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? Color.white.opacity(0.18) : Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.12))
            }
    }
}
