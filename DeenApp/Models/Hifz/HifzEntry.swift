//
//  HifzEntry.swift
//  DeenApp
//
//  Datenmodell für den Hifz-Tracker: ein gelernter Abschnitt aus dem Quran
//  (komplette Sure, Seitenbereich oder Ayah-Bereich) inklusive Zeitstempel
//  der letzten Wiederholung. Ein Erinnerungsnotification wird drei Tage
//  nach `lastRevisedAt` ausgelöst.
//

import Foundation

enum HifzPortion: Codable, Hashable {
    /// Komplette Sure (alle Ayat).
    case fullSurah
    /// Ein zusammenhängender Ayah-Bereich innerhalb der Sure.
    case ayahRange(from: Int, to: Int)
    /// Eine Anzahl Mushaf-Seiten (nur als grobes Label gespeichert; keine
    /// präzise Seitenzuordnung — das reicht für den Tracker).
    case pages(count: Int)
}

struct HifzEntry: Identifiable, Codable, Hashable {
    let id: String
    let createdAt: Date

    /// Suren-Nummer (1…114).
    var surahNumber: Int
    /// Lateinische Transliteration zum Anzeigen ohne Netzzugriff
    /// (z. B. "Al-Fatiha"). Wird beim Anlegen einmal eingefroren.
    var surahTransliteration: String
    /// Arabischer Suren-Name.
    var surahArabicName: String

    /// Was genau wurde gelernt.
    var portion: HifzPortion

    /// Zeitstempel der letzten Wiederholung. Beim Anlegen = `createdAt`,
    /// danach durch Tippen auf "Wiederholt" aktualisiert.
    var lastRevisedAt: Date

    init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        surahNumber: Int,
        surahTransliteration: String,
        surahArabicName: String,
        portion: HifzPortion,
        lastRevisedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.surahNumber = surahNumber
        self.surahTransliteration = surahTransliteration
        self.surahArabicName = surahArabicName
        self.portion = portion
        self.lastRevisedAt = lastRevisedAt ?? createdAt
    }

    /// Wann die nächste Wiederholungserinnerung anstehen soll.
    var nextRevisionDue: Date {
        Calendar.current.date(byAdding: .day, value: 3, to: lastRevisedAt) ?? lastRevisedAt
    }

    /// Tage seit der letzten Wiederholung (auf ganze Tage gerundet).
    func daysSinceLastRevision(now: Date = Date()) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: lastRevisedAt)
        let end = cal.startOfDay(for: now)
        return cal.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// True, wenn die 3-Tage-Wiederholungsfrist überschritten ist.
    func isOverdue(now: Date = Date()) -> Bool {
        daysSinceLastRevision(now: now) >= 3
    }
}

extension HifzPortion {
    /// Kurz-Label für die Listendarstellung (sprachneutral, da Zahlen + Suren-Name
    /// bereits getrennt angezeigt werden).
    func shortLabel(language: AppLanguage) -> String {
        switch self {
        case .fullSurah:
            return L10n.hifzPortionFullSurah(language)
        case .ayahRange(let from, let to):
            if from == to { return L10n.hifzPortionAyah(language, ayah: from) }
            return L10n.hifzPortionAyahRange(language, from: from, to: to)
        case .pages(let count):
            return L10n.hifzPortionPages(language, count: count)
        }
    }
}
