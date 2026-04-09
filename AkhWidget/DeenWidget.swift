//
//  DeenWidget.swift
//  AkhWidget
//
//  Prayer-times home-screen widget for DailyDeen.
//  Reads data written by PrayerTimeManager via the shared App Group
//  "group.d.DailyDee" — always in sync with the main app.
//  Accent color is read from App Group UserDefaults and matches the in-app theme.
//

import WidgetKit
import SwiftUI
import UIKit

// MARK: - Constants

private enum DeenWidgetConst {
    static let suiteName       = "group.d.DailyDee"
    static let todayPrayersKey = "widgetTodayPrayers"
    static let cityKey         = "widgetCityName"
    static let accentThemeKey  = "dailydee.accentTheme"
    static let districtIdKey   = "widgetDistrictId"
    static let ditibBase       = "https://ezanvakti.imsakiyem.com/api"
}

// MARK: - Lightweight DITIB models (widget-local, no dependency on main target)

private struct WDitibTimes: Decodable {
    let imsak: String; let gunes: String; let ogle: String
    let ikindi: String; let aksam: String; let yatsi: String
}
private struct WDitibDay: Decodable { let date: String; let times: WDitibTimes }
private struct WDitibResponse: Decodable { let data: [WDitibDay] }

// MARK: - Color helpers

// Mapping from theme raw value to hex string (mirrors ThemeColor in Theme.swift)
private let themeHexMap: [String: String] = [
    "sea_blue":      "1E88E5",
    "dark_purple":   "7B2FBE",
    "soft_gray":     "E53935",  // legacy → mapped to Red
    "red":           "E53935",
    "beige":         "D4A574",
    "emerald_green": "36D080",
    "warm_gold":     "FFC107",
    "white":         "F5F5F5",
    "dark_gray":     "424242",
]

private func accentColorForRaw(_ raw: String) -> Color {
    let hex = themeHexMap[raw] ?? themeHexMap["emerald_green"]!
    return Color(widgetHex: hex)
}

/// Compute the widget background color from the accent hue, adapted for light/dark mode.
private func computeWidgetBgColor(accentUIColor: UIColor, colorScheme: ColorScheme) -> Color {
    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    accentUIColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    if colorScheme == .dark {
        return Color(UIColor(hue: h, saturation: 0.28, brightness: 0.11, alpha: 1))
    } else {
        return Color(UIColor(hue: h, saturation: 0.06, brightness: 0.97, alpha: 1))
    }
}

extension Color {
    /// Hex initializer scoped to the widget target.
    fileprivate init(widgetHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
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

// MARK: - Data Model
// Field names must exactly match WidgetPrayerEntry in the main app target.

struct WidgetPrayer: Codable, Identifiable {
    var id: String { kindRaw }
    let kindRaw: String
    let name: String
    let iconName: String
    let timeString: String
    let time: Date
}

// MARK: - Timeline Entry

struct DeenEntry: TimelineEntry {
    let date: Date
    let cityName: String
    let nextPrayerName: String
    let nextPrayerDate: Date
    let prayers: [WidgetPrayer]
    /// Raw value of the selected ThemeColor (e.g. "emerald_green")
    let accentThemeRaw: String
}

extension DeenEntry {
    var accentColor: Color { accentColorForRaw(accentThemeRaw) }

    static func makePlaceholder() -> DeenEntry {
        let now = Date()
        let cal = Calendar.current
        let d = { (h: Int, m: Int) -> Date in
            cal.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now
        }
        let prayers: [WidgetPrayer] = [
            WidgetPrayer(kindRaw: "Imsak",   name: "Fajr",    iconName: "moon.haze.fill",  timeString: "05:22", time: d(5,  22)),
            WidgetPrayer(kindRaw: "Sunrise", name: "Shuruuq", iconName: "sunrise.fill",    timeString: "06:54", time: d(6,  54)),
            WidgetPrayer(kindRaw: "Dhuhr",   name: "Dhuhr",   iconName: "sun.max.fill",    timeString: "13:08", time: d(13,  8)),
            WidgetPrayer(kindRaw: "Asr",     name: "Asr",     iconName: "cloud.sun.fill",  timeString: "16:45", time: d(16, 45)),
            WidgetPrayer(kindRaw: "Maghrib", name: "Maghrib", iconName: "sunset.fill",     timeString: "19:48", time: d(19, 48)),
            WidgetPrayer(kindRaw: "Isha",    name: "Ishaa",   iconName: "moon.fill",       timeString: "21:18", time: d(21, 18)),
        ]
        let next = prayers.first { $0.time > now } ?? prayers[3]
        return DeenEntry(
            date: now, cityName: "Berlin",
            nextPrayerName: next.name,
            nextPrayerDate: next.time,
            prayers: prayers,
            accentThemeRaw: "emerald_green"
        )
    }
}

// MARK: - Timeline Provider

struct DeenProvider: TimelineProvider {

    func placeholder(in context: Context) -> DeenEntry { .makePlaceholder() }

    func getSnapshot(in context: Context, completion: @escaping (DeenEntry) -> Void) {
        completion(buildCurrentEntry() ?? .makePlaceholder())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DeenEntry>) -> Void) {
        let now = Date()
        let city = loadCity() ?? "—"

        // If cached prayers exist AND are from today → use them directly.
        if let prayers = loadPrayers(), !arePrayersStale(prayers) {
            completion(buildTimeline(prayers: prayers, city: city, from: now))
            return
        }

        // Cached data is stale (previous day) or missing.
        // The widget fetches fresh prayer times directly from the DITIB API so
        // it never shows the wrong day, even when the main app hasn't run yet.
        if let districtId = loadDistrictId() {
            fetchFreshTimeline(districtId: districtId, city: city, now: now, completion: completion)
        } else {
            // No district ID yet — retry in 15 minutes.
            completion(Timeline(entries: [DeenEntry.makePlaceholder()],
                                policy: .after(now.addingTimeInterval(900))))
        }
    }

    // MARK: - Stale detection

    /// Returns true when every stored prayer's Date is before the start of today.
    private func arePrayersStale(_ prayers: [WidgetPrayer]) -> Bool {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return prayers.allSatisfy { $0.time < startOfToday }
    }

    // MARK: - Timeline construction

    private func buildTimeline(prayers: [WidgetPrayer], city: String, from now: Date) -> Timeline<DeenEntry> {
        var entries: [DeenEntry] = [makeEntry(at: now, prayers: prayers, city: city)]
        for prayer in prayers where prayer.time > now {
            entries.append(makeEntry(at: prayer.time, prayers: prayers, city: city))
        }
        let midnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 1),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(86_400)
        return Timeline(entries: entries, policy: .after(midnight))
    }

