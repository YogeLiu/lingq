import SwiftUI
import SwiftData
import SharedModels
import VocabularyKit
import AudioPlayerKit

@main
struct lingQApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Course.self, Word.self])
    }

    init() {
        AudioPlayer.configureAudioSession()
    }
}
