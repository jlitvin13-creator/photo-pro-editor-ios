# Pro Auto Edit

SwiftUI MVP of a local iPhone photo editor focused on one-tap professional enhancement.

## Included

- Import photo from the gallery with `PhotosPicker`
- Capture photo from camera with `UIImagePickerController`
- Preview with hold-to-compare Before / After
- One-tap Auto Enhance
- Presets: Natural, Portrait Pro, Cinematic, Instagram Clean, Moody, Warm Film, Cold Urban, Black & White, Luxury Look, Soft Skin
- Manual sliders for brightness, contrast, saturation, shadows, highlights, warmth, tint, sharpness, vignette, grain, background blur, and skin smoothing
- Undo, redo, and reset
- Export quality selector: High / Medium
- Save to Photos and share sheet
- Fast lower-resolution live preview and full-resolution final export
- Local processing with Core Image and Vision person segmentation when available
- Tone-curve polish, subtle portrait face lift, and local eye detail enhancement
- Generated 1024x1024 app icon in the asset catalog

## Structure

- `PhotoProEditorApp.swift` - app entry point
- `Views/` - SwiftUI editor UI and UIKit bridges
- `ViewModels/PhotoEditorViewModel.swift` - editor state, history, import/export commands
- `Services/PhotoProcessingService.swift` - local Core Image / Vision processing pipeline
- `Services/PhotoLibraryService.swift` - saving edited images to Photos
- `Models/` - presets, slider controls, adjustment values, export quality

## Run

Open `PhotoProEditor.xcodeproj` in Xcode on macOS, select an iPhone simulator or device, set your Apple development team if needed, then run.

Camera capture requires a physical iPhone. The simulator can still import photos from the library.

## Run Without a Mac

The `web/` folder contains a Progressive Web App version for iPhone Safari. It runs locally in the browser, supports photo import/camera capture, auto enhance, presets, manual sliders, before/after comparison, save, share, and home-screen installation.

When published with GitHub Pages, open the Pages URL on iPhone, tap Share, then choose Add to Home Screen.
