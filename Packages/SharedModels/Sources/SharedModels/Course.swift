// Packages/SharedModels/Sources/SharedModels/Course.swift
import Foundation
import SwiftData

@Model
public final class Course {
    public var id: UUID
    public var title: String
    public var audioBookmark: Data  // legacy, keep for existing data
    public var subtitleBookmark: Data  // legacy
    public var audioFilePath: String?  // new: relative path in Documents
    public var subtitleFilePath: String?  // new: relative path in Documents
    public var coverImagePath: String?  // new: relative path in Documents
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
        self.audioFilePath = nil
        self.subtitleFilePath = nil
        self.coverImagePath = nil
        self.createdAt = Date()
        self.lastPlayedAt = nil
        self.playbackPosition = 0
        self.folder = nil
    }

    /// New initializer for zip import
    public init(
        title: String,
        audioFilePath: String,
        subtitleFilePath: String,
        coverImagePath: String?
    ) {
        self.id = UUID()
        self.title = title
        self.audioBookmark = Data()  // empty, not used
        self.subtitleBookmark = Data()  // empty, not used
        self.audioFilePath = audioFilePath
        self.subtitleFilePath = subtitleFilePath
        self.coverImagePath = coverImagePath
        self.createdAt = Date()
        self.lastPlayedAt = nil
        self.playbackPosition = 0
        self.folder = nil
    }

    /// Resolve audio URL — prefers local file path, falls back to bookmark
    public var resolvedAudioURL: URL? {
        if let audioFilePath {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return docs.appendingPathComponent(audioFilePath)
        }
        return nil
    }

    /// Resolve subtitle URL — prefers local file path, falls back to bookmark
    public var resolvedSubtitleURL: URL? {
        if let subtitleFilePath {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return docs.appendingPathComponent(subtitleFilePath)
        }
        return nil
    }

    /// Resolve cover image URL
    public var resolvedCoverImageURL: URL? {
        guard let coverImagePath else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(coverImagePath)
    }
}
