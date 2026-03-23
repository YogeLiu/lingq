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
                HStack(spacing: 12) {
                    ForEach(courses.prefix(8)) { course in
                        NavigationLink(value: course) {
                            VStack(alignment: .leading, spacing: 12) {
                                coverArtwork(for: course)
                                    .frame(height: 110)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(course.title)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .lineLimit(2)

                                    if course.playbackPosition > 0 {
                                        Label("停在 \(formatTime(course.playbackPosition))", systemImage: "play.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    } else {
                                        Label("尚未开始", systemImage: "headphones")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }

                                    if let lastPlayedAt = course.lastPlayedAt {
                                        Text(lastPlayedAt, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.textTertiary)
                                    } else {
                                        Text(course.createdAt, style: .date)
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.textTertiary)
                                    }
                                }
                            }
                            .frame(width: 214, alignment: .leading)
                            .padding(16)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
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
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.brandAccent.opacity(0.18), AppTheme.surfaceMuted, .white],
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

    private func formatTime(_ time: TimeInterval) -> String {
        let safeTime = time.isFinite ? max(time, 0) : 0
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
