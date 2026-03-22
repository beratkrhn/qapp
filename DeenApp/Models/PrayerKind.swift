//
//  PrayerKind.swift
//  DeenApp
//

import Foundation
import SwiftUI

/// Die täglichen Gebete + Imsak und Shuruuq
enum PrayerKind: String, CaseIterable, Codable {
    case imsak = "Imsak"
    case fajr = "Fajr"
    case shuruuq = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    /// Anzeigename (z. B. deutsch/türkisch)
    var displayName: String {
        switch self {
        case .imsak:   return "İmsak"
        case .fajr:    return "Sabah"
        case .shuruuq: return "Güneş"
        case .dhuhr:   return "Öğle"
        case .asr:     return "İkindi"
        case .maghrib: return "Akşam"
        case .isha:    return "Yatsı"
        }
    }

    var germanName: String {
        switch self {
        case .imsak:   return "Imsak (Morgengebet)"
        case .fajr:    return "Morgengebet"
        case .shuruuq: return "Sonnenaufgang"
        case .dhuhr:   return "Mittagsgebet"
        case .asr:     return "Nachmittagsgebet"
        case .maghrib: return "Abendgebet"
        case .isha:    return "Nachtgebet"
        }
    }

    var englishName: String {
        switch self {
        case .imsak:   return "Imsak (Fajr)"
        case .fajr:    return "Fajr"
        case .shuruuq: return "Sunrise"
        case .dhuhr:   return "Dhuhr"
        case .asr:     return "Asr"
        case .maghrib: return "Maghrib"
        case .isha:    return "Isha"
        }
    }

    var turkishName: String {
        switch self {
        case .imsak:   return "İmsak (Sabah)"
        case .fajr:    return "Sabah"
        case .shuruuq: return "Güneş"
        case .dhuhr:   return "Öğle"
        case .asr:     return "İkindi"
        case .maghrib: return "Akşam"
        case .isha:    return "Yatsı"
        }
    }

    /// Lateinische Umschrift für DE/AR (islamische Begriffe)
    var latinArabicName: String {
        switch self {
        case .imsak:   return "Imsak (Fajr)"
        case .fajr:    return "Fajr"
        case .shuruuq: return "Shuruuq"
        case .dhuhr:   return "Dhuhr"
        case .asr:     return "Asr"
        case .maghrib: return "Maghrib"
        case .isha:    return "Isha"
        }
    }

    /// SF Symbol für die View
    var iconName: String {
        switch self {
        case .imsak:   return "moon.haze.fill"
        case .fajr:    return "flag.fill"
        case .shuruuq: return "sunrise.fill"
        case .dhuhr:   return "sun.max.fill"
        case .asr:     return "cloud.sun.fill"
        case .maghrib: return "sunset.fill"
        case .isha:    return "moon.fill"
        }
    }

    /// Farbe für das Icon
    var iconColor: Color {
        switch self {
        case .imsak:   return Theme.textSecondary
        case .fajr:    return Theme.iconFajr
        case .shuruuq: return .orange
        case .dhuhr:   return Color(hex: "FFD54F")
        case .asr:     return Color(hex: "FFB74D")
        case .maghrib: return Color(hex: "FF7043")
        case .isha:    return Theme.textSecondary
        }
    }
}
