import SwiftUI
import SharedModels

struct ContinueListeningCard: View {
    let course: Course?

    var body: some View {
        if let course {
            NavigationLink(value: course) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("继续收听")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.brandAccent)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(course.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(2)

                        Text(playbackSummary(for: course))
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    if course.playbackPosition > 0 {
                        ProgressView(value: min(course.playbackPosition, 1), total: 1)
                            .tint(AppTheme.brandAccent)
                    }

                    HStack(spacing: 12) {
                        Label("继续播放", systemImage: "play.fill")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(AppTheme.brandAccent, in: Capsule())
                            .foregroundStyle(.white)

                        if course.playbackPosition > 0 {
                            Label(formatTime(course.playbackPosition), systemImage: "waveform")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        } else {
            EmptyStateCard(
                icon: "waveform.badge.plus",
                title: "还没有开始听",
                message: "导入音频和字幕后，你会在这里看到继续播放入口。"
            )
        }
    }

    private func playbackSummary(for course: Course) -> String {
        if let lastPlayedAt = course.lastPlayedAt {
            return "上次播放于 \(relativeFormatter.localizedString(for: lastPlayedAt, relativeTo: Date()))"
        }
        return "刚导入，准备开始第一遍输入"
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let safeTime = time.isFinite ? max(time, 0) : 0
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var relativeFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }
}
