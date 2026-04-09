//
//  PrayerKind.swift
//  DeenApp
//

import Foundation
import SwiftUI

/// Die angezeigten Gebetszeiten: İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı
enum PrayerKind: String, CaseIterable, Codable {
    case imsak = "Imsak"
    case shuruuq = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    var displayName: String {
        switch self {
        case .imsak:   return "İmsak"
        case .shuruuq: return "Güneş"
        case .dhuhr:   return "Öğle"
        case .asr:     return "İkindi"
        case .maghrib: return "Akşam"
        case .isha:    return "Yatsı"
        }
    }

    var iconName: String {
        switch self {
        case .imsak:   return "moon.haze.fill"
        case .shuruuq: return "sunrise.fill"
        case .dhuhr:   return "sun.max.fill"
        case .asr:     return "cloud.sun.fill"
        case .maghrib: return "sunset.fill"
        case .isha:    return "moon.fill"
        }
    }

    var iconColor: Color { .gray }

    /// Latin transcription of Arabic prayer names (used in Deutsch/Arabisch mode)
    var latinArabicName: String {
        switch self {
        case .imsak:   return "Fajr"
        case .shuruuq: return "Shuruuq"
        case .dhuhr:   return "Dhuhr"
        case .asr:     return "Asr"
        case .maghrib: return "Maghrib"
        case .isha:    return "Ishaa"
        }
    }

    /// Returns the prayer name localised for the given app language.
    /// - German and Deutsch/Arabisch → Arabic transliterations (Fajr, Shuruuq …)
    /// - Turkish and Deutsch/Türkisch → Turkish names (İmsak, Güneş …)
    /// - English → English names (Fajr, Sunrise …)
    func localizedName(for language: AppLanguage) -> String {
        switch language {
        case .german, .germanArabic:
            return latinArabicName
        case .turkish, .germanTurkish:
            return turkishName
        case .english:
            return englishName
        }
    }

    /// Turkish prayer names (used in Turkish and Deutsch/Türkisch modes)
    var turkishName: String {
        switch self {
        case .imsak:   return "İmsak"
        case .shuruuq: return "Güneş"
        case .dhuhr:   return "Öğle"
        case .asr:     return "İkindi"
        case .maghrib: return "Akşam"
        case .isha:    return "Yatsı"
        }
    }

    /// German prayer names
    var germanName: String {
        switch self {
        case .imsak:   return "Imsak"
        case .shuruuq: return "Sonnenaufgang"
        case .dhuhr:   return "Mittagsgebet"
        case .asr:     return "Nachmittagsgebet"
        case .maghrib: return "Abendgebet"
        case .isha:    return "Nachtgebet"
        }
    }

    /// English prayer names
    var englishName: String {
        switch self {
        case .imsak:   return "Fajr"
        case .shuruuq: return "Sunrise"
        case .dhuhr:   return "Dhuhr"
        case .asr:     return "Asr"
        case .maghrib: return "Maghrib"
        case .isha:    return "Isha"
        }
    }
}
