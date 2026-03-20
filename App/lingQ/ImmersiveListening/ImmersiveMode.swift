enum ImmersiveMode: String, CaseIterable {
    case focused = "FOCUSED"
    case ambient = "AMBIENT"

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
