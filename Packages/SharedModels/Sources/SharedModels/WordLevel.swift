import Foundation

public enum WordLevel: Int, Codable, Sendable, CaseIterable {
    case new = 0
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case known = 4

    public var displayName: String {
        switch self {
        case .new: "NEW"
        case .level1: "BEGINNER"
        case .level2: "INTERMEDIATE"
        case .level3: "ADVANCED"
        case .known: "KNOWN"
        }
    }

    public var isLearning: Bool {
        switch self {
        case .level1, .level2, .level3: true
        default: false
        }
    }
}
