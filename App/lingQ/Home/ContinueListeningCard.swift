import SwiftUI
import SharedModels
import UIKit

struct ContinueListeningCard: View {
    let course: Course?
    let onImportTap: () -> Void

    var body: some View {
        if let course {
            NavigationLink(value: course) {
                VStack(alignment: .leading, spacing: 0) {
                    coverImage(for: course)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    VStack(alignment: .leading, spacing: 8) {
                        Text(course.title)
                            .font(.headline)
                            .foregroundStyle(Color(.label))
                            .lineLimit(2)

                        Text(progressText(for: course))
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))

                        Button {
                            // NavigationLink handles navigation
                        } label: {
                            Label(course.playbackPosition > 0 ? "继续播放" : "开始播放", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(16)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "headphones")
                    .font(.title)
                    .foregroundStyle(Color(.tertiaryLabel))

                Text("导入你的第一个课程")
                    .font(.body)
                    .foregroundStyle(Color(.secondaryLabel))

                Button("导入", action: onImportTap)
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    @ViewBuilder
    private func coverImage(for course: Course) -> some View {
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
                        .font(.system(size: 40))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
        }
    }

    private func progressText(for course: Course) -> String {
        if let lastPlayed = course.lastPlayedAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd HH:mm"
            return "上次播放 \(formatter.string(from: lastPlayed))"
        }
        return "刚导入，准备开始"
    }
}
