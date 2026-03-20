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

    public func addWord(_ text: String, level: WordLevel, contextSentence: String?, courseId: UUID?) throws {
        // Dedup: if word already exists, update its level
        let lowered = text.lowercased()
        let descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.text == lowered })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.level = level
            if let ctx = contextSentence { existing.contextSentence = ctx }
            return
        }

        let word = Word(text: text, contextSentence: contextSentence)
        word.level = level
        word.courseId = courseId
        modelContext.insert(word)
    }

    public func updateLevel(word: Word, to level: WordLevel) {
        word.level = level
        if level == .level1 && word.nextReviewAt == nil {
            // First time marked as learning — schedule first review
            word.nextReviewAt = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        }
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

    public func wordCount(level: WordLevel, courseId: UUID? = nil) throws -> Int {
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { $0.level == level }
        )
        return try modelContext.fetchCount(descriptor)
    }

    private func currentInterval(for word: Word) -> Int {
        guard let nextReview = word.nextReviewAt else { return 0 }
        return max(Calendar.current.dateComponents([.day], from: word.createdAt, to: nextReview).day ?? 0, 0)
    }
}
