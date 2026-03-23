import Foundation
import SwiftData
import SharedModels
import SRSKit

@MainActor
public struct VocabularyStore {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Save a word. If it already exists, update context sentence.
    public func saveWord(_ text: String, definition: String? = nil, contextSentence: String?, courseId: UUID?) throws {
        let lowered = text.lowercased()
        let descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.text == lowered })
        if let existing = try modelContext.fetch(descriptor).first {
            if let ctx = contextSentence { existing.contextSentence = ctx }
            if let def = definition { existing.definition = def }
            return
        }

        let word = Word(text: text, contextSentence: contextSentence, courseId: courseId)
        word.definition = definition
        modelContext.insert(word)
    }

    /// Check if a word is already saved
    public func isWordSaved(_ text: String) throws -> Bool {
        let lowered = text.lowercased()
        let descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.text == lowered })
        return try modelContext.fetchCount(descriptor) > 0
    }

    public func gradeReview(word: Word, grade: ReviewGrade) {
        let schedule = SM2Algorithm.schedule(
            grade: grade,
            repetition: word.reviewCount,
            easeFactor: word.easeFactor,
            interval: currentInterval(for: word)
        )
        word.reviewCount = schedule.repetition
        word.easeFactor = schedule.easeFactor
        word.nextReviewAt = Calendar.current.date(byAdding: .day, value: schedule.interval, to: Date())
    }

    public func wordsForReview() throws -> [Word] {
        let now = Date()
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { word in
                word.nextReviewAt != nil && word.nextReviewAt! <= now
            },
            sortBy: [SortDescriptor(\.nextReviewAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func deleteWord(_ word: Word) {
        modelContext.delete(word)
    }

    private func currentInterval(for word: Word) -> Int {
        guard let nextReview = word.nextReviewAt else { return 0 }
        return max(Calendar.current.dateComponents([.day], from: word.createdAt, to: nextReview).day ?? 0, 0)
    }
}
