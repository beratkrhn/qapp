//
//  WidgetShared.swift
//  AkhWidget
//
//  Module-scoped helpers reused by every widget in this extension:
//  App Group access, accent-aware theming, DITIB self-fetch and timeline
//  cache loading. Mirrors the file-private helpers in DeenWidget.swift —
//  kept separate so the new widgets can share them without touching the
//  original implementation.
//

import WidgetKit
import SwiftUI
import UIKit

// MARK: - App Group keys

enum WidgetAppGroup {
    static let suiteName       = "group.d.DailyDee"
    static let todayPrayersKey = "widgetTodayPrayers"
    static let cityKey         = "widgetCityName"
    static let accentThemeKey  = "dailydee.accentTheme"
    static let districtIdKey   = "widgetDistrictId"
    static let appLanguageKey  = "dailydee.appLanguage"
    static let ditibBase       = "https://ezanvakti.imsakiyem.com/api"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
}

// MARK: - Theme

/// Mapping from `ThemeColor.rawValue` to the hex string used by the widget.
private let widgetThemeHexMap: [String: String] = [
    "sea_blue":      "1E88E5",
    "dark_purple":   "7B2FBE",
    "beige":         "D4A574",
    "emerald_green": "36D080",
    "sunset_coral":  "F26D5B",
    "royal_teal":    "0EA5A4",
]

enum WidgetTheme {
    static func accentColor(rawValue: String) -> Color {
        let hex = widgetThemeHexMap[rawValue] ?? widgetThemeHexMap["emerald_green"]!
        return Color(sharedHex: hex)
    }
}

extension Color {
    /// Module-scoped hex initialiser used by every widget. Named distinctly so
    /// it doesn't clash with the file-private `init(widgetHex:)` in DeenWidget.swift.
    init(sharedHex hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch trimmed.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Lightweight DITIB models (module-scoped, mirrors WDitib* in DeenWidget.swift)

struct SharedDitibTimes: Decodable {
    let imsak: String; let gunes: String; let ogle: String
    let ikindi: String; let aksam: String; let yatsi: String
}
struct SharedDitibDay: Decodable { let date: String; let times: SharedDitibTimes }
struct SharedDitibResponse: Decodable { let data: [SharedDitibDay] }

// MARK: - App Group readers

enum WidgetDataSource {

    static func loadPrayers() -> [WidgetPrayer]? {
        guard let data = WidgetAppGroup.defaults?.data(forKey: WidgetAppGroup.todayPrayersKey)
        else { return nil }
        return try? JSONDecoder().decode([WidgetPrayer].self, from: data)
    }

    static func loadCity() -> String? {
        WidgetAppGroup.defaults?
            .string(forKey: WidgetAppGroup.cityKey)
            .flatMap { $0.isEmpty ? nil : $0 }
    }

    static func loadDistrictId() -> String? {
        WidgetAppGroup.defaults?
            .string(forKey: WidgetAppGroup.districtIdKey)
            .flatMap { $0.isEmpty ? nil : $0 }
    }

    static func loadAccentRaw() -> String {
        WidgetAppGroup.defaults?
            .string(forKey: WidgetAppGroup.accentThemeKey) ?? "emerald_green"
    }

    /// Returns the user's selected app-language raw value (e.g. "de", "en", "tr").
    /// Defaults to German if no value is present.
    static func loadLanguageRaw() -> String {
        WidgetAppGroup.defaults?
            .string(forKey: WidgetAppGroup.appLanguageKey) ?? "de"
    }

    /// True when every stored prayer's Date is before the start of today —
    /// meaning the App Group cache is from a previous day.
    static func arePrayersStale(_ prayers: [WidgetPrayer]) -> Bool {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return prayers.allSatisfy { $0.time < startOfToday }
    }
}

// MARK: - DITIB self-fetch

enum WidgetDitibFetcher {

    /// Fetches today's prayer times directly from the DITIB API and maps them
    /// to `WidgetPrayer` values anchored to `referenceDate`. Used as a fallback
    /// when the App Group cache is stale (e.g. day rolled over before the main
    /// app refreshed).
    static func fetchTodayPrayers(districtId: String,
                                  referenceDate: Date,
                                  completion: @escaping ([WidgetPrayer]?) -> Void) {
        let urlString = "\(WidgetAppGroup.ditibBase)/prayer-times/\(districtId)/daily"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard
                let data,
                let response = try? JSONDecoder().decode(SharedDitibResponse.self, from: data),
                !response.data.isEmpty
            else {
                completion(nil)
                return
            }
            let iso = DateFormatter()
            iso.locale = Locale(identifier: "en_US_POSIX")
            iso.dateFormat = "yyyy-MM-dd"
            let todayISO = iso.string(from: referenceDate)
            let today = response.data.first(where: { $0.date.hasPrefix(todayISO) })
                     ?? response.data.first!
            completion(buildPrayers(from: today.times, referenceDate: referenceDate))
        }.resume()
    }

    static func buildPrayers(from t: SharedDitibTimes, referenceDate: Date) -> [WidgetPrayer] {
        func d(_ hhmm: String) -> Date {
            let p = hhmm.split(separator: ":").compactMap { Int($0) }
            guard p.count >= 2 else { return referenceDate }
            return Calendar.current.date(bySettingHour: p[0], minute: p[1],
                                         second: 0, of: referenceDate) ?? referenceDate
        }
        return [
            WidgetPrayer(kindRaw: "Imsak",   name: "Fajr",    iconName: "moon.haze.fill",  timeString: t.imsak,  time: d(t.imsak)),
            WidgetPrayer(kindRaw: "Sunrise", name: "Shuruuq", iconName: "sunrise.fill",    timeString: t.gunes,  time: d(t.gunes)),
            WidgetPrayer(kindRaw: "Dhuhr",   name: "Dhuhr",   iconName: "sun.max.fill",    timeString: t.ogle,   time: d(t.ogle)),
            WidgetPrayer(kindRaw: "Asr",     name: "Asr",     iconName: "cloud.sun.fill",  timeString: t.ikindi, time: d(t.ikindi)),
            WidgetPrayer(kindRaw: "Maghrib", name: "Maghrib", iconName: "sunset.fill",     timeString: t.aksam,  time: d(t.aksam)),
            WidgetPrayer(kindRaw: "Isha",    name: "Isha",    iconName: "moon.fill",       timeString: t.yatsi,  time: d(t.yatsi)),
        ]
    }
}

// MARK: - Prayer subset helpers

/// Returns the next-prayer name relative to `now`, falling back to tomorrow's
/// first prayer when every prayer for today has already passed.
func widgetNextPrayer(in prayers: [WidgetPrayer], from now: Date) -> (name: String, time: Date)? {
    if let next = prayers.first(where: { $0.time > now }) {
        return (next.name, next.time)
    }
    guard let first = prayers.first else { return nil }
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: first.time) ?? now
    return (first.name, tomorrow)
}
