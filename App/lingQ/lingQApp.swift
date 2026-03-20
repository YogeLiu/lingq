import SwiftUI
import SwiftData
import SharedModels
import VocabularyKit
import AudioPlayerKit

@main
struct lingQApp: App {
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.colorScheme)
                .environment(themeManager)
        }
        .modelContainer(for: [Course.self, Word.self])
    }

    init() {
        AudioPlayer.configureAudioSession()
    }
}
