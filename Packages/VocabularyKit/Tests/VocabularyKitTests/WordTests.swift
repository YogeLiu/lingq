import Testing
import Foundation
@testable import VocabularyKit
import SharedModels

@Test func wordDefaultValues() {
    let word = Word(text: "equilibrium", contextSentence: "A sense of equilibrium.")
    #expect(word.text == "equilibrium")
    #expect(word.reviewCount == 0)
    #expect(word.easeFactor == 2.5)
    #expect(word.contextSentence == "A sense of equilibrium.")
    #expect(word.nextReviewAt != nil)
}

@Test func wordIsDueForReview() {
    let word = Word(text: "test", contextSentence: nil)
    word.nextReviewAt = Date.distantPast
    #expect(word.isDueForReview == true)

    word.nextReviewAt = Date.distantFuture
    #expect(word.isDueForReview == false)

    word.nextReviewAt = nil
    #expect(word.isDueForReview == false)
}
