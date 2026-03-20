import SwiftUI

enum AppTheme {
    // Dark mode colors
    static let darkBackground = Color(hex: "0D1117")
    static let darkSurface = Color(hex: "1C2333")
    static let darkAccent = Color(hex: "4A90D9")

    // Light mode colors
    static let lightBackground = Color(hex: "F8F9FB")
    static let lightSurface = Color.white
    static let lightAccent = Color(hex: "6C5CE7")

    // Word level colors
    static let level1Color = Color.green
    static let level2Color = Color.purple
    static let level3Color = Color.blue
    static let knownColor = Color.gray
    static let newColor = Color.cyan.opacity(0.5)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            (r, g, b) = (Double((int >> 16) & 0xFF) / 255, Double((int >> 8) & 0xFF) / 255, Double(int & 0xFF) / 255)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: r, green: g, blue: b)
    }
}