    private func makeEntry(at date: Date, prayers: [WidgetPrayer], city: String) -> DeenEntry {
        let accentRaw = loadAccentThemeRaw()
        if let next = prayers.first(where: { $0.time > date }) {
            return DeenEntry(date: date, cityName: city,
                             nextPrayerName: next.name, nextPrayerDate: next.time,
                             prayers: prayers, accentThemeRaw: accentRaw)
        }
        // All prayers passed — countdown to tomorrow's Imsak
        let first = prayers[0]
        let tomorrowFirst = Calendar.current.date(byAdding: .day, value: 1, to: first.time)
            ?? date.addingTimeInterval(3_600)
        return DeenEntry(date: date, cityName: city,
                         nextPrayerName: first.name, nextPrayerDate: tomorrowFirst,
                         prayers: prayers, accentThemeRaw: accentRaw)
    }

    // MARK: - DITIB self-fetch

    /// Fetches today's prayer times directly from the DITIB API when the
    /// App Group cache is stale.  Runs on a background URLSession thread and
    /// calls `completion` once — either with fresh data or a 15-min retry.
    private func fetchFreshTimeline(districtId: String, city: String, now: Date,
                                    completion: @escaping (Timeline<DeenEntry>) -> Void) {
        let urlString = "\(DeenWidgetConst.ditibBase)/prayer-times/\(districtId)/daily"
        guard let url = URL(string: urlString) else {
            completion(retryTimeline(after: 900))
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard
                let data,
                let response = try? JSONDecoder().decode(WDitibResponse.self, from: data),
                !response.data.isEmpty
            else {
                completion(self.retryTimeline(after: 900))
                return
            }
            // Pick today's entry
            let iso = DateFormatter()
            iso.locale = Locale(identifier: "en_US_POSIX")
            iso.dateFormat = "yyyy-MM-dd"
            let todayISO = iso.string(from: now)
            let todayData = response.data.first(where: { $0.date.hasPrefix(todayISO) })
                         ?? response.data.first!

            let prayers = Self.buildPrayers(from: todayData.times, referenceDate: now)
            completion(self.buildTimeline(prayers: prayers, city: city, from: now))
        }.resume()
    }

    private func retryTimeline(after seconds: TimeInterval) -> Timeline<DeenEntry> {
        Timeline(entries: [DeenEntry.makePlaceholder()],
                 policy: .after(Date().addingTimeInterval(seconds)))
    }

