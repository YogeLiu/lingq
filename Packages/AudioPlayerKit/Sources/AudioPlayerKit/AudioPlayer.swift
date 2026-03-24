import AVFoundation
import Observation

@MainActor
@Observable
public final class AudioPlayer {
    public private(set) var isPlaying = false
    public private(set) var currentTime: TimeInterval = 0
    public private(set) var duration: TimeInterval = 0

    public var playbackRate: Float = 1.0 {
        didSet {
            let clamped = min(max(playbackRate, 0.5), 2.0)
            if clamped != playbackRate {
                playbackRate = clamped
            }
            avPlayer?.rate = isPlaying ? playbackRate : 0
        }
    }

    public var loopRange: ClosedRange<TimeInterval>?

    private var avPlayer: AVAudioPlayer?
    private var timer: Timer?

    public init() {}

    public func load(url: URL) throws {
        let player = try AVAudioPlayer(contentsOf: url)
        player.enableRate = true
        player.prepareToPlay()
        self.avPlayer = player
        self.duration = player.duration
        self.currentTime = 0
    }

    public func play() {
        guard let avPlayer else { return }
        avPlayer.rate = playbackRate
        avPlayer.play()
        isPlaying = true
        startTimer()
    }

    public func pause() {
        avPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    public func toggle() {
        isPlaying ? pause() : play()
    }

    public func seek(to time: TimeInterval) {
        let clamped = min(max(time, 0), duration)
        avPlayer?.currentTime = clamped
        currentTime = clamped
    }

    public func skipForward(_ seconds: TimeInterval = 10) {
        seek(to: currentTime + seconds)
    }

    public func skipBackward(_ seconds: TimeInterval = 10) {
        seek(to: currentTime - seconds)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let avPlayer = self.avPlayer else { return }
                let currentPlayerTime = avPlayer.currentTime
                self.currentTime = currentPlayerTime

                let range = self.loopRange
                if let range, currentPlayerTime >= range.upperBound {
                    self.seek(to: range.lowerBound)
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    public static func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
        #endif
    }
}
