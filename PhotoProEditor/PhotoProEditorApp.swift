import SwiftUI

@main
struct PhotoProEditorApp: App {
    var body: some Scene {
        WindowGroup {
            EditorView()
                .preferredColorScheme(.dark)
        }
    }
}
