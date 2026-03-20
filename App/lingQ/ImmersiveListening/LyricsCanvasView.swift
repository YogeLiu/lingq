import SwiftUI
import SharedModels

struct LyricsCanvasView: View {
    let cues: [SubtitleCue]
    let currentIndex: Int?
    let onCueTap: (SubtitleCue) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Spacer(minLength: 200)

                    ForEach(Array(cues.enumerated()), id: \.element.id) { index, cue in
                        LyricLineView(
                            text: cue.text,
                            state: lyricState(for: index),
                            onTap: { onCueTap(cue) }
                        )
                        .id(cue.id)
                    }

                    Spacer(minLength: 200)
                }
                .padding(.horizontal, 32)
            }
            .onChange(of: currentIndex) { _, newIndex in
                if let id = newIndex.flatMap({ cues[safe: $0]?.id }) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    private func lyricState(for index: Int) -> LyricLineView.LyricState {
        guard let current = currentIndex else { return .future(distance: 0) }
        if index == current { return .current }
        if index < current { return .past(distance: current - index) }
        return .future(distance: index - current)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
