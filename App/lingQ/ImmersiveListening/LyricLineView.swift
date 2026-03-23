import SwiftUI
import SharedModels

struct LyricLineView: View {
    let text: String
    let state: LyricState
    let mode: ImmersiveMode
    let onTap: () -> Void

    enum LyricState {
        case past(distance: Int)
        case current
        case future(distance: Int)
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(foregroundColor)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, state.isCurrent ? 8 : 2)
            .opacity(state.opacity(for: mode))
            .animation(.easeInOut(duration: 0.4), value: state.isCurrent)
            .onTapGesture(perform: onTap)
    }

    private var font: Font {
        if state.isCurrent {
            return .title3.weight(.bold)
        }
        return .body
    }

    private var foregroundColor: Color {
        switch state {
        case .current:
            return AppTheme.brandAccent
        case .future:
            return AppTheme.textPrimary
        case .past:
            return AppTheme.textTertiary
        }
    }
}

extension LyricLineView.LyricState {
    var isCurrent: Bool {
        if case .current = self { return true }
        return false
    }

    func opacity(for mode: ImmersiveMode) -> Double {
        switch self {
        case .current:
            return 1.0
        case .future(let d):
            return max(0.4, 1.0 - Double(d) * 0.08)
        case .past(let d):
            return max(0.2, 0.6 - Double(d) * 0.1)
        }
    }
}
