import Testing
@testable import SharedModels

@Test func wordLevelRawValues() {
    #expect(WordLevel.saved.rawValue == 1)
    #expect(WordLevel.known.rawValue == 4)
}

@Test func wordLevelDisplayName() {
    #expect(WordLevel.saved.displayName == "SAVED")
    #expect(WordLevel.known.displayName == "KNOWN")
}

@Test func wordLevelCaseIterable() {
    #expect(WordLevel.allCases.count == 2)
}
