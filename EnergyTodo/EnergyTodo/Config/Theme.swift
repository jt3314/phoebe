import SwiftUI

/// App-wide color theme matching the web app's warm retro palette.
/// Web CSS: primary hsl(16, 55%, 55%), background hsl(40, 20%, 94%)
enum Theme {
    // Primary - warm coral/terracotta
    static let primary = Color(hue: 16/360, saturation: 0.55, brightness: 0.80)
    static let primaryForeground = Color(hue: 40/360, saturation: 0.20, brightness: 0.96)

    // Background - warm beige
    static let background = Color(hue: 40/360, saturation: 0.12, brightness: 0.94)
    static let foreground = Color(hue: 30/360, saturation: 0.15, brightness: 0.35)

    // Card
    static let card = Color(hue: 40/360, saturation: 0.12, brightness: 0.97)
    static let cardBorder = Color(hue: 35/360, saturation: 0.12, brightness: 0.82)

    // Secondary
    static let secondary = Color(hue: 35/360, saturation: 0.15, brightness: 0.85)
    static let secondaryForeground = Color(hue: 30/360, saturation: 0.15, brightness: 0.40)

    // Muted
    static let muted = Color(hue: 35/360, saturation: 0.15, brightness: 0.88)
    static let mutedForeground = Color(hue: 30/360, saturation: 0.10, brightness: 0.50)

    // Accent
    static let accent = Color(hue: 35/360, saturation: 0.18, brightness: 0.88)

    // Destructive
    static let destructive = Color(hue: 0/360, saturation: 0.50, brightness: 0.70)

    // Status colors
    static let success = Color(hue: 142/360, saturation: 0.60, brightness: 0.55)
    static let warning = Color(hue: 38/360, saturation: 0.80, brightness: 0.65)

    // Lunar gradient colors (for calendar)
    static let lunarColors: [Color] = [
        Color(hex: "#FCF5F2"),
        Color(hex: "#F9EBE4"),
        Color(hex: "#F5DED2"),
        Color(hex: "#F0CFBD"),
        Color(hex: "#E8B89D"),
        Color(hex: "#DFA07D"),
        Color(hex: "#D4845A"),
    ]

    // Sleep check
    static let sleepBg = Color(hue: 220/360, saturation: 0.15, brightness: 0.95)
    static let sleepAccent = Color.indigo
}

// MARK: - Styled Card Modifier

struct ThemedCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.cardBorder, lineWidth: 0.5)
            )
    }
}

extension View {
    func themedCard() -> some View {
        modifier(ThemedCard())
    }
}
