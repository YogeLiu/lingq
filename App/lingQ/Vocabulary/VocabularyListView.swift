import SwiftUI
import SwiftData
import SharedModels
import VocabularyKit

struct VocabularyListView: View {
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

    var body: some View {
        List {
            // 筛选
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

            // 单词列表
            ForEach(filteredWords) { word in
                WordCardView(word: word)
            }
            .onDelete { indexSet in
                // 删除逻辑
            }
        }
        .searchable(text: $searchText, prompt: "搜索生词")
        .navigationTitle("生词本")
    }
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
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
            .onTapGesture(perform: onTap)
    }
}
