import Testing
@testable import VocabularyKit
import SharedModels
import SwiftData

@Test @MainActor func addWordCreatesEntry() throws {
    let container = try ModelContainer(for: Word.self, configurations: .init(isStoredInMemoryOnly: true))
    let store = VocabularyStore(modelContext: container.mainContext)
    try store.addWord("hello", level: .level1, contextSentence: "Hello world", courseId: nil)
    let descriptor = FetchDescriptor<Word>()
    let words = try container.mainContext.fetch(descriptor)
    #expect(words.count == 1)
    #expect(words[0].text == "hello")
    #expect(words[0].level == .level1)
}

@Test @MainActor func addWordDeduplicate() throws {
    let container = try ModelContainer(for: Word.self, configurations: .init(isStoredInMemoryOnly: true))
    let store = VocabularyStore(modelContext: container.mainContext)
    try store.addWord("hello", level: .level1, contextSentence: nil, courseId: nil)
    try store.addWord("hello", level: .level2, contextSentence: nil, courseId: nil)
    let descriptor = FetchDescriptor<Word>()
    let words = try container.mainContext.fetch(descriptor)
    #expect(words.count == 1)
    #expect(words[0].level == .level2)
}
