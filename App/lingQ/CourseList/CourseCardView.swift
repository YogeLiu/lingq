import SwiftUI
import SharedModels
import UIKit

struct CourseCardView: View {
    let course: Course

    var body: some View {
        HStack(spacing: 12) {
            coverThumbnail
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
    }

    @ViewBuilder
    private var coverThumbnail: some View {
        if let coverURL = course.resolvedCoverImageURL,
           let coverImage = UIImage(contentsOfFile: coverURL.path) {
            Image(uiImage: coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(Color(.systemFill))
                .overlay {
                    Image(systemName: "headphones")
                        .foregroundStyle(Color(.tertiaryLabel))
                }
        }
    }

    private var statusText: String {
        if course.playbackPosition > 0 {
            return "停在 \(formatTime(course.playbackPosition))"
        }
        return "尚未开始"
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let safeTime = time.isFinite ? max(time, 0) : 0
        let minutes = Int(safeTime) / 60
        let seconds = Int(safeTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
