import SwiftUI
import SharedModels
import NaturalLanguage

struct TappableSubtitleLineView: View {
    let text: String
    let state: LyricLineView.LyricState
    let savedWords: Set<String>
    let onLineTap: () -> Void
    let onWordLongPress: (String, String) -> Void
    private let tokens: [SubtitleToken]

    init(
        text: String,
        state: LyricLineView.LyricState,
        savedWords: Set<String>,
        onLineTap: @escaping () -> Void,
        onWordLongPress: @escaping (String, String) -> Void
    ) {
        self.text = text
        self.state = state
        self.savedWords = savedWords
        self.onLineTap = onLineTap
        self.onWordLongPress = onWordLongPress
        self.tokens = SubtitleToken.tokenize(text)
    }

    var body: some View {
        FlowLayout(spacing: 4, lineSpacing: 6) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                if token.isWord {
                    Text(token.text)
                        .font(font)
                        .padding(.horizontal, tokenPadding)
                        .padding(.vertical, 3)
                        .background(tokenBackground(for: token.normalizedWord), in: Capsule())
                        .foregroundStyle(foregroundColor)
                        .contentShape(Rectangle())
                        .onLongPressGesture(minimumDuration: 0.35) {
                            onWordLongPress(token.text, text)
                        }
                } else {
                    Text(token.text)
                        .font(font)
                        .foregroundStyle(foregroundColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .opacity(state.opacity)
        .onTapGesture(perform: onLineTap)
    }

    private var font: Font {
        .system(size: 21, weight: state.isCurrent ? .bold : .medium, design: .rounded)
    }

    private var foregroundColor: Color {
        switch state {
        case .current:
            AppTheme.brandAccent
        case .future:
            AppTheme.textPrimary
        case .past:
            AppTheme.textTertiary
        }
    }

    private var tokenPadding: CGFloat {
        4
    }

    private func tokenBackground(for word: String?) -> Color {
        if let word, savedWords.contains(word) {
            return AppTheme.brandAccent.opacity(state.isCurrent ? 0.18 : 0.10)
        }
        if state.isCurrent {
            return AppTheme.brandAccent.opacity(0.08)
        }
        return .clear
    }
}

private struct SubtitleToken {
    let text: String
    let isWord: Bool

    var normalizedWord: String? {
        guard isWord else { return nil }
        let cleaned = text
            .trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.symbols).union(.whitespacesAndNewlines))
            .lowercased()

        guard cleaned.rangeOfCharacter(from: .letters) != nil else {
            return nil
        }

        return cleaned
    }

    static func tokenize(_ source: String) -> [SubtitleToken] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = source

        var tokens: [SubtitleToken] = []
        var currentIndex = source.startIndex

        tokenizer.enumerateTokens(in: source.startIndex..<source.endIndex) { range, _ in
            if currentIndex < range.lowerBound {
                tokens.append(SubtitleToken(text: String(source[currentIndex..<range.lowerBound]), isWord: false))
            }

            tokens.append(SubtitleToken(text: String(source[range]), isWord: true))
            currentIndex = range.upperBound
            return true
        }

        if currentIndex < source.endIndex {
            tokens.append(SubtitleToken(text: String(source[currentIndex..<source.endIndex]), isWord: false))
        }

        return tokens.filter { !$0.text.isEmpty }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    init(spacing: CGFloat = 4, lineSpacing: CGFloat = 6) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX > 0 && currentX + size.width > maxWidth {
                currentX = 0
                currentY += lineHeight + lineSpacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxLineWidth = max(maxLineWidth, currentX)
        }

        return (
            size: CGSize(width: min(maxWidth, maxLineWidth), height: currentY + lineHeight),
            positions: positions
        )
    }
}
