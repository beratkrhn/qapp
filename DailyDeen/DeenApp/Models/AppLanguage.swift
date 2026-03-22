//
//  AppLanguage.swift
//  DeenApp
//
//  App-Sprachen: DE, EN, TR, DE/AR (Islam-Begriffe in lateinischer Umschrift).
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case german = "de"
    case english = "en"
    case turkish = "tr"
    case germanArabic = "de_ar"   // Deutsch + islamische Begriffe lateinisch (Dhuhr, Wudu …)
    case germanTurkish = "de_tr"  // Deutsch + türkische Begriffe (Sabah, Öğle, …)

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .german: return "Deutsch"
        case .english: return "English"
        case .turkish: return "Türkçe"
        case .germanArabic: return "Deutsch / Arabisch"
        case .germanTurkish: return "Deutsch / Türkisch"
        }
    }

    /// Islam-Begriffe in lateinischer Umschrift (Fajr, Dhuhr …)
    var isIslamicTermsLatin: Bool { self == .germanArabic }
    /// Türkische Gebets-/Begriffsnamen (Sabah, Öğle …) bei deutscher UI
    var isIslamicTermsTurkish: Bool { self == .germanTurkish }
}
