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
        case .maghrib: return "building.2.fill"
        case .isha:    return "moon.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .shuruuq: return .orange
        default:       return Theme.textSecondary
        }
    }
}
