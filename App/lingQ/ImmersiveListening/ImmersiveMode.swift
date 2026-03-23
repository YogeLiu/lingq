import Foundation

enum ImmersiveMode: String, CaseIterable {
    case focused = "FOCUSED"
    case ambient = "AMBIENT"

    var title: String {
        rawValue
    }

    var description: String {
        switch self {
        case .focused:
            "当前句更突出，适合跟读和点词"
        case .ambient:
            "弱化字幕强调，更适合连续听"
        }
    }

    var autoPauseDelay: TimeInterval? {
        switch self {
        case .focused: 0.8
        case .ambient: nil
        }
    }

    var showWordStatus: Bool {
        switch self {
        case .focused: true
        case .ambient: false
        }
    }
}
