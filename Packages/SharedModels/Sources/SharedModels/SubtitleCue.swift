import Foundation

public struct SubtitleCue: Sendable, Identifiable, Equatable {
    public let id: Int  // SRT 序号
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let text: String

    public init(id: Int, startTime: TimeInterval, endTime: TimeInterval, text: String) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }

    public func contains(time: TimeInterval) -> Bool {
        time >= startTime && time < endTime
    }
}
