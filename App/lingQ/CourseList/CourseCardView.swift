import SwiftUI
import SharedModels

struct CourseCardView: View {
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.title)
                .font(.headline.italic())

            HStack(spacing: 6) {
                if let lastPlayed = course.lastPlayedAt {
                    Text(lastPlayed, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if course.playbackPosition > 0 {
                ProgressView(value: course.playbackPosition, total: 1.0)
                    .tint(.accentColor)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
