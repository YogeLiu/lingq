import SwiftUI
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
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Text(word.isDueForReview ? "待复习" : "已保存")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((word.isDueForReview ? AppTheme.warning : AppTheme.brandAccent).opacity(0.12), in: Capsule())
                    .foregroundStyle(word.isDueForReview ? AppTheme.warning : AppTheme.brandAccent)
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

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(word.createdAt, style: .date)
                }
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)

                if word.reviewCount > 0 {
                    Label("复习 \(word.reviewCount) 次", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .padding(14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
    }
}
