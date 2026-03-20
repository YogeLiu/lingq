import Foundation

enum BookmarkManager {
    static func createBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    static func resolveBookmark(_ data: Data) throws -> URL {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        if isStale {
            // Bookmark is stale, caller should recreate
        }
        return url
    }
}
