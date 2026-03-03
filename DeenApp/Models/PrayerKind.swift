//
//  PrayerKind.swift
//  DeenApp
//

import Foundation
import SwiftUI

/// Die 5 täglichen Gebete (API: Fajr, Dhuhr, Asr, Maghrib, Isha)
enum PrayerKind: String, CaseIterable, Codable {
    case fajr = "Fajr"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    /// Anzeigename (z. B. deutsch/türkisch)
    var displayName: String {
        switch self {
        case .fajr: return "Sabah"
        case .dhuhr: return "Öğle"
        case .asr: return "İkindi"
        case .maghrib: return "Akşam"
        case .isha: return "Yatsı"
        }
    }

    /// SF Symbol oder Icon-Hinweis für die View
    var iconName: String {
        switch self {
        case .fajr: return "flag.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "cloud.sun.fill"
        case .maghrib: return "building.2.fill"
        case .isha: return "moon.fill"
        }
    }

    /// Farbe für das Fajr-Flaggen-Icon
    var iconColor: Color {
        switch self {
        case .fajr: return Theme.iconFajr
        default: return Theme.textSecondary
        }
    }
}
