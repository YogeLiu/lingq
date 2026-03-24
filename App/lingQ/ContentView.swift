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
            Tab("首页", systemImage: "house.fill", value: .playlist) {
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

            Tab("词汇", systemImage: "character.book.closed.fill", value: .vocabulary) {
                NavigationStack {
                    VocabularyListView()
                }
            }

            Tab("复习", systemImage: "rectangle.stack.badge.play", value: .review) {
                NavigationStack {
                    FlashcardReviewView()
                }
            }

            Tab("我的", systemImage: "person.crop.circle", value: .me) {
                NavigationStack {
                    MeView(importRequestID: importRequestID)
                }
            }
        }
        .tint(AppTheme.brandAccent)
        .toolbarBackground(AppTheme.chromeBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
