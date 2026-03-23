import SwiftUI
import SharedModels
import UIKit

struct CourseCardView: View {
    let course: Course

    var body: some View {
        HStack(spacing: 16) {
            coverArtwork
                .frame(width: 84, height: 84)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(course.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)

                    Text(course.lastPlayedAt == nil ? "准备开始第一遍输入" : "继续你的听力会话")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
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
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
    }

    @ViewBuilder
    private var coverArtwork: some View {
        if let coverURL = course.resolvedCoverImageURL,
           let coverImage = UIImage(contentsOfFile: coverURL.path) {
            Image(uiImage: coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.brandAccent.opacity(0.22), AppTheme.surfaceMuted, .white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Image(systemName: "headphones")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppTheme.brandAccent)
                }
        }
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