    /// Maps raw DITIB time strings to `WidgetPrayer` with today's `Date` values.
    private static func buildPrayers(from t: WDitibTimes, referenceDate: Date) -> [WidgetPrayer] {
        func d(_ hhmm: String) -> Date {
            let p = hhmm.split(separator: ":").compactMap { Int($0) }
            guard p.count >= 2 else { return referenceDate }
            return Calendar.current.date(bySettingHour: p[0], minute: p[1],
                                         second: 0, of: referenceDate) ?? referenceDate
        }
        return [
            WidgetPrayer(kindRaw: "Imsak",   name: "Fajr",    iconName: "moon.haze.fill",  timeString: t.imsak,  time: d(t.imsak)),
            WidgetPrayer(kindRaw: "Sunrise",  name: "Shuruuq", iconName: "sunrise.fill",    timeString: t.gunes,  time: d(t.gunes)),
            WidgetPrayer(kindRaw: "Dhuhr",   name: "Dhuhr",   iconName: "sun.max.fill",    timeString: t.ogle,   time: d(t.ogle)),
            WidgetPrayer(kindRaw: "Asr",     name: "Asr",     iconName: "cloud.sun.fill",  timeString: t.ikindi, time: d(t.ikindi)),
            WidgetPrayer(kindRaw: "Maghrib", name: "Maghrib", iconName: "sunset.fill",     timeString: t.aksam,  time: d(t.aksam)),
            WidgetPrayer(kindRaw: "Isha",    name: "Isha",    iconName: "moon.fill",       timeString: t.yatsi,  time: d(t.yatsi)),
        ]
    }

    // MARK: - App Group readers

    private func buildCurrentEntry() -> DeenEntry? {
        guard let prayers = loadPrayers(), let city = loadCity() else { return nil }
        return makeEntry(at: Date(), prayers: prayers, city: city)
    }

    private func loadPrayers() -> [WidgetPrayer]? {
        guard let defaults = UserDefaults(suiteName: DeenWidgetConst.suiteName),
              let data = defaults.data(forKey: DeenWidgetConst.todayPrayersKey) else { return nil }
        return try? JSONDecoder().decode([WidgetPrayer].self, from: data)
    }

    private func loadCity() -> String? {
        UserDefaults(suiteName: DeenWidgetConst.suiteName)?
            .string(forKey: DeenWidgetConst.cityKey)
            .flatMap { $0.isEmpty ? nil : $0 }
    }

    private func loadDistrictId() -> String? {
        UserDefaults(suiteName: DeenWidgetConst.suiteName)?
            .string(forKey: DeenWidgetConst.districtIdKey)
            .flatMap { $0.isEmpty ? nil : $0 }
    }

    private func loadAccentThemeRaw() -> String {
        UserDefaults(suiteName: DeenWidgetConst.suiteName)?
            .string(forKey: DeenWidgetConst.accentThemeKey) ?? "emerald_green"
    }
}

// MARK: - Small Widget View

private struct SmallWidgetView: View {
    let entry: DeenEntry

    private var nextPrayer: WidgetPrayer? {
        entry.prayers.first { $0.name == entry.nextPrayerName }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            // Icon — same SF Symbol as used in the medium prayer pills
            Image(systemName: nextPrayer?.iconName ?? "moon.stars.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(entry.accentColor)
                .widgetAccentable()

            Spacer().frame(height: 6)

            // Prayer name
            Text(entry.nextPrayerName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer().frame(height: 5)

            // Live countdown hh:mm:ss
            Text(entry.nextPrayerDate, style: .timer)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .foregroundStyle(entry.accentColor)
                .widgetAccentable()
                .multilineTextAlignment(.center)

            Spacer().frame(height: 4)

            // Exact prayer time hh:mm
            Text(nextPrayer?.timeString ?? "")
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.primary.opacity(0.5))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Prayer Pill (Medium Widget cell)

private struct PrayerPill: View {
    let prayer: WidgetPrayer
    let isNext: Bool
    let accentColor: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: prayer.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isNext ? accentColor : Color.primary.opacity(0.4))
                .widgetAccentable(isNext)

            Text(prayer.name)
                .font(.system(size: 9, weight: isNext ? .bold : .regular))
                .foregroundStyle(isNext ? Color.primary : Color.primary.opacity(0.5))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(prayer.timeString)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(isNext ? accentColor : Color.primary.opacity(0.65))
                .widgetAccentable(isNext)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 7)
        .background {
            if isNext {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor.opacity(0.17))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(accentColor.opacity(0.45), lineWidth: 0.75)
                    )
            }
        }
    }
}

// MARK: - Medium Widget View

private struct MediumWidgetView: View {
    let entry: DeenEntry

