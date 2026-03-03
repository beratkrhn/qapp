//
//  QuranModels.swift
//  DeenApp
//

import Foundation

struct QuranBook: Decodable {
    let suras: [QuranSura]
}

struct QuranSura: Identifiable, Decodable {
    let id: Int
    let nameArabic: String
    let nameTransliteration: String
    let verses: [QuranVerse]
}

struct QuranVerse: Identifiable, Decodable {
    let id: Int
    let suraNumber: Int
    let verseNumber: Int
    let arabic: String
    let translationEN: String?
    let translationDE: String?

    init(id: Int, suraNumber: Int, verseNumber: Int, arabic: String, translationEN: String?, translationDE: String?) {
        self.id = id
        self.suraNumber = suraNumber
        self.verseNumber = verseNumber
        self.arabic = arabic
        self.translationEN = translationEN
        self.translationDE = translationDE
    }
}

/// Eine Seite im Mushaf-Stil (ca. 15 Zeilen)
struct QuranPage: Identifiable {
    let id: Int
    let verses: [QuranVerse]
}

/// Eine Ayah aus der Mushaf-Page-API (authentische Seitenzuordnung)
struct MushafAyah: Identifiable {
    let id: Int          // globale Ayah-Nummer
    let text: String
    let numberInSurah: Int
    let suraNumber: Int
    let suraName: String         // Arabischer Name
    let suraEnglishName: String
    let juz: Int
}

/// Eine echte Mushaf-Seite (1–604) mit ihren Ayahs
struct MushafPage: Identifiable {
    let id: Int          // Seitennummer 1–604
    let ayahs: [MushafAyah]

    /// Juz-Nummer der ersten Ayah auf dieser Seite
    var juzNumber: Int { ayahs.first?.juz ?? 1 }

    /// Englische Suranamen auf dieser Seite (dedupliziert, in Reihenfolge)
    var suraNames: [String] {
        var seen = Set<Int>()
        var names: [String] = []
        for a in ayahs where !seen.contains(a.suraNumber) {
            seen.insert(a.suraNumber)
            names.append(a.suraEnglishName)
        }
        return names
    }

    /// Arabische Suranamen auf dieser Seite (dedupliziert, in Reihenfolge)
    var suraArabicNames: [String] {
        var seen = Set<Int>()
        var names: [String] = []
        for a in ayahs where !seen.contains(a.suraNumber) {
            seen.insert(a.suraNumber)
            names.append(a.suraName)
        }
        return names
    }
}

/// Eine Ayah mit Übersetzungstext (für die Übersetzungs-Bottom-Sheet)
struct TranslationAyah: Identifiable {
    let id: Int          // globale Ayah-Nummer
    let numberInSurah: Int
    let suraNumber: Int
    let suraName: String // englischer Sura-Name
    let text: String     // Übersetzungstext
}
