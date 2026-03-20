import SwiftUI
import SharedModels

struct TappableWordView: View {
    let word: String
    let level: WordLevel?
    let onTap: () -> Void

    var body: some View {
        Text(word)
            .underline(level?.isLearning == true, color: underlineColor)
            .foregroundStyle(level == .known ? .secondary : .primary)
            .onTapGesture(perform: onTap)
    }

    private var underlineColor: Color {
        switch level {
        case .level1: AppTheme.level1Color
        case .level2: AppTheme.level2Color
        case .level3: AppTheme.level3Color
        default: .clear
        }
    }
}
