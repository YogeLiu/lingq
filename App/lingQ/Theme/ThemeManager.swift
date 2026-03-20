import SwiftUI

@Observable
final class ThemeManager {
    enum ThemeMode: String, CaseIterable {
        case system = "跟随系统"
        case light = "浅色"
        case dark = "深色"
    }

    var mode: ThemeMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: "themeMode") }
    }

    init() {
        self.mode = ThemeMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "") ?? .system
    }

    var colorScheme: ColorScheme? {
        switch mode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
