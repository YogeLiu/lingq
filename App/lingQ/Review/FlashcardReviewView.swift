import SwiftUI
import SwiftData
import VocabularyKit
import SRSKit

struct FlashcardReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var reviewWords: [Word] = []
    @State private var currentIndex = 0
    @State private var showSummary = false
    @State private var grades: [ReviewGrade] = []

    private var dueCount: Int { reviewWords.count }

    var body: some View {
        Group {
            if showSummary {
                ReviewSummaryView(
                    totalReviewed: grades.count,
                    againCount: grades.filter { $0 == .again }.count,
                    hardCount: grades.filter { $0 == .hard }.count,
                    goodCount: grades.filter { $0 == .good }.count,
                    easyCount: grades.filter { $0 == .easy }.count,
                    onDone: { showSummary = false; loadWords() }
                )
            } else if reviewWords.isEmpty {
                ContentUnavailableView {
                    Label("暂无待复习单词", systemImage: "sparkles")
                } description: {
                    Text("在精读模式中标记生词后，会按照间隔重复计划出现在这里")
                }
            } else if currentIndex < reviewWords.count {
                VStack {
                    // 进度
                    Text("\(currentIndex + 1) / \(dueCount)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    FlashcardView(word: reviewWords[currentIndex]) { grade in
                        gradeWord(grade)
                    }
                }
            }
        }
        .navigationTitle("复习")
        .task { loadWords() }
    }

    private func loadWords() {
        let store = VocabularyStore(modelContext: modelContext)
        reviewWords = (try? store.wordsForReview()) ?? []
        currentIndex = 0
        grades = []
        showSummary = false
    }

    private func gradeWord(_ grade: ReviewGrade) {
        let store = VocabularyStore(modelContext: modelContext)
        store.gradeReview(word: reviewWords[currentIndex], grade: grade)
        grades.append(grade)
        currentIndex += 1
        if currentIndex >= reviewWords.count {
            showSummary = true
        }
    }
}
