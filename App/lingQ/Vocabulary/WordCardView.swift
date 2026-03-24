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
