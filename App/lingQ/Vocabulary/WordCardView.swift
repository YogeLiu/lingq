import SwiftUI
import SharedModels
import VocabularyKit

struct WordCardView: View {
    let word: Word

    var body: some View {
        HStack {
            Circle()
                .fill(colorForLevel(word.level))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(word.text)
                    .font(.headline)
                if let definition = word.definition {
                    Text(definition)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if word.level != .known {
                Text("\(word.level.rawValue)")
                    .font(.caption.bold())
                    .frame(width: 24, height: 24)
                    .background(colorForLevel(word.level).opacity(0.2), in: Circle())
            } else {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
