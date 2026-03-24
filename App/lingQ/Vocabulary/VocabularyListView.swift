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

    private var groupedByDate: [(key: String, words: [Word])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredWords) { word -> String in
            if calendar.isDateInToday(word.createdAt) { return "今天" }
            if calendar.isDateInYesterday(word.createdAt) { return "昨天" }
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: word.createdAt)
        }
        // Sort by the first word's date in each group (most recent first)
        return grouped.map { (key: $0.key, words: $0.value) }
            .sorted { ($0.words.first?.createdAt ?? .distantPast) > ($1.words.first?.createdAt ?? .distantPast) }
    }

    private var courseLookup: [UUID: String] {
        Dictionary(uniqueKeysWithValues: courses.map { ($0.id, $0.title) })
    }

    var body: some View {
        Group {
            if filteredWords.isEmpty {
                ContentUnavailableView {
                    Label(searchText.isEmpty ? "还没有保存的词汇" : "没有匹配结果", systemImage: "character.book.closed")
                } description: {
                    Text(searchText.isEmpty ? "在沉浸听力中点击单词即可保存" : "换个关键词再试")
                }
            } else {
                List {
                    ForEach(groupedByDate, id: \.key) { group in
                        Section(group.key) {
                            ForEach(group.words) { word in
                                WordRow(word: word, courseTitle: word.courseId.flatMap { courseLookup[$0] })
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            modelContext.delete(word)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $searchText, prompt: "搜索生词")
        .navigationTitle("词汇")
    }
}

private struct WordRow: View {
    let word: Word
    let courseTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(word.text)
                .font(.body)
                .foregroundStyle(Color(.label))

            Text(word.definition ?? "还没有释义")
                .font(.caption)
                .foregroundStyle(Color(.secondaryLabel))
                .lineLimit(1)

            if let courseTitle {
                Text(courseTitle)
                    .font(.caption2)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .lineLimit(1)
            }
        }
    }
}
