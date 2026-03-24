import SwiftUI
import SwiftData
import SharedModels
import VocabularyKit

struct MeView: View {
    let importRequestID: Int

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]

    @State private var showZipImport = false

    init(importRequestID: Int = 0) {
        self.importRequestID = importRequestID
    }

    private var dueCount: Int {
        words.filter(\.isDueForReview).count
    }

    var body: some View {
        List {
            Section {
                Button {
                    showZipImport = true
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("从文件导入 ZIP")
                                .font(.headline)
                            Text("封面、音频、字幕会自动解压并入库")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "doc.zipper")
                            .foregroundStyle(AppTheme.brandAccent)
                    }
                }
            } header: {
                Text("导入")
            }

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
                            .foregroundStyle(AppTheme.brandAccent)
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
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("我的")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: importRequestID) { _, newValue in
            if newValue > 0 {
                showZipImport = true
            }
        }
        .sheet(isPresented: $showZipImport) {
            ZipImportView()
        }
    }
}
