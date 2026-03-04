//
//  Theme.swift
//  DeenApp
//
//  Globale Farbpalette & Design-Tokens (aus Screenshot extrahiert)
//

import SwiftUI
import UIKit

enum Theme {

    // MARK: - Background (dynamic — hue follows the selected accent theme)

    /// Haupt-Hintergrund: very dark shade of the current accent hue.
    static var background: Color {
        Color(uiColor: ThemeColor.current.darkShade(brightness: 0.11, saturation: 0.28))
    }

    /// Karten-Hintergrund: slightly lighter shade of the accent hue.
    static var cardBackground: Color {
        Color(uiColor: ThemeColor.current.darkShade(brightness: 0.16, saturation: 0.32))
    }

    /// Nächste-Gebet-Karte: subtly lighter than cardBackground.
    static var cardHighlightBackground: Color {
        Color(uiColor: ThemeColor.current.darkShade(brightness: 0.18, saturation: 0.34))
    }

    // MARK: - Accent & Primary (dynamic — reads from ThemeColor.current)

    /// User-selected accent color. Resolves via ThemeColor.current so all
    /// views re-render automatically when AppState.accentTheme changes.
    static var accent: Color { ThemeColor.current.color }

    /// Leicht abgetönter Akzent für Glow
    static var accentMuted: Color { ThemeColor.current.color.opacity(0.85) }

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

    // MARK: - Tajweed Colors (Turkish Tajweed rule set)

    /// Pink — İdgham Meal Günne (a/w) + Ghunna/Mushaddad (n/g)
    static let tajweedIdghamGhunna  = Color(hex: "F06292")
    /// Brown — İdgham Mütecaniseyn / Mütekaribeyn / Müteşabihteyn (i)
    static let tajweedIdghamMutmath = Color(hex: "A1887F")
    /// Dark Green — İhfa Hakiki (f)
    static let tajweedIkhfa         = Color(hex: "66BB6A")
    /// Light Green — Dudak İhfası / İhfa Şefevi (m)
    static let tajweedIkhfaShafawi  = Color(hex: "A5D6A7")
    /// Beige — Kalkale (q)
    static let tajweedQalqala       = Color(hex: "D4AC7A")
    /// Blue — İklab (c) + Medd-i Arız / Tabii / Sıla (j/r/v)
    static let tajweedIqlab         = Color(hex: "42A5F5")
    /// Forest Green — İzhar (o)  — noticeably darker than İhfa
    static let tajweedIzhar         = Color(hex: "388E3C")
    /// Gold — Medd-i Lin (p/b)
    static let tajweedMaddLin       = Color(hex: "FFD54F")
    /// Gray — Okunmayan Harfler / Hamza Vasl / Sessiz Lam (h/l/s)
    static let tajweedSilent        = Color(hex: "90A4AE")
    /// Red — Medd-i Muttasıl + Medd-i Munfasıl (k/t)
    static let tajweedMaddQasr      = Color(hex: "EF5350")
    /// Orange — Medd-i Lazım (u)
    static let tajweedMaddLazim     = Color(hex: "FF9800")
    /// White — untagged Arabic text
    static let tajweedDefault       = Color.white

    // MARK: - Shadows

    static let shadowColor = Color.black.opacity(0.35)
    static let shadowRadius: CGFloat = 12
    static let shadowY: CGFloat = 6

    // MARK: - Layout

    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
}

// MARK: - ThemeColor

/// The seven user-selectable accent colors.
/// The selection is persisted to UserDefaults so `Theme.accent` (a computed var)
/// always returns the correct value at render time without any singleton dependency.
enum ThemeColor: String, CaseIterable, Identifiable {
    case seaBlue      = "sea_blue"
    case darkPurple   = "dark_purple"
    case softGray     = "soft_gray"
    case beige        = "beige"
    case emeraldGreen = "emerald_green"
    case slateBlue    = "slate_blue"
    case warmGold     = "warm_gold"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .seaBlue:      return "Sea Blue"
        case .darkPurple:   return "Dark Purple"
        case .softGray:     return "Soft Gray"
        case .beige:        return "Beige"
        case .emeraldGreen: return "Emerald Green"
        case .slateBlue:    return "Slate Blue"
        case .warmGold:     return "Warm Gold"
        }
    }

    var color: Color {
        switch self {
        case .seaBlue:      return Color(hex: "1E88E5")
        case .darkPurple:   return Color(hex: "7B2FBE")
        case .softGray:     return Color(hex: "9E9E9E")
        case .beige:        return Color(hex: "D4A574")
        case .emeraldGreen: return Color(hex: "36D080")
        case .slateBlue:    return Color(hex: "5C7AEA")
        case .warmGold:     return Color(hex: "FFC107")
        }
    }

    /// Reads the persisted selection from UserDefaults.
    /// Used by `Theme.accent` to stay stateless while remaining reactive.
    static var current: ThemeColor {
        let raw = UserDefaults.standard.string(forKey: "dailydee.accentTheme") ?? ""
        return ThemeColor(rawValue: raw) ?? .emeraldGreen
    }

    /// Produces a dark `UIColor` that shares the hue of this accent color
    /// but with fixed low saturation and brightness — used to generate
    /// theme-matched background shades for `Theme.background` etc.
    fileprivate func darkShade(brightness: CGFloat, saturation: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: saturation, brightness: brightness, alpha: 1)
    }
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
