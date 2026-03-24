import SwiftUI
import AudioPlayerKit

struct PlayerSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding(18)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.borderSubtle.opacity(0.72), lineWidth: 1)
        }
    }
}

struct PlaybackControlCard: View {
    @Bindable var player: AudioPlayer

    let availableSpeeds: [Float]
    let isLoopActive: Bool
    let onSubtitleTap: (() -> Void)?
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSkipBackward: () -> Void
    let onSkipForward: () -> Void
    let onToggleLoop: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Progress
            VStack(spacing: 6) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(playerTrackTint)

                        Capsule()
                            .fill(playerAccentColor)
                            .frame(width: max(proxy.size.width * progressFraction, 4))
                    }
                    .frame(height: 3)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                seek(to: gesture.location.x, in: proxy.size.width)
                            }
                    )
                }
                .frame(height: 28)

                HStack {
                    Text(formatTime(progressValue))
                    Spacer()
                    Text(formatTime(progressTotal))
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced).monospacedDigit())
                .foregroundStyle(playerControlTint)
            }

            // Transport controls
            HStack(spacing: 0) {
                secondaryControlButton(systemImage: "gobackward.10", action: onSkipBackward)
                Spacer()
                secondaryControlButton(systemImage: "backward.end.fill", action: onPrevious)
                Spacer()

                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(playerAccentColor, in: Circle())
                }
                .buttonStyle(.plain)

                Spacer()
                secondaryControlButton(systemImage: "forward.end.fill", action: onNext)
                Spacer()
                secondaryControlButton(systemImage: "goforward.10", action: onSkipForward)
            }

            // Utility row
            HStack(spacing: 8) {
                if let onSubtitleTap {
                    utilityButton(systemImage: "captions.bubble.fill", isActive: false, action: onSubtitleTap)
                } else {
                    Color.clear.frame(width: 34, height: 34)
                }

                Spacer()

                HStack(spacing: 4) {
                    ForEach(availableSpeeds, id: \.self) { rate in
                        Button {
                            player.playbackRate = rate
                        } label: {
                            Text(speedValueLabel(for: rate))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(player.playbackRate == rate ? .white : AppTheme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(player.playbackRate == rate ? playerAccentColor : Color.clear, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(playerTrackTint, in: Capsule())

                Spacer()

                utilityButton(systemImage: "repeat", isActive: isLoopActive, action: onToggleLoop)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppTheme.borderSubtle.opacity(0.4), lineWidth: 0.5)
        }
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

    private var progressFraction: CGFloat {
        CGFloat(progressValue / progressTotal)
    }

    private var playerAccentColor: Color {
        AppTheme.brandAccent
    }

    private var playerTrackTint: Color {
        AppTheme.surfaceMuted
    }

    private var playerControlTint: Color {
        AppTheme.textTertiary
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let safeTime = time.isFinite ? max(time, 0) : 0
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func secondaryControlButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }

    private func utilityButton(systemImage: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isActive ? .white : AppTheme.textSecondary)
                .frame(width: 34, height: 34)
                .background(isActive ? playerAccentColor : playerTrackTint, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func speedValueLabel(for rate: Float) -> String {
        if rate == Float(Int(rate)) {
            return "\(Int(rate))x"
        }
        return String(format: "%.2gx", Double(rate))
    }

    private func seek(to xOffset: CGFloat, in width: CGFloat) {
        guard width > 0, progressTotal > 0 else { return }
        let percent = min(max(xOffset / width, 0), 1)
        player.seek(to: progressTotal * percent)
    }
}
