import Testing
@testable import SharedModels

@Test func wordLevelRawValues() {
    #expect(WordLevel.new.rawValue == 0)
    #expect(WordLevel.level1.rawValue == 1)
    #expect(WordLevel.level2.rawValue == 2)
    #expect(WordLevel.level3.rawValue == 3)
    #expect(WordLevel.known.rawValue == 4)
}

@Test func wordLevelDisplayName() {
    #expect(WordLevel.level2.displayName == "INTERMEDIATE")
    #expect(WordLevel.known.displayName == "KNOWN")
}

@Test func wordLevelIsLearning() {
    #expect(WordLevel.new.isLearning == false)
    #expect(WordLevel.level1.isLearning == true)
    #expect(WordLevel.level2.isLearning == true)
    #expect(WordLevel.level3.isLearning == true)
    #expect(WordLevel.known.isLearning == false)
}
