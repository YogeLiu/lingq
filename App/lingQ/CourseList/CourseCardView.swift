import SwiftUI
import SharedModels
import UIKit

struct CourseCardView: View {
    let course: Course

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            coverArtwork
                .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(course.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)

                    Text(course.lastPlayedAt == nil ? "准备开始第一遍输入" : "继续你的听力会话")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 8) {
                    statusChip(title: playbackStatus, systemImage: playbackIcon)

                    if let lastPlayed = course.lastPlayedAt {
                        relativeChip(date: lastPlayed)
                    } else {
                        statusChip(title: "新加入", systemImage: "tray.full")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textTertiary)
                .padding(.top, 4)
        }
        .padding(18)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.borderSubtle.opacity(0.68), lineWidth: 1)
        }
        .shadow(color: AppTheme.shadow, radius: 12, y: 8)
    }

    @ViewBuilder
    private var coverArtwork: some View {
        if let coverURL = course.resolvedCoverImageURL,
           let coverImage = UIImage(contentsOfFile: coverURL.path) {
            Image(uiImage: coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.compactCornerRadius, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: AppTheme.compactCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.brandAccentMuted, AppTheme.surfaceMuted],
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

    private func statusChip(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppTheme.surfaceMuted, in: Capsule())
    }

    private func relativeChip(date: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
            Text(date, style: .relative)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(AppTheme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(AppTheme.surfaceMuted, in: Capsule())
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
