import SwiftUI

struct Theme {
    // Dark theme colors
    static let darkBgDeep = Color(hex: "08090a")
    static let darkBgSurface = Color(hex: "0d0e10")
    static let darkBgElevated = Color(hex: "131416")
    static let darkBgHover = Color(hex: "1a1b1e")
    static let darkBorder = Color(hex: "1e2023")
    static let darkTextPrimary = Color(hex: "e8e8e8")
    static let darkTextSecondary = Color(hex: "8b8d91")
    static let darkTextTertiary = Color(hex: "5a5c60")
    static let darkTextMuted = Color(hex: "3d3f42")

    // Light theme colors
    static let lightBgDeep = Color(hex: "fafafa")
    static let lightBgSurface = Color(hex: "ffffff")
    static let lightBgElevated = Color(hex: "f5f5f5")
    static let lightBgHover = Color(hex: "efefef")
    static let lightBorder = Color(hex: "e5e5e5")
    static let lightTextPrimary = Color(hex: "171717")
    static let lightTextSecondary = Color(hex: "525252")
    static let lightTextTertiary = Color(hex: "737373")
    static let lightTextMuted = Color(hex: "a3a3a3")

    // Accent colors
    static let accent = Color(hex: "E86F33")
    static let success = Color(hex: "3ecf8e")
    static let warning = Color(hex: "f0b429")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
