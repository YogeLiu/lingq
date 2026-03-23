import SwiftUI
import SharedModels
import VocabularyKit

struct WordCardView: View {
    let word: Word
    let courseTitle: String?

    init(word: Word, courseTitle: String? = nil) {
        self.word = word
        self.courseTitle = courseTitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(word.text)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Text(levelLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForLevel(word.level).opacity(0.12), in: Capsule())
                    .foregroundStyle(colorForLevel(word.level))
            }

            Text(word.definition ?? "还没有释义")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)

            if let contextSentence = word.contextSentence, !contextSentence.isEmpty {
                Text(contextSentence)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(2)
                    .italic()
            }

            if let courseTitle {
                Label(courseTitle, systemImage: "books.vertical")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 3, y: 2)
    }

    private var levelLabel: String {
        switch word.level {
        case .level1: "初识"
        case .level2: "熟悉"
        case .level3: "掌握"
        case .known: "已会"
        case .new: "新词"
        }
    }

    private func colorForLevel(_ level: WordLevel) -> Color {
        switch level {
        case .new: AppTheme.newColor
        case .level1: AppTheme.level1Color
        case .level2: AppTheme.level2Color
        case .level3: AppTheme.level3Color
        case .known: AppTheme.knownColor
        }
    }
}
