import SwiftUI
import AudioPlayerKit

struct MiniPlayerView: View {
    @Bindable var player: AudioPlayer
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            ProgressView(value: player.currentTime, total: max(player.duration, 1))
                .tint(.accentColor)

            HStack(spacing: 24) {
                Text(formatTime(player.currentTime))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: onPrevious) {
                    Image(systemName: "backward.end.fill")
                }

                Button(action: { player.toggle() }) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .frame(width: 48, height: 48)
                .background(.accent, in: Circle())
                .foregroundStyle(.white)

                Button(action: onNext) {
                    Image(systemName: "forward.end.fill")
                }

                Spacer()

                Text(formatTime(player.duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
