import Foundation
import SwiftData

@Model
public final class Course {
    public var id: UUID
    public var title: String
    public var audioBookmark: Data  // Security-Scoped Bookmark
    public var subtitleBookmark: Data
    public var createdAt: Date
    public var lastPlayedAt: Date?
    public var playbackPosition: TimeInterval
    public var folder: String?

    public init(
        title: String,
        audioBookmark: Data,
        subtitleBookmark: Data
    ) {
        self.id = UUID()
        self.title = title
        self.audioBookmark = audioBookmark
        self.subtitleBookmark = subtitleBookmark
        self.createdAt = Date()
        self.lastPlayedAt = nil
        self.playbackPosition = 0
        self.folder = nil
    }
}
