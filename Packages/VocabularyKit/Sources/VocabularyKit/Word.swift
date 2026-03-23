import Foundation
import SwiftData
import SharedModels

@Model
public final class Word {
    public var id: UUID
    public var text: String
    public var definition: String?
    public var phonetic: String?
    public var contextSentence: String?
    public var courseId: UUID?
    public var createdAt: Date
    public var nextReviewAt: Date?
    public var reviewCount: Int
    public var easeFactor: Double

    public init(text: String, contextSentence: String?, courseId: UUID? = nil) {
        self.id = UUID()
        self.text = text.lowercased()
        self.definition = nil
        self.phonetic = nil
        self.contextSentence = contextSentence
        self.courseId = courseId
        self.createdAt = Date()
        self.nextReviewAt = Date() // schedule review immediately
        self.reviewCount = 0
        self.easeFactor = 2.5
    }

    public var isDueForReview: Bool {
        guard let nextReviewAt else { return false }
        return nextReviewAt <= Date()
    }
}
