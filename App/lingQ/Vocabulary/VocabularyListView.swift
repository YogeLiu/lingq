import SwiftUI
import SwiftData
import VocabularyKit
import SharedModels

struct VocabularyListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]
    @State private var searchText = ""

    private var filteredWords: [Word] {
        words.filter { word in
            searchText.isEmpty || word.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var courseLookup: [UUID: String] {
        Dictionary(uniqueKeysWithValues: courses.map { ($0.id, $0.title) })
    }

    var body: some View {
        Group {
            if filteredWords.isEmpty {
                ContentUnavailableView {
                    Label(searchText.isEmpty ? "还没有保存的单词" : "没有匹配结果", systemImage: "character.book.closed")
                } description: {
                    Text(searchText.isEmpty ? "在字幕里点词后，这里会收纳你保存的词。" : "换个关键词再试。")
                }
            } else {
                List {
                    ForEach(filteredWords) { word in
                        WordCardView(word: word, courseTitle: word.courseId.flatMap { courseLookup[$0] })
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(word)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .searchable(text: $searchText, prompt: "搜索生词")
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("词汇")
    }
}
