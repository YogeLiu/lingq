import SwiftUI
import SharedModels
import UIKit

struct ContinueListeningCard: View {
    let course: Course?

    var body: some View {
        if let course {
            NavigationLink(value: course) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("继续收听")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.brandAccent)
                        .tracking(1)

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 18) {
                            coverArtwork(for: course)
                                .frame(width: 124, height: 124)
                            detailStack(for: course)
                        }

                        VStack(alignment: .leading, spacing: 18) {
                            coverArtwork(for: course)
                                .frame(maxWidth: .infinity)
                                .frame(height: 216)
                            detailStack(for: course)
                        }
                    }

                    Rectangle()
                        .fill(AppTheme.divider)
                        .frame(height: 1)

                    HStack(spacing: 12) {
                        Label(course.playbackPosition > 0 ? "继续播放" : "开始播放", systemImage: course.playbackPosition > 0 ? "play.fill" : "headphones")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(AppTheme.brandAccent, in: Capsule())
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .stroke(AppTheme.borderSubtle.opacity(0.72), lineWidth: 1)
                }
                .shadow(color: AppTheme.shadow, radius: 16, y: 10)
            }
            .buttonStyle(.plain)
        } else {
            EmptyStateCard(
                icon: "waveform.badge.plus",
                title: "还没有开始听",
                message: "导入 ZIP 课程后，你会在这里看到继续播放入口。"
            )
        }
    }

    private func detailStack(for course: Course) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(course.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(3)

                Text(playbackSummary(for: course))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                infoChip(
                    title: course.playbackPosition > 0 ? formatTime(course.playbackPosition) : "未开始",
                    systemImage: course.playbackPosition > 0 ? "waveform" : "sparkles"
                )

                if let lastPlayedAt = course.lastPlayedAt {
                    relativeChip(date: lastPlayedAt)
                } else {
                    infoChip(title: "新导入", systemImage: "tray.full")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func coverArtwork(for course: Course) -> some View {
        if let coverURL = course.resolvedCoverImageURL,
           let coverImage = UIImage(contentsOfFile: coverURL.path) {
            Image(uiImage: coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.nestedCornerRadius, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: AppTheme.nestedCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.brandAccentMuted, AppTheme.surfaceMuted],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Image(systemName: "headphones")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(AppTheme.brandAccent)
                }
        }
    }

    private func infoChip(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
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
        .padding(.vertical, 8)
        .background(AppTheme.surfaceMuted, in: Capsule())
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
