//
//  PrayerTutorialModels.swift
//  DeenApp
//
//  Datenmodelle für das interaktive Gebetstutorial (Hanafi-Rechtsschule).
//

import Foundation

// MARK: - Gender

enum Gender: String, CaseIterable, Identifiable {
    case male
    case female

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male:   return "Männlich"
        case .female: return "Weiblich"
        }
    }

    var iconName: String {
        switch self {
        case .male:   return "figure.stand"
        case .female: return "figure.stand.dress"
        }
    }
}

// MARK: - PrayerStep

struct PrayerStep: Identifiable, Hashable {
    let id: String
    let title: String
    let arabicText: String?
    let transliteration: String?
    let translation: String?
    let audioFileName: String?
    let imageNameMale: String
    let imageNameFemale: String

    init(
        id: String = UUID().uuidString,
        title: String,
        arabicText: String? = nil,
        transliteration: String? = nil,
        translation: String? = nil,
        audioFileName: String? = nil,
        imageNameMale: String,
        imageNameFemale: String
    ) {
        self.id = id
        self.title = title
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.translation = translation
        self.audioFileName = audioFileName
        self.imageNameMale = imageNameMale
        self.imageNameFemale = imageNameFemale
    }
}

