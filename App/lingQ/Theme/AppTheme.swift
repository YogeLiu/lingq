import SwiftUI
import UIKit

enum AppTheme {
    static let background = Color(lightHex: "F4F1EA", darkHex: "0D131C")
    static let chromeBackground = Color(lightHex: "F8F5EF", darkHex: "111826")
    static let elevatedBackground = Color(lightHex: "ECE6DA", darkHex: "141C28")
    static let surface = Color(lightHex: "FEFCF7", darkHex: "18202C")
    static let surfaceMuted = Color(lightHex: "F2EDE4", darkHex: "1F2937")

    static let brandAccent = Color(lightHex: "1C4D98", darkHex: "93B5FF")
    static let brandAccentMuted = Color(lightHex: "E7EDF9", darkHex: "273852")

    static let textPrimary = Color(lightHex: "162132", darkHex: "F4F7FC")
    static let textSecondary = Color(lightHex: "5D6778", darkHex: "A6B0C2")
    static let textTertiary = Color(lightHex: "89909C", darkHex: "808A9A")
    static let borderSubtle = Color(lightHex: "D9D2C7", darkHex: "2B3443")
    static let divider = Color(lightHex: "E8E0D4", darkHex: "242E3C")
    static let shadow = Color.black.opacity(0.08)

    static let success = Color(uiColor: .systemGreen)
    static let warning = Color(uiColor: .systemOrange)
    static let danger = Color(uiColor: .systemRed)

    static let cardCornerRadius: CGFloat = 28
    static let nestedCornerRadius: CGFloat = 22
    static let compactCornerRadius: CGFloat = 18
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

    init(lightHex: String, darkHex: String) {
        self.init(uiColor: UIColor { traitCollection in
            UIColor(hex: traitCollection.userInterfaceStyle == .dark ? darkHex : lightHex)
        })
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: CGFloat
        switch hex.count {
        case 6:
            r = CGFloat((int >> 16) & 0xFF) / 255
            g = CGFloat((int >> 8) & 0xFF) / 255
            b = CGFloat(int & 0xFF) / 255
        default:
            r = 0
            g = 0
            b = 0
        }

        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
