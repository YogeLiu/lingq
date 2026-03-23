import Foundation

public enum WordLevel: Int, Codable, Sendable, CaseIterable {
    case saved = 1
    case known = 4

    public var displayName: String {
        switch self {
        case .saved: "SAVED"
        case .known: "KNOWN"
        }
    }
}
