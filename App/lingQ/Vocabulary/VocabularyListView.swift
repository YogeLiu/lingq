import SwiftUI
import SwiftData
import SharedModels
import VocabularyKit

struct VocabularyListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]
    @State private var filterLevel: WordLevel?
    @State private var searchText = ""

    private var filteredWords: [Word] {
        words.filter { word in
            let matchesLevel = filterLevel == nil || word.level == filterLevel
            let matchesSearch = searchText.isEmpty || word.text.localizedCaseInsensitiveContains(searchText)
            return matchesLevel && matchesSearch
        }
    }

    private var courseLookup: [UUID: String] {
        Dictionary(uniqueKeysWithValues: courses.map { ($0.id, $0.title) })
    }

    private var groupedByDate: [VocabularySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredWords) { word in
            calendar.startOfDay(for: word.createdAt)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { date, words in
                VocabularySection(
                    id: date.ISO8601Format(),
                    title: date.formatted(date: .abbreviated, time: .omitted),
                    words: words
                )
            }
    }

    var body: some View {
        List {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "全部", isSelected: filterLevel == nil) {
                        filterLevel = nil
                    }
                    ForEach([WordLevel.level1, .level2, .level3, .known], id: \.rawValue) { level in
                        FilterChip(
                            title: level == .known ? "✓" : "\(level.rawValue)",
                            isSelected: filterLevel == level
                        ) {
                            filterLevel = level
                        }
                    }
                }
                .padding(.horizontal)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            ForEach(groupedByDate) { section in
                Section {
                    ForEach(section.words) { word in
                        WordCardView(word: word, courseTitle: word.courseId.flatMap { courseLookup[$0] })
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { offsets in
                        deleteWords(in: section, at: offsets)
                    }
                } header: {
                    Text(section.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "搜索生词")
        .navigationTitle("Vocabulary")
    }

    private func deleteWords(in section: VocabularySection, at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(section.words[index])
        }
    }
}

struct VocabularySection: Identifiable {
    let id: String
    let title: String
    let words: [Word]
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(title)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
            .onTapGesture(perform: onTap)
    }
}
