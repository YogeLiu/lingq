import SwiftUI

struct TappableSubtitleLineView: View {
    let text: String
    let state: LyricLineView.LyricState
    let wordProgress: Double
    let savedWords: Set<String>
    let words: [WordSpan]
    let onLineTap: () -> Void
    let onWordLongPress: (String, String) -> Void

    var body: some View {
        FlowLayout(spacing: 0, lineSpacing: 2) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Text(word.display)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(wordColor(at: index))
                    .underline(isSaved(word), color: .white.opacity(0.25))
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 0.35) {
                        onWordLongPress(word.raw, text)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .scaleEffect(state.isCurrent ? 1.0 : 0.95, anchor: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: onLineTap)
    }

    private func wordColor(at index: Int) -> Color {
        switch state {
        case .current:
            let total = max(words.count, 1)
            let threshold = Double(index) / Double(total)
            return threshold < wordProgress ? .white : .white.opacity(0.3)
        case .past(let d):
            return .white.opacity(max(0.08, 0.35 - Double(d) * 0.06))
        case .future(let d):
            return .white.opacity(max(0.08, 0.45 - Double(d) * 0.06))
        }
    }

    private func isSaved(_ word: WordSpan) -> Bool {
        guard let normalized = word.normalized else { return false }
        return savedWords.contains(normalized)
    }
}

// MARK: - Word Span

struct WordSpan {
    let display: String
    let raw: String
    let normalized: String?

    static func split(_ source: String) -> [WordSpan] {
        let components = source.split(separator: /\s+/)
        return components.enumerated().map { index, component in
            let raw = String(component)
            let display = index < components.count - 1 ? raw + " " : raw
            let cleaned = raw
                .trimmingCharacters(in: .punctuationCharacters.union(.symbols))
                .lowercased()
            return WordSpan(
                display: display,
                raw: raw,
                normalized: cleaned.isEmpty ? nil : cleaned
            )
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

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
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxLineWidth = max(maxLineWidth, x)
        }

        return (
            size: CGSize(width: min(maxWidth, maxLineWidth), height: y + lineHeight),
            positions: positions
        )
    }
}
