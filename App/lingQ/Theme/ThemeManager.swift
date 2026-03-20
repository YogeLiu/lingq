import SwiftUI

@Observable
final class ThemeManager {
    enum ThemeMode: String, CaseIterable {
        case system = "跟随系统"
        case light = "浅色"
        case dark = "深色"
    }

    var mode: ThemeMode {
        get { ThemeMode(rawValue: storedMode) ?? .system }
        set { storedMode = newValue.rawValue }
    }

    @AppStorage("themeMode") private var storedMode = ThemeMode.system.rawValue

    var colorScheme: ColorScheme? {
        switch mode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
