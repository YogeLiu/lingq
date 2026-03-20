import Foundation
import SharedModels

public struct CueSearcher: Sendable {
    private let cues: [SubtitleCue]

    public init(cues: [SubtitleCue]) {
        self.cues = cues.sorted { $0.startTime < $1.startTime }
    }

    public func cue(at time: TimeInterval) -> SubtitleCue? {
        var low = 0
        var high = cues.count - 1
        while low <= high {
            let mid = (low + high) / 2
            let c = cues[mid]
            if c.contains(time: time) {
                return c
            } else if time < c.startTime {
                high = mid - 1
            } else {
                low = mid + 1
            }
        }
        return nil
    }

    public func index(at time: TimeInterval) -> Int? {
        cues.firstIndex { $0.contains(time: time) }
    }

    public func nextCue(after time: TimeInterval) -> SubtitleCue? {
        guard let idx = index(at: time), idx + 1 < cues.count else { return nil }
        return cues[idx + 1]
    }

    public func previousCue(before time: TimeInterval) -> SubtitleCue? {
        guard let idx = index(at: time), idx > 0 else { return nil }
        return cues[idx - 1]
    }

    public var allCues: [SubtitleCue] { cues }
}
