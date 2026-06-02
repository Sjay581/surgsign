import SwiftUI

extension Color {
    // MARK: - SurgSign Theme Colors

    /// Primary background — deep navy
    static let surgBackground = Color(hex: "#09152A")

    /// Card / surface background
    static let surgSurface = Color(hex: "#122039")

    /// Lighter surface for hover / highlight states
    static let surgSurfaceLight = Color(hex: "#1A2D4D")

    /// Primary accent — bright cyan
    static let surgAccent = Color(hex: "#00C8FF")

    /// AM shift color — warm amber
    static let surgAM = Color(hex: "#FFAD30")

    /// PM shift color — soft indigo
    static let surgPM = Color(hex: "#7B8EF7")

    /// Alert / high priority red
    static let surgRed = Color(hex: "#FF4538")

    /// Positive / stable green
    static let surgGreen = Color(hex: "#2ED44A")

    /// Primary text — white
    static let surgText = Color.white

    /// Secondary text — muted blue-gray
    static let surgTextSecondary = Color(hex: "#8899B0")

    /// Border / divider color
    static let surgBorder = Color(hex: "#1E3455")

    // MARK: - Hex Initializer

    /// Creates a `Color` from a hex string (e.g. "#FF4538" or "FF4538").
    /// Supports 6-character (RGB) and 8-character (ARGB) hex values.
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = sanitized.hasPrefix("#") ? String(sanitized.dropFirst()) : sanitized

        var rgbValue: UInt64 = 0
        Scanner(string: filtered).scanHexInt64(&rgbValue)

        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double

        switch filtered.count {
        case 6:
            red = Double((rgbValue >> 16) & 0xFF) / 255.0
            green = Double((rgbValue >> 8) & 0xFF) / 255.0
            blue = Double(rgbValue & 0xFF) / 255.0
            opacity = 1.0
        case 8:
            opacity = Double((rgbValue >> 24) & 0xFF) / 255.0
            red = Double((rgbValue >> 16) & 0xFF) / 255.0
            green = Double((rgbValue >> 8) & 0xFF) / 255.0
            blue = Double(rgbValue & 0xFF) / 255.0
        default:
            red = 0
            green = 0
            blue = 0
            opacity = 1.0
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}