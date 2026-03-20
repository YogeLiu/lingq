import SwiftUI
import SharedModels
import NaturalLanguage

struct SentenceView: View {
    let cue: SubtitleCue
    let isCurrentlyPlaying: Bool
    let wordLevels: [String: WordLevel]
    let onWordTap: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(tokenize(cue.text), id: \.self) { word in
                TappableWordView(
                    word: word,
                    level: wordLevels[word.lowercased()],
                    onTap: { onWordTap(word) }
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(isCurrentlyPlaying ? Color.accentColor.opacity(0.1) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func tokenize(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            tokens.append(String(text[range]))
            return true
        }
        return tokens
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)  // subtract trailing spacing from last item
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
