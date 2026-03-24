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
    @State private var playbackManager = PlaybackManager()
    @State private var playlistPath = NavigationPath()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: Binding(
            get: { selectedTab },
            set: { newTab in
                // Switch tab without animation to prevent mini player bounce
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    selectedTab = newTab
                }
            }
        )) {
            Tab("首页", systemImage: "house.fill", value: .playlist) {
                NavigationStack(path: $playlistPath) {
                    HomeView {
                        selectedTab = .me
                        importRequestID += 1
                    }
                    .withMiniPlayer(playbackManager: playbackManager) {
                        navigateToPlayer()
                    }
                    .navigationDestination(for: Course.self) { course in
                        PlaybackDetailView(course: course)
                    }
                }
            }

            Tab("词汇", systemImage: "character.book.closed.fill", value: .vocabulary) {
                NavigationStack {
                    VocabularyListView()
                        .withMiniPlayer(playbackManager: playbackManager) {
                            navigateToPlayer()
                        }
                }
            }

            Tab("复习", systemImage: "rectangle.stack.badge.play", value: .review) {
                NavigationStack {
                    FlashcardReviewView()
                        .withMiniPlayer(playbackManager: playbackManager) {
                            navigateToPlayer()
                        }
                }
            }

            Tab("我的", systemImage: "person.crop.circle", value: .me) {
                NavigationStack {
                    MeView(importRequestID: importRequestID)
                        .withMiniPlayer(playbackManager: playbackManager) {
                            navigateToPlayer()
                        }
                }
            }
        }
        .environment(playbackManager)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                playbackManager.saveProgress()
            }
        }
    }

    private func navigateToPlayer() {
        if let course = playbackManager.currentCourse {
            selectedTab = .playlist
            playlistPath = NavigationPath([course])
        }
    }
}

private extension View {
    func withMiniPlayer(playbackManager: PlaybackManager, onTap: @escaping () -> Void) -> some View {
        self.safeAreaInset(edge: .bottom, spacing: 0) {
            MiniPlayerBar(playbackManager: playbackManager, onTap: onTap)
        }
    }
}
