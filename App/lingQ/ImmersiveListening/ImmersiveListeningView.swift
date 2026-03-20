import SwiftUI
import SharedModels
import SubtitleKit
import AudioPlayerKit

struct ImmersiveListeningView: View {
    let course: Course
    let cues: [SubtitleCue]
    let searcher: CueSearcher
    @Bindable var player: AudioPlayer

    @Environment(\.dismiss) private var dismiss
    @State private var mode: ImmersiveMode = .focused
    @State private var currentIndex: Int?

    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()

            // 歌词画布
            LyricsCanvasView(
                cues: cues,
                currentIndex: currentIndex,
                onCueTap: { cue in
                    player.seek(to: cue.startTime)
                }
            )
            .padding(.bottom, 200)

            // 播放器
            ImmersivePlayerView(
                player: player,
                mode: $mode,
                onPrevious: {
                    if let prev = searcher.previousCue(before: player.currentTime) {
                        player.seek(to: prev.startTime)
                    }
                },
                onNext: {
                    if let next = searcher.nextCue(after: player.currentTime) {
                        player.seek(to: next.startTime)
                    }
                }
            )
        }
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .padding()
            }
        }
        .overlay(alignment: .top) {
            // FLOW STATE 指示器
            Text("FLOW STATE")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .onChange(of: player.currentTime) { _, time in
            currentIndex = searcher.index(at: time)
        }
    }
}
