//
//  Goal.swift
//  DeenApp
//
//  Datenmodell für persönliche Ziele (Khatm, Tagesseiten, fünf Pflichtgebete,
//  Sunnah-Gebete). Optional sichtbar für Freunde — in dem Fall wird der gleiche
//  Datensatz nach Firestore unter `users/{uid}/goals/{goalId}` gespiegelt.
//

import Foundation

// MARK: - Enums

enum GoalType: String, Codable, CaseIterable, Hashable {
    case khatmByDate          // Quran komplett bis Datum X durchlesen
    case dailyQuranPages      // N Seiten pro Tag lesen
    case fivePrayersDaily     // alle 5 Pflichtgebete täglich verrichten
    case sunnahPrayer         // Tahajjud / Witr / Duha mit Wochenziel

    var iconName: String {
        switch self {
        case .khatmByDate:      return "book.closed.fill"
        case .dailyQuranPages:  return "book.fill"
        case .fivePrayersDaily: return "moon.stars.fill"
        case .sunnahPrayer:     return "sparkles"
        }
    }
}

enum SunnahPrayerKind: String, Codable, CaseIterable, Hashable {
    case tahajjud, witr, duha
}

/// Die fünf Pflichtgebete, die im "alle 5 Gebete täglich"-Ziel abgehakt werden.
enum FardPrayer: String, Codable, CaseIterable, Hashable {
    case fajr, dhuhr, asr, maghrib, isha
}

// MARK: - FardPrayer display helper

extension FardPrayer {
    /// Anzeigename über das PrayerKind-Vokabular. `.fajr` wird bewusst auf
    /// `.imsak` gemappt — die Gebetszeiten-Ansicht nutzt die DITIB-Nomenklatur.
    func localizedName(language: AppLanguage) -> String {
        switch self {
        case .fajr:    return PrayerKind.imsak.localizedName(for: language)
        case .dhuhr:   return PrayerKind.dhuhr.localizedName(for: language)
        case .asr:     return PrayerKind.asr.localizedName(for: language)
        case .maghrib: return PrayerKind.maghrib.localizedName(for: language)
        case .isha:    return PrayerKind.isha.localizedName(for: language)
        }
    }
}

// MARK: - Goal

struct Goal: Identifiable, Codable, Hashable {

    /// Seitenzahl des Standard-Mushaf (Madina-Druck) — Basis aller Khatm-Berechnungen.
    static let totalMushafPages = 604

    /// Stabile UUID; auch der Firestore-Dokumentname.
    let id: String
    let createdAt: Date
    var type: GoalType
    var isActive: Bool
    var visibleToFriends: Bool

    // MARK: Configuration (nur die für `type` relevanten Felder werden gesetzt)

    /// `.khatmByDate`
    var khatmTargetDate: Date?

    /// `.dailyQuranPages` — Tagesziel in Mushaf-Seiten.
    var dailyPagesTarget: Int?

    /// `.sunnahPrayer`
    var sunnahKind: SunnahPrayerKind?
    /// `.sunnahPrayer` — Wochenziel (Anzahl pro Kalenderwoche).
    var sunnahWeeklyTarget: Int?

    /// `.khatmByDate` — zuletzt gelesene Mushaf-Seite im Khatma-Modus.
    /// Wird als "Lesezeichen" verwendet, um beim nächsten Öffnen direkt
    /// weiterzulesen.
    var khatmBookmarkPage: Int?

    // MARK: Progress logs
    // Datums-Schlüssel = "yyyy-MM-dd" im Nutzer-Kalender (UTC-frei).

    /// Pro Tag gelesene Mushaf-Seiten. Nur für `.khatmByDate` + `.dailyQuranPages`.
    var pagesPerDay: [String: Int]

    /// Pro Tag verrichtete Pflichtgebete. Nur für `.fivePrayersDaily`.
    /// Wert = `FardPrayer.rawValue`.
    var prayersPerDay: [String: [String]]

    /// Datumsliste, an denen das Sunnah-Gebet verrichtet wurde.
    /// Nur für `.sunnahPrayer`.
    var sunnahDates: [String]

    // MARK: - Init

    init(
        id: String = UUID().uuidString,
        type: GoalType,
        createdAt: Date = Date(),
        isActive: Bool = true,
        visibleToFriends: Bool = false,
        khatmTargetDate: Date? = nil,
        dailyPagesTarget: Int? = nil,
        sunnahKind: SunnahPrayerKind? = nil,
        sunnahWeeklyTarget: Int? = nil,
        khatmBookmarkPage: Int? = nil,
        pagesPerDay: [String: Int] = [:],
        prayersPerDay: [String: [String]] = [:],
        sunnahDates: [String] = []
    ) {
        self.id = id
        self.type = type
        self.createdAt = createdAt
        self.isActive = isActive
        self.visibleToFriends = visibleToFriends
        self.khatmTargetDate = khatmTargetDate
        self.dailyPagesTarget = dailyPagesTarget
        self.sunnahKind = sunnahKind
        self.sunnahWeeklyTarget = sunnahWeeklyTarget
        self.khatmBookmarkPage = khatmBookmarkPage
        self.pagesPerDay = pagesPerDay
        self.prayersPerDay = prayersPerDay
        self.sunnahDates = sunnahDates
    }
}

// MARK: - Date keys

enum GoalDateKey {
    /// "yyyy-MM-dd" im aktuellen Nutzer-Kalender.
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    static func key(for date: Date) -> String { formatter.string(from: date) }
    static var today: String { key(for: Date()) }
}

