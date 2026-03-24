import SwiftUI

enum LyricLineView {
    enum LyricState {
        case past(distance: Int)
        case current
        case future(distance: Int)
    }
}

extension LyricLineView.LyricState {
    var isCurrent: Bool {
        if case .current = self { return true }
        return false
    }
}
