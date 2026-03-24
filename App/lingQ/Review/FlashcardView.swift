import SwiftUI
import SRSKit
import VocabularyKit

struct FlashcardView: View {
    let word: Word
    @State private var isFlipped = false

    var onGrade: (SRSKit.ReviewGrade) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                if !isFlipped {
                    VStack(spacing: 12) {
                        Text(word.text)
                            .font(.title.bold())
                        if let phonetic = word.phonetic {
                            Text(phonetic)
                                .font(.title3)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                        Text("点击翻转查看释义")
                            .font(.caption)
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(word.definition ?? "暂无释义")
                            .font(.title3)
                        if let ctx = word.contextSentence {
                            Divider()
                            Text(ctx)
                                .font(.body)
                                .foregroundStyle(Color(.secondaryLabel))
                                .italic()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 280)
            .padding(24)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .onTapGesture { isFlipped.toggle() }
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(.easeInOut(duration: 0.4), value: isFlipped)

            if isFlipped {
                HStack(spacing: 12) {
                    gradeButton(title: "忘了", color: .red) { onGrade(.again) }
                    gradeButton(title: "模糊", color: .orange) { onGrade(.hard) }
                    gradeButton(title: "记得", color: .green) { onGrade(.good) }
                    gradeButton(title: "简单", color: .blue) { onGrade(.easy) }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
    }

    private func gradeButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(color)
    }
}