// MARK: - Progress helpers

extension Goal {

    /// Gesamtfortschritt in 0…1 zum heutigen Zeitpunkt.
    /// Definition pro Typ siehe Hilfsmethoden weiter unten.
    var progressFraction: Double {
        switch type {
        case .khatmByDate:      return khatmProgressFraction
        case .dailyQuranPages:  return dailyPagesProgressFraction
        case .fivePrayersDaily: return prayersTodayCount.fraction(of: FardPrayer.allCases.count)
        case .sunnahPrayer:     return sunnahWeekProgressFraction
        }
    }

    /// Eine Zeile Beschreibung, z. B. "120 / 604 Seiten" oder "3 / 5 Gebete".
    func progressLabel(language: AppLanguage) -> String {
        switch type {
        case .khatmByDate:
            return "\(khatmPagesRead) / \(Goal.totalMushafPages) \(L10n.goalsPagesUnit(language))"
        case .dailyQuranPages:
            let today = pagesReadToday
            let target = dailyPagesTarget ?? 0
            return "\(today) / \(target) \(L10n.goalsPagesUnit(language))"
        case .fivePrayersDaily:
            return "\(prayersTodayCount) / 5 \(L10n.goalsPrayersUnit(language))"
        case .sunnahPrayer:
            let count = sunnahCountThisWeek
            let target = sunnahWeeklyTarget ?? 0
            return "\(count) / \(target) \(L10n.goalsThisWeekUnit(language))"
        }
    }

    /// Lokalisierter Titel (z. B. "Khatm bis 30.06.2026").
    func title(language: AppLanguage) -> String {
        switch type {
        case .khatmByDate:
            if let date = khatmTargetDate {
                let f = DateFormatter()
                f.dateStyle = .medium
                f.locale = Locale(identifier: language.localeIdentifier)
                return "\(L10n.goalTypeKhatm(language)) · \(f.string(from: date))"
            }
            return L10n.goalTypeKhatm(language)
        case .dailyQuranPages:
            return L10n.goalTypeDailyPages(language)
        case .fivePrayersDaily:
            return L10n.goalTypeFivePrayers(language)
        case .sunnahPrayer:
            return sunnahKind?.localizedName(language: language) ?? L10n.goalTypeSunnah(language)
        }
    }

    // MARK: Per-type computations

    /// Seiten, die seit Anlage des Khatm-Ziels gelesen wurden (Summe aus Log).
    var khatmPagesRead: Int {
        pagesPerDay.values.reduce(0, +)
    }

    /// Verbleibende Tage bis zum Khatm-Zieldatum (inkl. heute, min 1).
    var khatmDaysRemaining: Int {
        guard let target = khatmTargetDate else { return 0 }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.startOfDay(for: target)
        let comps = cal.dateComponents([.day], from: start, to: end)
        return max(1, (comps.day ?? 0) + 1)
    }

    /// Wieviele Seiten der Nutzer ab heute pro Tag schaffen muss, um das Khatm zu erreichen.
    var khatmPagesPerDayNeeded: Int {
        let remainingPages = max(0, Self.totalMushafPages - khatmPagesRead)
        return Int(ceil(Double(remainingPages) / Double(khatmDaysRemaining)))
    }

    var khatmProgressFraction: Double {
        min(1.0, Double(khatmPagesRead) / Double(Self.totalMushafPages))
    }

    var pagesReadToday: Int { pagesPerDay[GoalDateKey.today] ?? 0 }

    var dailyPagesProgressFraction: Double {
        guard let target = dailyPagesTarget, target > 0 else { return 0 }
        return min(1.0, Double(pagesReadToday) / Double(target))
    }

    var prayersTodayCount: Int {
        prayersPerDay[GoalDateKey.today]?.count ?? 0
    }

    var prayersToday: Set<FardPrayer> {
        Set((prayersPerDay[GoalDateKey.today] ?? []).compactMap(FardPrayer.init(rawValue:)))
    }

    var sunnahCountThisWeek: Int {
        let cal = Calendar.current
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())?.start
        else { return sunnahDates.count }
        return sunnahDates.filter {
            guard let d = GoalDateKey.formatter.date(from: $0) else { return false }
            return d >= weekStart
        }.count
    }

    var sunnahWeekProgressFraction: Double {
        guard let target = sunnahWeeklyTarget, target > 0 else { return 0 }
        return min(1.0, Double(sunnahCountThisWeek) / Double(target))
    }
}

private extension Int {
    func fraction(of denominator: Int) -> Double {
        guard denominator > 0 else { return 0 }
        return Swift.min(1.0, Double(self) / Double(denominator))
    }
}

// MARK: - SunnahPrayerKind helpers

extension SunnahPrayerKind {
    func localizedName(language: AppLanguage) -> String {
        switch self {
        case .tahajjud: return L10n.goalSunnahTahajjud(language)
        case .witr:     return L10n.goalSunnahWitr(language)
        case .duha:     return L10n.goalSunnahDuha(language)
        }
    }
}

// MARK: - AppLanguage locale helper (used by Goal.title formatter)

extension AppLanguage {
    /// Best-effort BCP-47 für die NSDateFormatter-Lokalisierung der Goal-Titel.
    var localeIdentifier: String {
        switch self {
        case .german, .germanArabic, .germanTurkish: return "de_DE"
        case .english:                               return "en_US"
        case .turkish:                               return "tr_TR"
        }
    }
}
