import SwiftUI

extension Color {
    // Primary Colors
    static let championBlue = Color(hex: "4A90E2")
    static let victoryGold = Color(hex: "F5A623")
    static let energyGreen = Color(hex: "7ED321")

    // Secondary Colors
    static let softBackground = Color(hex: "F8F9FA")
    static let textPrimary = Color(hex: "2C3E50")
    static let textSecondary = Color(hex: "7F8C8D")
    static let accentRed = Color(hex: "E74C3C")
    static let accentPurple = Color(hex: "9B59B6")

    // Semantic Colors
    static let success = Color(hex: "27AE60")
    static let warning = Color(hex: "F39C12")
    static let error = Color(hex: "E74C3C")
    static let info = Color(hex: "3498DB")

    // Convenience initializer for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
