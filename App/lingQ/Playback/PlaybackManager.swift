import Foundation
import Observation
import AVFoundation
import SharedModels
import SubtitleKit
import AudioPlayerKit
import UIKit

@MainActor
@Observable
final class PlaybackManager {
    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    let player = AudioPlayer()
    private(set) var currentCourse: Course?
    private(set) var cues: [SubtitleCue] = []
    private(set) var searcher: CueSearcher?
    private(set) var loadState: LoadState = .idle

    private var audioResourceURL: URL?
    private var hasAudioSecurityScope = false
    private var progressTimer: Timer?
    private var nowPlayingTimer: Timer?
    private var interruptionObserver: Any?

    init() {
        observeInterruptions()
    }

    func play(course: Course) async {
        if currentCourse?.id == course.id {
            return
        }

        // Save progress of previous course and release resources
        saveProgress()
        releaseResources()

        currentCourse = course
        loadState = .loading

        do {
            let subtitleURL = try resolveSubtitleURL(for: course)
            cues = try SRTParser.parse(fileURL: subtitleURL)
            searcher = CueSearcher(cues: cues)

            let audioURL = try resolveAudioURL(for: course)
            audioResourceURL = audioURL
            try player.load(url: audioURL)

            if course.playbackPosition > 0 {
                player.seek(to: course.playbackPosition)
            }

            player.play()
            loadState = .ready
            NowPlayingManager.configure(player: player)
            NowPlayingManager.update(course: course, player: player)
            startProgressTimer()
            startNowPlayingUpdater()
        } catch {
            loadState = .failed("文件读取失败，可能是导入文件已移动或权限失效。请确认源文件仍存在后重试。")
        }
    }

    func stop() {
        saveProgress()
        player.pause()
        player.loopRange = nil
        stopNowPlayingUpdater()
        NowPlayingManager.clear()
        releaseResources()
        currentCourse = nil
        cues = []
        searcher = nil
        loadState = .idle
        stopProgressTimer()
    }

    func saveProgress() {
        guard let currentCourse, loadState == .ready else { return }
        currentCourse.playbackPosition = player.currentTime
        currentCourse.lastPlayedAt = Date()
        NowPlayingManager.update(course: currentCourse, player: player)
    }

    // MARK: - Resource Management

    private func releaseResources() {
        if hasAudioSecurityScope, let audioResourceURL {
            audioResourceURL.stopAccessingSecurityScopedResource()
        }
        hasAudioSecurityScope = false
        audioResourceURL = nil
    }

    private func resolveSubtitleURL(for course: Course) throws -> URL {
        if let resolvedSubtitleURL = course.resolvedSubtitleURL,
           FileManager.default.fileExists(atPath: resolvedSubtitleURL.path) {
            return resolvedSubtitleURL
        }
        let url = try BookmarkManager.resolveBookmark(course.subtitleBookmark)
        let hasScope = url.startAccessingSecurityScopedResource()
        defer { if hasScope { url.stopAccessingSecurityScopedResource() } }
        return url
    }

    private func resolveAudioURL(for course: Course) throws -> URL {
        if let resolvedAudioURL = course.resolvedAudioURL,
           FileManager.default.fileExists(atPath: resolvedAudioURL.path) {
            hasAudioSecurityScope = false
            return resolvedAudioURL
        }
        let url = try BookmarkManager.resolveBookmark(course.audioBookmark)
        hasAudioSecurityScope = url.startAccessingSecurityScopedResource()
        return url
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveProgress()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Now Playing Updater

    private func startNowPlayingUpdater() {
        stopNowPlayingUpdater()
        nowPlayingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let course = self.currentCourse, self.loadState == .ready else { return }
                NowPlayingManager.update(course: course, player: self.player)
            }
        }
    }

    private func stopNowPlayingUpdater() {
        nowPlayingTimer?.invalidate()
        nowPlayingTimer = nil
    }

    // MARK: - Audio Interruptions

    private func observeInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            let shouldResume: Bool
            if type == .ended,
               let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                shouldResume = AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume)
            } else {
                shouldResume = false
            }

            Task { @MainActor [weak self] in
                guard let self else { return }
                if type == .began {
                    self.player.pause()
                } else if type == .ended, shouldResume {
                    self.player.play()
                }
            }
        }
    }
}
