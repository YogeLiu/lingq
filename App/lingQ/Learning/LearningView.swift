import SwiftUI
import SwiftData
import VocabularyKit
import SharedModels

struct LearningView: View {
    let importRequestID: Int

    init(importRequestID: Int = 0) {
        self.importRequestID = importRequestID
    }

    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]
    @Query(sort: \Word.nextReviewAt, order: .forward) private var words: [Word]

    private var dueCount: Int {
        words.filter(\.isDueForReview).count
    }

    private var dueWords: [Word] {
        Array(words.filter(\.isDueForReview).prefix(3))
    }

    private var newWords: [Word] {
        Array(words.sorted { $0.createdAt > $1.createdAt }.prefix(6))
    }

    private var courseLookup: [UUID: String] {
        Dictionary(uniqueKeysWithValues: courses.map { ($0.id, $0.title) })
    }

    var body: some View {
        List {
            Section("复习") {
                NavigationLink {
                    FlashcardReviewView()
                } label: {
                    Label("开始复习", systemImage: "rectangle.stack.badge.play")
                        .badge(dueCount)
                }
            }

            if !dueWords.isEmpty {
                Section("待复习预览") {
                    ForEach(dueWords) { word in
                        WordCardView(word: word, courseTitle: word.courseId.flatMap { courseLookup[$0] })
                    }
                }
            }

            if !newWords.isEmpty {
                Section("最近新增") {
                    ForEach(newWords) { word in
                        WordCardView(word: word, courseTitle: word.courseId.flatMap { courseLookup[$0] })
                    }
                }
            }

            Section {
                NavigationLink("查看全部词汇") {
                    VocabularyListView()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("学习")
    }
}