    // Shuruuq (Sunrise) is excluded from the medium widget pills — six pills
    // don't fit the medium canvas without becoming unreadably small.
    private var mediumPrayers: [WidgetPrayer] {
        entry.prayers.filter { $0.kindRaw != "Sunrise" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──────────────────────────────────────────────────────
            HStack(alignment: .center, spacing: 5) {
                // City — left side
                Image(systemName: "location.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(entry.accentColor)
                    .widgetAccentable()
                Text(entry.cityName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .layoutPriority(1)

                Spacer(minLength: 6)

                // "verbleibende Zeit bis [Gebet]:" inline left of timer
                HStack(alignment: .center, spacing: 4) {
                    Text("verbleibende Zeit bis \(entry.nextPrayerName):")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Color.primary.opacity(0.5))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.trailing)
                    Text(entry.nextPrayerDate, style: .timer)
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(entry.accentColor)
                        .widgetAccentable()
                        .layoutPriority(1)
                }
            }

            // ── Divider ─────────────────────────────────────────────────────
            Rectangle()
                .fill(entry.accentColor.opacity(0.22))
                .frame(height: 0.5)
                .padding(.vertical, 8)

            // ── Prayer pills (5 prayers, Shuruuq excluded) ───────────────────
            HStack(spacing: 0) {
                ForEach(mediumPrayers) { prayer in
                    PrayerPill(
                        prayer: prayer,
                        isNext: prayer.name == entry.nextPrayerName,
                        accentColor: entry.accentColor
                    )
                    if prayer.id != mediumPrayers.last?.id {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Large Widget Row

private struct LargePrayerRow: View {
    let prayer: WidgetPrayer
    let isNext: Bool
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: prayer.iconName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isNext ? accentColor : Color.primary.opacity(0.38))
                .frame(width: 26, alignment: .center)
                .widgetAccentable(isNext)

            Text(prayer.name)
                .font(.system(size: 16, weight: isNext ? .semibold : .regular))
                .foregroundStyle(isNext ? Color.primary : Color.primary.opacity(0.65))

            Spacer()

            Text(prayer.timeString)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(isNext ? accentColor : Color.primary.opacity(0.65))
                .widgetAccentable(isNext)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 8)
        .background {
            if isNext {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(accentColor.opacity(0.35), lineWidth: 0.75)
                    )
            }
        }
    }
}

// MARK: - Large Widget View

private struct LargeWidgetView: View {
    let entry: DeenEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──────────────────────────────────────────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(entry.accentColor)
                            .widgetAccentable()
                        Text(entry.cityName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    // Today's system date — formatted using the entry's calendar day
                    Text(entry.date, format: .dateTime.weekday(.wide).day().month(.wide).year())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                // "verbleibende Zeit bis [Gebet]:" inline left of timer
                HStack(alignment: .center, spacing: 5) {
                    Text("verbleibende Zeit bis \(entry.nextPrayerName):")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.primary.opacity(0.5))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.trailing)
                    Text(entry.nextPrayerDate, style: .timer)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(entry.accentColor)
                        .widgetAccentable()
                        .layoutPriority(1)
                }
            }

            // ── Divider ─────────────────────────────────────────────────────
            Rectangle()
                .fill(entry.accentColor.opacity(0.22))
                .frame(height: 0.5)
                .padding(.vertical, 10)

            // ── Prayer rows ──────────────────────────────────────────────────
            VStack(spacing: 0) {
                ForEach(entry.prayers) { prayer in
                    LargePrayerRow(
                        prayer: prayer,
                        isNext: prayer.name == entry.nextPrayerName,
                        accentColor: entry.accentColor
                    )
                    if prayer.id != entry.prayers.last?.id {
                        Rectangle()
                            .fill(Color.primary.opacity(0.07))
                            .frame(height: 0.5)
                            .padding(.horizontal, 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Entry View Router

struct DeenWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: DeenEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemLarge, .systemExtraLarge:
                // Both large sizes use the same full-list layout which naturally
                // includes Shuruuq via ForEach(entry.prayers).
                LargeWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            widgetBgColor
        }
    }

    private var widgetBgColor: Color {
        let uiAccent = UIColor(entry.accentColor)
        return computeWidgetBgColor(accentUIColor: uiAccent, colorScheme: colorScheme)
    }
}

// MARK: - Widget Definition

struct DeenWidget: Widget {
    let kind: String = "DeenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DeenProvider()) { entry in
            DeenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("Your daily prayer schedule at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    DeenWidget()
} timeline: {
    DeenEntry.makePlaceholder()
}

#Preview("Medium", as: .systemMedium) {
    DeenWidget()
} timeline: {
    DeenEntry.makePlaceholder()
}

#Preview("Large", as: .systemLarge) {
    DeenWidget()
} timeline: {
    DeenEntry.makePlaceholder()
}
