//
//  WatchAccent.swift
//  AkhWatch / AkhWatchWidget
//
//  Mirrors ThemeColor.color from the iOS Theme.swift so the watch
//  surface uses the same accent the user picked on the phone.
//
//  Target membership: AkhWatch, AkhWatchWidget.
//

import SwiftUI

enum WatchAccent {
    /// Raw theme value → SwiftUI Color. Matches ThemeColor.color in Theme.swift.
    static func color(for raw: String) -> Color {
        switch raw {
        case "sea_blue":      return Color(hex: "1E88E5")
        case "dark_purple":   return Color(hex: "7B2FBE")
        case "beige":         return Color(hex: "D4A574")
        case "sunset_coral":  return Color(hex: "F26D5B")
        case "royal_teal":    return Color(hex: "0EA5A4")
        default:              return Color(hex: "36D080")   // emerald_green
        }
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
