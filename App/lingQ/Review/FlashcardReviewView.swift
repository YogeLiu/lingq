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
                    Label("没有需要复习的词汇", systemImage: "rectangle.on.rectangle")
                } description: {
                    Text("保存的词汇会按照记忆曲线安排复习")
                }
            } else if currentIndex < reviewWords.count {
                VStack(spacing: 16) {
                    Text("\(currentIndex + 1) / \(dueCount)")
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))

                    FlashcardView(word: reviewWords[currentIndex]) { grade in
                        gradeWord(grade)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
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
