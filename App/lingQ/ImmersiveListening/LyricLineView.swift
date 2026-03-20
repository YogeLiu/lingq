import SwiftUI
import SharedModels

struct LyricLineView: View {
    let text: String
    let state: LyricState
    let onTap: () -> Void

    enum LyricState {
        case past(distance: Int)     // 已过句子，distance=与当前句的距离
        case current
        case future(distance: Int)
    }

    var body: some View {
        Text(text)
            .font(state.isCurrent ? .title.bold() : .body)
            .multilineTextAlignment(.center)
            .opacity(state.opacity)
            .scaleEffect(state.isCurrent ? 1.0 : 0.95)
            .shadow(color: state.isCurrent ? Color.accentColor.opacity(0.3) : .clear, radius: 20)
            .animation(.easeInOut(duration: 0.5), value: state.isCurrent)
            .onTapGesture(perform: onTap)
            .padding(.vertical, 8)
    }
}

extension LyricLineView.LyricState {
    var isCurrent: Bool {
        if case .current = self { return true }
        return false
    }

    var opacity: Double {
        switch self {
        case .current: 1.0
        case .past(let d), .future(let d):
            max(0.08, 0.4 - Double(d) * 0.1)
        }
    }
}
