import SwiftUI
import SwiftData
import SharedModels
import VocabularyKit

struct MeView: View {
    let importRequestID: Int

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]

    @State private var showImporter = false

    init(importRequestID: Int = 0) {
        self.importRequestID = importRequestID
    }

    private var dueCount: Int {
        words.filter(\.isDueForReview).count
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    CollectionsView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("我的合集")
                                .font(.headline)
                            Text("\(courses.count) 门课程")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(AppTheme.brandAccent)
                    }
                }
            }

            Section {
                NavigationLink {
                    FlashcardReviewView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("复习")
                                .font(.headline)
                            Text(dueCount > 0 ? "\(dueCount) 个待复习词" : "暂无到期词")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "rectangle.stack.badge.play")
                            .foregroundStyle(AppTheme.warning)
                    }
                }

                NavigationLink {
                    VocabularyListView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("全部词汇")
                                .font(.headline)
                            Text("\(words.count) 个词")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "character.book.closed.fill")
                            .foregroundStyle(AppTheme.level2Color)
                    }
                }
            } header: {
                Text("学习")
            }

            Section {
                NavigationLink {
                    CourseListView()
                } label: {
                    Label("课程库", systemImage: "books.vertical")
                }
            } header: {
                Text("管理")
            }
        }
        .navigationTitle("Me")
        .navigationBarTitleDisplayMode(.large)
    }
}
