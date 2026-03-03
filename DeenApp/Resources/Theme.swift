//
//  Theme.swift
//  DeenApp
//
//  Globale Farbpalette & Design-Tokens (aus Screenshot extrahiert)
//

import SwiftUI

enum Theme {

    // MARK: - Background

    /// Haupt-Hintergrund (dunkles, desaturiertes Grün-Grau) ~ #121C19
    static let background = Color(hex: "121C19")

    /// Karten-Hintergrund (etwas heller) ~ #1B2A26
    static let cardBackground = Color(hex: "1B2A26")

    /// Nächste-Gebet-Karte (subtil heller/glow) ~ #1E2E2A
    static let cardHighlightBackground = Color(hex: "1E2E2A")

    // MARK: - Accent & Primary

    /// Akzent Grün (Countdown, aktives Tab, hervorgehobener Text) ~ #36D080
    static let accent = Color(hex: "36D080")

    /// Leicht abgetönter Akzent für Glow
    static let accentMuted = Color(hex: "36D080").opacity(0.85)

    // MARK: - Text

    /// Primärer Text (Titel, Gebetsnamen)
    static let textPrimary = Color.white

    /// Sekundärer Text (Labels, Zeitzone) ~ #A5B2AD
    static let textSecondary = Color(hex: "A5B2AD")

    /// Sektion-Header (Uppercase Labels)
    static let textSection = Color(hex: "A5B2AD")

    // MARK: - Icons & Special

    /// Sabah/Fajr Icon (Orange-Gelb) ~ #FFC107
    static let iconFajr = Color(hex: "FFC107")

    /// Vokabeln Brain-Icon (Pink) ~ #E91E63
    static let iconBrain = Color(hex: "E91E63")

    // MARK: - Shadows

    static let shadowColor = Color.black.opacity(0.35)
    static let shadowRadius: CGFloat = 12
    static let shadowY: CGFloat = 6

    // MARK: - Layout

    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
}

// MARK: - Color+Hex

extension Color {
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
            (a, r, g, b) = (255, 0, 0, 0)
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
