import Testing
@testable import VocabularyKit
import SharedModels
import SwiftData

@Test @MainActor func saveWordCreatesEntry() throws {
    let container = try ModelContainer(for: Word.self, configurations: .init(isStoredInMemoryOnly: true))
    let store = VocabularyStore(modelContext: container.mainContext)
    try store.saveWord("hello", contextSentence: "Hello world", courseId: nil)
    let descriptor = FetchDescriptor<Word>()
    let words = try container.mainContext.fetch(descriptor)
    #expect(words.count == 1)
    #expect(words[0].text == "hello")
}

@Test @MainActor func saveWordDeduplicate() throws {
    let container = try ModelContainer(for: Word.self, configurations: .init(isStoredInMemoryOnly: true))
    let store = VocabularyStore(modelContext: container.mainContext)
    try store.saveWord("hello", contextSentence: nil, courseId: nil)
    try store.saveWord("hello", contextSentence: "Updated context", courseId: nil)
    let descriptor = FetchDescriptor<Word>()
    let words = try container.mainContext.fetch(descriptor)
    #expect(words.count == 1)
    #expect(words[0].contextSentence == "Updated context")
}

@Test @MainActor func isWordSaved() throws {
    let container = try ModelContainer(for: Word.self, configurations: .init(isStoredInMemoryOnly: true))
    let store = VocabularyStore(modelContext: container.mainContext)
    #expect(try store.isWordSaved("hello") == false)
    try store.saveWord("hello", contextSentence: nil, courseId: nil)
    #expect(try store.isWordSaved("hello") == true)
}

@Test @MainActor func deleteWord() throws {
    let container = try ModelContainer(for: Word.self, configurations: .init(isStoredInMemoryOnly: true))
    let store = VocabularyStore(modelContext: container.mainContext)
    try store.saveWord("hello", contextSentence: "Hello world", courseId: nil)
    let descriptor = FetchDescriptor<Word>()
    var words = try container.mainContext.fetch(descriptor)
    #expect(words.count == 1)
    let word = words[0]
    store.deleteWord(word)
    words = try container.mainContext.fetch(descriptor)
    #expect(words.count == 0)
}
