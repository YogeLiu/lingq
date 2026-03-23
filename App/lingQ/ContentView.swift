import SwiftUI
import SharedModels

struct ContentView: View {
    private enum TabSelection: Hashable {
        case playlist
        case vocabulary
        case review
        case me
    }

    @State private var selectedTab: TabSelection = .playlist
    @State private var importRequestID = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Playlist", systemImage: "play.square.stack", value: .playlist) {
                NavigationStack {
                    HomeView {
                        selectedTab = .me
                        importRequestID += 1
                    }
                    .navigationDestination(for: Course.self) { course in
                        PlaybackDetailView(course: course)
                    }
                }
            }

            Tab("Vocabulary", systemImage: "character.book.closed.fill", value: .vocabulary) {
                NavigationStack {
                    VocabularyListView()
                }
            }

            Tab("Review", systemImage: "rectangle.stack.badge.play", value: .review) {
                NavigationStack {
                    FlashcardReviewView()
                }
            }

            Tab("Me", systemImage: "person.crop.circle", value: .me) {
                NavigationStack {
                    MeView(importRequestID: importRequestID)
                }
            }
        }
        .tint(AppTheme.brandAccent)
    }
}
