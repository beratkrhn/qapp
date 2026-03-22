//
//  Theme.swift
//  DeenApp
//
<<<<<<< HEAD
//  Farbpalette & Design-Tokens — Light/Dark über dynamische UIColors, Akzent aus ThemeColor.
//

import SwiftUI
import UIKit

enum Theme {

    // MARK: - Background (accent-hue aware, Light/Dark)

    static var background: Color {
        Color(uiColor: UIColor { trait in
            let accent = ThemeColor.current
            switch trait.userInterfaceStyle {
            case .dark:
                return accent.uiDarkShade(brightness: 0.11, saturation: 0.28)
            case .light, .unspecified:
                return accent.uiLightShade(brightness: 0.97, saturation: 0.06)
            @unknown default:
                return accent.uiDarkShade(brightness: 0.11, saturation: 0.28)
            }
        })
    }

    static var cardBackground: Color {
        Color(uiColor: UIColor { trait in
            let accent = ThemeColor.current
            switch trait.userInterfaceStyle {
            case .dark:
                return accent.uiDarkShade(brightness: 0.16, saturation: 0.32)
            case .light, .unspecified:
                return accent.uiLightShade(brightness: 1.0, saturation: 0.08)
            @unknown default:
                return accent.uiDarkShade(brightness: 0.16, saturation: 0.32)
            }
        })
    }

    static var cardHighlightBackground: Color {
        Color(uiColor: UIColor { trait in
            let accent = ThemeColor.current
            switch trait.userInterfaceStyle {
            case .dark:
                return accent.uiDarkShade(brightness: 0.18, saturation: 0.34)
            case .light, .unspecified:
                return accent.uiLightShade(brightness: 0.99, saturation: 0.12)
            @unknown default:
                return accent.uiDarkShade(brightness: 0.18, saturation: 0.34)
            }
        })
    }

    // MARK: - Accent & Primary

    static var accent: Color { ThemeColor.resolvedSwiftUIColor }

    static var accentMuted: Color { ThemeColor.resolvedSwiftUIColor.opacity(0.85) }

    // MARK: - Text

    static var textPrimary: Color {
        Color(uiColor: UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark: return .white
            case .light, .unspecified: return UIColor(white: 0.12, alpha: 1)
            @unknown default: return .white
            }
        })
    }

    static var textSecondary: Color {
        Color(uiColor: UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark: return UIColor(red: 0.65, green: 0.70, blue: 0.68, alpha: 1)
            case .light, .unspecified: return UIColor(red: 0.38, green: 0.42, blue: 0.40, alpha: 1)
            @unknown default: return UIColor(red: 0.65, green: 0.70, blue: 0.68, alpha: 1)
            }
        })
    }

    static var textSection: Color { textSecondary }

    // MARK: - Icons & Special

    static let iconFajr = Color(hex: "FFC107")

    static let iconBrain = Color(hex: "E91E63")

    // MARK: - Tajweed Colors

    static let tajweedIdghamGhunna  = Color(hex: "c84782")
    static let tajweedIdghamMutmath = Color(hex: "836155")
    static let tajweedIkhfa         = Color(hex: "6ba66e")
    static let tajweedIkhfaShafawi  = Color(hex: "afbc5d")
    static let tajweedQalqala       = Color(hex: "a78c5f")
    /// İklab (c) — kräftiges Petrol
    static let tajweedIqlab         = Color(hex: "1B7A8C")
    static let tajweedIzhar         = Color(hex: "326e5a")
    static let tajweedMaddLin       = Color(hex: "b58640")
    static let tajweedSilent        = Color(hex: "90A4AE")
    static let tajweedMaddQasr      = Color(hex: "be4b58")
    static let tajweedMaddLazim     = Color(hex: "9b4c3a")
    static let tajweedMaddAriz      = Color(hex: "0184d7")
    static let tajweedDefault       = Color.white

    // MARK: - Shadows

    static var shadowColor: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.35)
                : UIColor.black.withAlphaComponent(0.12)
        })
    }

=======
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
>>>>>>> origin/claude/adoring-banach
    static let shadowRadius: CGFloat = 12
    static let shadowY: CGFloat = 6

    // MARK: - Layout

    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
}

<<<<<<< HEAD
// MARK: - ThemeColor

enum ThemeColor: String, CaseIterable, Identifiable {
    case seaBlue      = "sea_blue"
    case darkPurple   = "dark_purple"
    case softGray     = "soft_gray"
    case beige        = "beige"
    case emeraldGreen = "emerald_green"
    case warmGold     = "warm_gold"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .seaBlue:      return "Sea Blue"
        case .darkPurple:   return "Dark Purple"
        case .softGray:     return "Soft Gray"
        case .beige:        return "Beige"
        case .emeraldGreen: return "Emerald Green"
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
        case .warmGold:     return Color(hex: "FFC107")
        }
    }

    /// Persistierte Auswahl; entferntes `slate_blue` wird auf Smaragdgrün gemappt.
    static var current: ThemeColor {
        let raw = UserDefaults.standard.string(forKey: "dailydee.accentTheme") ?? ""
        if raw == "slate_blue" {
            return .emeraldGreen
        }
        return ThemeColor(rawValue: raw) ?? .emeraldGreen
    }

    fileprivate static var resolvedSwiftUIColor: Color { ThemeColor.current.color }

    fileprivate func uiDarkShade(brightness: CGFloat, saturation: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: saturation, brightness: brightness, alpha: 1)
    }

    fileprivate func uiLightShade(brightness: CGFloat, saturation: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: saturation, brightness: brightness, alpha: 1)
    }
}

=======
>>>>>>> origin/claude/adoring-banach
// MARK: - Color+Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
<<<<<<< HEAD
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
=======
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
>>>>>>> origin/claude/adoring-banach
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
