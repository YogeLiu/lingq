import SwiftUI
import SharedModels

struct LyricsCanvasView: View {
    let cues: [SubtitleCue]
    let currentIndex: Int?
    let currentTime: TimeInterval
    let onCueTap: (SubtitleCue) -> Void
    let onBackgroundTap: () -> Void
    let savedWords: Set<String>
    let onWordLongPress: (String, String) -> Void

    @State private var wordsCache: [[WordSpan]] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 4) {
                            Spacer(minLength: UIScreen.main.bounds.height * 0.4)
                                .frame(maxWidth: .infinity)

                            ForEach(Array(cues.enumerated()), id: \.element.id) { index, cue in
                                let words = wordsCache.indices.contains(index) ? wordsCache[index] : []
                                TappableSubtitleLineView(
                                    text: cue.text,
                                    state: lyricState(for: index),
                                    wordProgress: wordProgress(for: index),
                                    savedWords: savedWords,
                                    words: words,
                                    onLineTap: { onCueTap(cue) },
                                    onWordLongPress: onWordLongPress
                                )
                                .id(cue.id)
                            }

                            Spacer(minLength: UIScreen.main.bounds.height * 0.5)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 24)
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .onAppear {
                        buildWordsCacheIfNeeded()
                        scrollToCurrent(using: proxy, animated: false)
                    }
                    .onChange(of: currentIndex) { _, _ in
                        scrollToCurrent(using: proxy, animated: true)
                    }
                }

                // Right side tap zone — toggle controls, no sentence jump
                HStack(spacing: 0) {
                    Spacer()
                    Color.clear
                        .frame(width: geo.size.width * 0.35)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onBackgroundTap)
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

    private func wordProgress(for index: Int) -> Double {
        guard let currentIndex, index == currentIndex else { return 0 }
        let cue = cues[index]
        let duration = cue.endTime - cue.startTime
        guard duration > 0 else { return 1 }
        return min(max((currentTime - cue.startTime) / duration, 0), 1)
    }

    private func buildWordsCacheIfNeeded() {
        guard wordsCache.isEmpty else { return }
        wordsCache = cues.map { WordSpan.split($0.text) }
    }

    private func scrollToCurrent(using proxy: ScrollViewProxy, animated: Bool) {
        guard let currentIndex, cues.indices.contains(currentIndex) else { return }
        let targetID = cues[currentIndex].id
        if animated {
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo(targetID, anchor: .center)
            }
        } else {
            proxy.scrollTo(targetID, anchor: .center)
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
