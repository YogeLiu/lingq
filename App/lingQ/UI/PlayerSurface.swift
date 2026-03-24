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
        VStack(spacing: 22) {
            VStack(spacing: 14) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(playerTrackTint)

                        Capsule()
                            .fill(playerAccentColor)
                            .frame(width: max(proxy.size.width * progressFraction, 18))
                    }
                    .frame(height: 14)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                seek(to: gesture.location.x, in: proxy.size.width)
                            }
                    )
                }
                .frame(height: 14)

                HStack {
                    Text(formatTime(progressValue))
                    Spacer()
                    Text(formatTime(progressTotal))
                }
                .font(.system(size: 18, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(playerControlTint)
            }

            HStack(spacing: 18) {
                secondaryControlButton(systemImage: "gobackward.10", action: onSkipBackward)
                secondaryControlButton(systemImage: "backward.end.fill", action: onPrevious)

                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 98, height: 98)
                        .background(playerAccentColor, in: Circle())
                        .shadow(color: playerAccentColor.opacity(0.16), radius: 16, y: 10)
                }
                .buttonStyle(.plain)

                secondaryControlButton(systemImage: "forward.end.fill", action: onNext)
                secondaryControlButton(systemImage: "goforward.10", action: onSkipForward)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                if let onSubtitleTap {
                    utilityButton(systemImage: "captions.bubble.fill", isActive: false, action: onSubtitleTap)
                } else {
                    Color.clear
                        .frame(width: 42, height: 42)
                }

                HStack(spacing: 8) {
                    ForEach(availableSpeeds, id: \.self) { rate in
                        Button {
                            player.playbackRate = rate
                        } label: {
                            Text(speedValueLabel(for: rate))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(player.playbackRate == rate ? .white : AppTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(player.playbackRate == rate ? playerAccentColor : AppTheme.surface, in: Capsule())
                                .overlay {
                                    if player.playbackRate != rate {
                                        Capsule()
                                            .stroke(AppTheme.borderSubtle.opacity(0.68), lineWidth: 1)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(5)
                .background(playerTrackTint, in: Capsule())

                utilityButton(systemImage: "repeat", isActive: isLoopActive, action: onToggleLoop)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 18)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .strokeBorder(AppTheme.borderSubtle.opacity(0.72), lineWidth: 1)
        }
        .shadow(color: AppTheme.shadow, radius: 18, y: 10)
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
        AppTheme.textSecondary
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
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(playerControlTint)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }

    private func utilityButton(systemImage: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isActive ? .white : playerAccentColor)
                .frame(width: 42, height: 42)
                .background(isActive ? playerAccentColor : playerTrackTint, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func speedValueLabel(for rate: Float) -> String {
        if rate == Float(Int(rate)) {
            return "\(Int(rate))"
        }
        return String(format: "%.2g", Double(rate))
    }

    private func seek(to xOffset: CGFloat, in width: CGFloat) {
        guard width > 0, progressTotal > 0 else { return }
        let percent = min(max(xOffset / width, 0), 1)
        player.seek(to: progressTotal * percent)
    }
}
