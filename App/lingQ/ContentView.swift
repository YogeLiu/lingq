import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("课程", systemImage: "books.vertical") {
                NavigationStack {
                    CourseListView()
                }
            }

            Tab("生词本", systemImage: "character.book.closed") {
                NavigationStack {
                    VocabularyListView()
                }
            }

            Tab("复习", systemImage: "sparkles.rectangle.stack") {
                NavigationStack {
                    FlashcardReviewView()
                }
            }
        }
    }
}
