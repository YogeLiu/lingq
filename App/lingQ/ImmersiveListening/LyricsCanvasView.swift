import SwiftUI
import SharedModels

struct LyricsCanvasView: View {
    let cues: [SubtitleCue]
    let currentIndex: Int?
    let onCueTap: (SubtitleCue) -> Void
    let savedWords: Set<String>
    let onWordLongPress: (String, String) -> Void

    @State private var lastAutoScrolledIndex: Int?

    private let followScrollStep = 4

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 6) {
                    Spacer(minLength: 120)

                    ForEach(Array(cues.enumerated()), id: \.element.id) { index, cue in
                        TappableSubtitleLineView(
                            text: cue.text,
                            state: lyricState(for: index),
                            savedWords: savedWords,
                            onLineTap: { onCueTap(cue) },
                            onWordLongPress: onWordLongPress
                        )
                        .id(cue.id)
                    }

                    Spacer(minLength: 300)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.immediately)
            .onAppear {
                scrollToCurrentCueIfNeeded(using: proxy, force: true)
            }
            .onChange(of: currentIndex) { _, newIndex in
                scrollToCurrentCueIfNeeded(using: proxy, force: false)
            }
        }
    }

    private func lyricState(for index: Int) -> LyricLineView.LyricState {
        guard let current = currentIndex else { return .future(distance: 0) }
        if index == current { return .current }
        if index < current { return .past(distance: current - index) }
        return .future(distance: index - current)
    }

    private func scrollToCurrentCueIfNeeded(using proxy: ScrollViewProxy, force: Bool) {
        guard let currentIndex,
              cues.indices.contains(currentIndex) else { return }

        if !force,
           let lastAutoScrolledIndex,
           currentIndex > lastAutoScrolledIndex,
           currentIndex - lastAutoScrolledIndex < followScrollStep {
            return
        }

        let targetIndex = min(currentIndex + 2, cues.count - 1)
        proxy.scrollTo(cues[targetIndex].id, anchor: .center)
        lastAutoScrolledIndex = currentIndex
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
