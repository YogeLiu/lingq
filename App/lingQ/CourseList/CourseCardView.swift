import SwiftUI
import SharedModels

struct CourseCardView: View {
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(course.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)

                    Text(course.lastPlayedAt == nil ? "准备开始第一遍输入" : "继续你的听力会话")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "headphones")
                    .font(.headline)
                    .foregroundStyle(AppTheme.brandAccent)
            }

            HStack {
                Label(playbackStatus, systemImage: playbackIcon)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                if let lastPlayed = course.lastPlayedAt {
                    Text(lastPlayed, style: .relative)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                } else {
                    Text(course.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let safeTime = time.isFinite ? max(time, 0) : 0
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var playbackStatus: String {
        course.playbackPosition > 0 ? "停在 \(formatTime(course.playbackPosition))" : "尚未开始"
    }

    private var playbackIcon: String {
        course.playbackPosition > 0 ? "play.circle.fill" : "play.circle"
    }
}
