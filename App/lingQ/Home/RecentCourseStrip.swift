import SwiftUI
import SharedModels

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
                            VStack(alignment: .leading, spacing: 10) {
                                Text(course.title)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(2)

                                Spacer(minLength: 0)

                                VStack(alignment: .leading, spacing: 4) {
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
                            .frame(width: 200, height: 140, alignment: .leading)
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

    private func formatTime(_ time: TimeInterval) -> String {
        let safeTime = time.isFinite ? max(time, 0) : 0
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
