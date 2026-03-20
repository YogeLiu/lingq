import SwiftUI
import SRSKit
import VocabularyKit

struct FlashcardView: View {
    let word: Word
    @State private var isFlipped = false

    var onGrade: (SRSKit.ReviewGrade) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 24) {
            // 卡片
            ZStack {
                if !isFlipped {
                    // 正面
                    VStack(spacing: 12) {
                        Text(word.text)
                            .font(.largeTitle.bold())
                        if let phonetic = word.phonetic {
                            Text(phonetic)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        Text("点击翻转查看释义")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    // 背面
                    VStack(alignment: .leading, spacing: 12) {
                        Text(word.definition ?? "暂无释义")
                            .font(.title3)
                        if let ctx = word.contextSentence {
                            Divider()
                            Text(ctx)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .onTapGesture { isFlipped.toggle() }
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(.easeInOut(duration: 0.4), value: isFlipped)

            // 评分按钮（仅翻转后显示）
            if isFlipped {
                HStack(spacing: 12) {
                    GradeButton(title: "重来", color: .red) { onGrade(.again) }
                    GradeButton(title: "困难", color: .orange) { onGrade(.hard) }
                    GradeButton(title: "良好", color: .green) { onGrade(.good) }
                    GradeButton(title: "简单", color: .blue) { onGrade(.easy) }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
    }
}

struct GradeButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(color)
        }
    }
}
