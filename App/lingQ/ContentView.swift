import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("课程", systemImage: "books.vertical") {
                NavigationStack {
                    Text("课程列表")
                        .navigationTitle("我的课程")
                }
            }

            Tab("生词本", systemImage: "character.book.closed") {
                NavigationStack {
                    Text("生词本")
                        .navigationTitle("生词本")
                }
            }

            Tab("复习", systemImage: "sparkles.rectangle.stack") {
                NavigationStack {
                    Text("闪卡复习")
                        .navigationTitle("复习")
                }
            }
        }
    }
}
