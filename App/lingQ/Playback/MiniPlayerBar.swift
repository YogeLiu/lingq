import SwiftUI
import SharedModels
import UIKit

struct MiniPlayerBar: View {
    let playbackManager: PlaybackManager
    let onTap: () -> Void

    var body: some View {
        if let course = playbackManager.currentCourse, playbackManager.loadState == .ready {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    coverThumbnail(for: course)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text(course.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(.label))
                        .lineLimit(1)

                    Spacer()

                    Button {
                        playbackManager.player.toggle()
                    } label: {
                        Image(systemName: playbackManager.player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(.label))
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    ZStack(alignment: .bottom) {
                        Color(.secondarySystemBackground)

                        // Progress indicator at the bottom edge
                        GeometryReader { proxy in
                            Rectangle()
                                .fill(Color.accentColor.opacity(0.5))
                                .frame(width: proxy.size.width * progressFraction)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        }
                        .frame(height: 2)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                )
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 16,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var progressFraction: Double {
        let duration = playbackManager.player.duration
        let time = playbackManager.player.currentTime
        guard duration.isFinite, duration > 0, time.isFinite else { return 0 }
        return min(max(time / duration, 0), 1)
    }

    @ViewBuilder
    private func coverThumbnail(for course: Course) -> some View {
        if let coverURL = course.resolvedCoverImageURL,
           let coverImage = UIImage(contentsOfFile: coverURL.path) {
            Image(uiImage: coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.systemFill))
                .overlay {
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
        }
    }
}
