import SwiftData
import SwiftUI

@main
struct OpenVoiceApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: TranscriptionItem.self)
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        MenuBarExtra("Open Voice", systemImage: "waveform.badge.mic") {
            MainMenuView()
                .modelContainer(modelContainer)
        }
        .menuBarExtraStyle(.window)
    }
}
