import Foundation
@preconcurrency import MediaPlayer
import SharedModels
import AudioPlayerKit
import UIKit

enum NowPlayingManager {

    nonisolated(unsafe) private static var cachedArtwork: MPMediaItemArtwork?
    nonisolated(unsafe) private static var cachedCourseId: UUID?

    @MainActor
    static func configure(player: AudioPlayer) {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.playCommand.removeTarget(nil)
        center.playCommand.addTarget { _ in
            Task { @MainActor in player.play() }
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.removeTarget(nil)
        center.pauseCommand.addTarget { _ in
            Task { @MainActor in player.pause() }
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.addTarget { _ in
            Task { @MainActor in player.toggle() }
            return .success
        }

        center.skipForwardCommand.isEnabled = true
        center.skipForwardCommand.preferredIntervals = [10]
        center.skipForwardCommand.removeTarget(nil)
        center.skipForwardCommand.addTarget { _ in
            Task { @MainActor in player.skipForward(10) }
            return .success
        }

        center.skipBackwardCommand.isEnabled = true
        center.skipBackwardCommand.preferredIntervals = [10]
        center.skipBackwardCommand.removeTarget(nil)
        center.skipBackwardCommand.addTarget { _ in
            Task { @MainActor in player.skipBackward(10) }
            return .success
        }

        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.removeTarget(nil)
        center.changePlaybackPositionCommand.addTarget { event in
            guard let posEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in player.seek(to: posEvent.positionTime) }
            return .success
        }
    }

    @MainActor
    static func update(course: Course, player: AudioPlayer) {
        let duration = player.duration
        let currentTime = player.currentTime
        let rate = player.isPlaying ? Double(player.playbackRate) : 0.0
        let title = course.title
        let courseId = course.id
        let coverURL = course.resolvedCoverImageURL

        guard duration.isFinite, currentTime.isFinite else { return }

        if cachedCourseId != courseId {
            cachedCourseId = courseId
            cachedArtwork = nil
            if let coverURL,
               let imageData = try? Data(contentsOf: coverURL) {
                cachedArtwork = makeArtwork(from: imageData)
            }
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: rate
        ]
        if let artwork = cachedArtwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Build MPMediaItemArtwork in a nonisolated context so its request handler
    /// closure is not associated with MainActor — MediaPlayer calls it on its own queue.
    private nonisolated static func makeArtwork(from imageData: Data) -> MPMediaItemArtwork? {
        guard let image = UIImage(data: imageData) else { return nil }
        let size = image.size
        return MPMediaItemArtwork(boundsSize: size) { _ in
            UIImage(data: imageData) ?? UIImage()
        }
    }

    static func clear() {
        cachedArtwork = nil
        cachedCourseId = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
