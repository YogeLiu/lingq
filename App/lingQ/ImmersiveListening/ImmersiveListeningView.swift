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
    @State private var controlsVisible = true
    @State private var hideControlsTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background
                .ignoresSafeArea()

            LyricsCanvasView(
                cues: cues,
                currentIndex: currentIndex,
                mode: mode,
                onCueTap: { cue in
                    player.seek(to: cue.startTime)
                    showControlsTemporarily()
                }
            )
            .padding(.bottom, controlsVisible ? 200 : 60)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    controlsVisible.toggle()
                }
                if controlsVisible {
                    scheduleHideControls()
                }
            }

            if controlsVisible {
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
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .topLeading) {
            if controlsVisible {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .padding(12)
                        .background(.thinMaterial, in: Circle())
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.leading, 20)
                .padding(.top, 12)
                .transition(.opacity)
            }
        }
        .overlay(alignment: .top) {
            if controlsVisible {
                VStack(spacing: 2) {
                    Text(mode.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(mode.description)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: controlsVisible)
        .onChange(of: player.currentTime) { _, time in
            currentIndex = searcher.index(at: time)
        }
        .onAppear {
            currentIndex = searcher.index(at: player.currentTime)
            scheduleHideControls()
        }
    }

    private func showControlsTemporarily() {
        withAnimation(.easeInOut(duration: 0.3)) {
            controlsVisible = true
        }
        scheduleHideControls()
    }

    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    controlsVisible = false
                }
            }
        }
    }
}
