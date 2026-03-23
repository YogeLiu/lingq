import SwiftUI
import AudioPlayerKit

struct ImmersivePlayerView: View {
    @Bindable var player: AudioPlayer
    @Binding var mode: ImmersiveMode
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        PlayerSurface {
            VStack(spacing: 6) {
                ProgressView(value: progressValue, total: progressTotal)
                    .tint(AppTheme.brandAccent)
                HStack {
                    Text(formatTime(progressValue))
                    Spacer()
                    Text(formatTime(progressTotal))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: 20) {
                Button { player.skipBackward(10) } label: {
                    Image(systemName: "gobackward.10")
                }

                Button(action: onPrevious) {
                    Image(systemName: "backward.end.fill")
                }

                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                }
                .frame(width: 56, height: 56)
                .background(AppTheme.brandAccent, in: Circle())
                .foregroundStyle(.white)

                Button(action: onNext) {
                    Image(systemName: "forward.end.fill")
                }

                Button { player.skipForward(10) } label: {
                    Image(systemName: "goforward.10")
                }
            }
            .font(.title3)
            .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 12) {
                ForEach(ImmersiveMode.allCases, id: \.self) { m in
                    Button {
                        mode = m
                    } label: {
                        Text(m.title)
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(m == mode ? AppTheme.brandAccent.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(m == mode ? AppTheme.brandAccent.opacity(0.3) : Color.clear)
                            }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(m == mode ? AppTheme.brandAccent : AppTheme.textSecondary)
                }
            }
        }
        .padding()
    }

    private var progressTotal: TimeInterval {
        let duration = player.duration
        guard duration.isFinite, duration > 0 else { return 1 }
        return duration
    }

    private var progressValue: TimeInterval {
        let time = player.currentTime
        guard time.isFinite else { return 0 }
        return min(max(time, 0), progressTotal)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let safeTime = time.isFinite ? max(time, 0) : 0
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
