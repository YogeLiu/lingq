import SwiftUI
import SharedModels
import UIKit

struct ContinueListeningCard: View {
    let course: Course?

    var body: some View {
        if let course {
            NavigationLink(value: course) {
                HStack(spacing: 18) {
                    coverArtwork(for: course)
                        .frame(width: 108, height: 108)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("继续收听")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.brandAccent)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(course.title)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(2)

                            Text(playbackSummary(for: course))
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
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
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
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

    @ViewBuilder
    private func coverArtwork(for course: Course) -> some View {
        if let coverURL = course.resolvedCoverImageURL,
           let coverImage = UIImage(contentsOfFile: coverURL.path) {
            Image(uiImage: coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.brandAccent.opacity(0.22), AppTheme.surfaceMuted, .white],
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
