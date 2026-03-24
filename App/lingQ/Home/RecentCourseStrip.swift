import SwiftUI
import SharedModels
import UIKit

struct RecentCourseStrip: View {
    let courses: [Course]

    var body: some View {
        if courses.isEmpty {
            EmptyStateCard(
                icon: "books.vertical",
                title: "还没有课程",
                message: "导入后会在这里看到最近的听力内容。"
            )
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(courses.prefix(8)) { course in
                        NavigationLink(value: course) {
                            VStack(alignment: .leading, spacing: 14) {
                                coverArtwork(for: course)
                                    .frame(height: 136)

                                VStack(alignment: .leading, spacing: 10) {
                                    Text(course.title)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .lineLimit(2)

                                    Text(course.playbackPosition > 0 ? "从 \(formatTime(course.playbackPosition)) 继续这门课程" : "还没开始，适合现在打开做第一遍输入。")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .lineLimit(2)

                                    HStack(spacing: 8) {
                                        statusChip(
                                            title: course.playbackPosition > 0 ? formatTime(course.playbackPosition) : "未开始",
                                            systemImage: course.playbackPosition > 0 ? "play.circle.fill" : "sparkles"
                                        )

                                        if let lastPlayedAt = course.lastPlayedAt {
                                            relativeChip(date: lastPlayedAt)
                                        } else {
                                            statusChip(title: "新加入", systemImage: "tray.full")
                                        }
                                    }
                                }
                            }
                            .frame(width: 244, alignment: .leading)
                            .padding(16)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.nestedCornerRadius, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: AppTheme.nestedCornerRadius, style: .continuous)
                                    .stroke(AppTheme.borderSubtle.opacity(0.72), lineWidth: 1)
                            }
                            .shadow(color: AppTheme.shadow, radius: 12, y: 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    @ViewBuilder
    private func coverArtwork(for course: Course) -> some View {
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
                        .font(.title3.weight(.semibold))
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
}
