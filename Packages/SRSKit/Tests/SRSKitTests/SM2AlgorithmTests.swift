import Testing
@testable import SRSKit

@Test func againResetsRepetition() {
    let result = SM2Algorithm.schedule(
        grade: .again,
        repetition: 3,
        easeFactor: 2.5,
        interval: 10
    )
    #expect(result.repetition == 0)
    #expect(result.interval == 1)
}

@Test func goodUsesEaseFactor() {
    let result = SM2Algorithm.schedule(
        grade: .good,
        repetition: 2,
        easeFactor: 2.5,
        interval: 6
    )
    #expect(result.interval == 15)  // 6 * 2.5 = 15
    #expect(result.easeFactor == 2.5)  // good doesn't change easeFactor
}

@Test func easyIncreasesEaseFactor() {
    let result = SM2Algorithm.schedule(
        grade: .easy,
        repetition: 2,
        easeFactor: 2.5,
        interval: 6
    )
    #expect(result.interval == 19)  // 6 * 2.5 * 1.3 ≈ 19.5, truncated to 19
    #expect(result.easeFactor > 2.5)
}

@Test func hardDecreasesEaseFactor() {
    let result = SM2Algorithm.schedule(
        grade: .hard,
        repetition: 2,
        easeFactor: 2.5,
        interval: 6
    )
    #expect(result.interval == 7)  // 6 * 1.2 = 7.2, truncated to 7
    #expect(result.easeFactor == 2.35)  // 2.5 - 0.15
}

@Test func easeFactorNeverBelowMinimum() {
    let result = SM2Algorithm.schedule(
        grade: .hard,
        repetition: 2,
        easeFactor: 1.35,
        interval: 6
    )
    #expect(result.easeFactor == 1.3)  // minimum
}

@Test func firstRepetitionIntervalIsOne() {
    let result = SM2Algorithm.schedule(
        grade: .good,
        repetition: 0,
        easeFactor: 2.5,
        interval: 0
    )
    #expect(result.interval == 1)
    #expect(result.repetition == 1)
}

@Test func secondRepetitionIntervalIsSix() {
    let result = SM2Algorithm.schedule(
        grade: .good,
        repetition: 1,
        easeFactor: 2.5,
        interval: 1
    )
    #expect(result.interval == 6)
    #expect(result.repetition == 2)
}
