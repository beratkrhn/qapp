//
//  PrayerTrioWidgets.swift
//  AkhWidget
//
//  Two compact lock-screen widgets, each showing three prayer times in
//  a single `accessoryRectangular` block:
//   • MorningPrayersWidget — Fajr, Shuruuq, Dhuhr
//   • EveningPrayersWidget — Asr, Maghrib, Isha
//
//  Both read the same App Group cache populated by PrayerTimeManager.
//

import WidgetKit
import SwiftUI

// MARK: - Trio kinds

enum PrayerTrioKind {
    case morning   // Imsak (Fajr), Sunrise (Shuruuq), Dhuhr
    case evening   // Asr, Maghrib, Isha

    var kindRaws: [String] {
        switch self {
        case .morning: return ["Imsak", "Sunrise", "Dhuhr"]
        case .evening: return ["Asr", "Maghrib", "Isha"]
        }
    }

    var displayName: String {
        switch self {
        case .morning: return "Morgen-Gebete"
        case .evening: return "Abend-Gebete"
        }
    }

    var headerKey: String {
        switch self {
        case .morning: return "Morgen"
        case .evening: return "Abend"
        }
    }

    var headerIcon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .evening: return "sunset.fill"
        }
    }
}

// MARK: - Timeline Entry

struct TrioEntry: TimelineEntry {
    let date: Date
    let trio: [WidgetPrayer]       // exactly 3 prayers, ordered as listed in kindRaws
    let nextPrayerName: String     // name of the next prayer (may be outside trio)
    let accentThemeRaw: String
    let kind: PrayerTrioKind

    var accentColor: Color { WidgetTheme.accentColor(rawValue: accentThemeRaw) }
}

extension TrioEntry {
    static func makePlaceholder(kind: PrayerTrioKind) -> TrioEntry {
        let now = Date()
        let cal = Calendar.current
        let d = { (h: Int, m: Int) -> Date in
            cal.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now
        }
        let pool: [WidgetPrayer] = [
            WidgetPrayer(kindRaw: "Imsak",   name: "Fajr",    iconName: "moon.haze.fill",  timeString: "05:22", time: d(5, 22)),
            WidgetPrayer(kindRaw: "Sunrise", name: "Shuruuq", iconName: "sunrise.fill",    timeString: "06:54", time: d(6, 54)),
            WidgetPrayer(kindRaw: "Dhuhr",   name: "Dhuhr",   iconName: "sun.max.fill",    timeString: "13:08", time: d(13, 8)),
            WidgetPrayer(kindRaw: "Asr",     name: "Asr",     iconName: "cloud.sun.fill",  timeString: "16:45", time: d(16, 45)),
            WidgetPrayer(kindRaw: "Maghrib", name: "Maghrib", iconName: "sunset.fill",     timeString: "19:48", time: d(19, 48)),
            WidgetPrayer(kindRaw: "Isha",    name: "Isha",    iconName: "moon.fill",       timeString: "21:18", time: d(21, 18)),
        ]
        let trio = kind.kindRaws.compactMap { raw in pool.first(where: { $0.kindRaw == raw }) }
        let next = pool.first { $0.time > now } ?? pool[2]
        return TrioEntry(
            date: now,
            trio: trio,
            nextPrayerName: next.name,
            accentThemeRaw: "emerald_green",
            kind: kind
        )
    }
}

// MARK: - Timeline Provider

struct TrioProvider: TimelineProvider {
    let kind: PrayerTrioKind

    func placeholder(in context: Context) -> TrioEntry { .makePlaceholder(kind: kind) }

    func getSnapshot(in context: Context, completion: @escaping (TrioEntry) -> Void) {
        completion(buildCurrentEntry() ?? .makePlaceholder(kind: kind))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TrioEntry>) -> Void) {
        let now = Date()
        if let prayers = WidgetDataSource.loadPrayers(),
           !WidgetDataSource.arePrayersStale(prayers) {
            completion(buildTimeline(prayers: prayers, from: now))
            return
        }
        if let districtId = WidgetDataSource.loadDistrictId() {
            WidgetDitibFetcher.fetchTodayPrayers(districtId: districtId, referenceDate: now) { prayers in
                if let prayers {
                    completion(buildTimeline(prayers: prayers, from: now))
                } else {
                    completion(retryTimeline())
                }
            }
        } else {
            completion(retryTimeline())
        }
    }

    private func buildTimeline(prayers: [WidgetPrayer], from now: Date) -> Timeline<TrioEntry> {
        let midnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 1),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(86_400)

        var entries: [TrioEntry] = [makeEntry(at: now, prayers: prayers)]
        for prayer in prayers where prayer.time > now {
            entries.append(makeEntry(at: prayer.time, prayers: prayers))
        }
        return Timeline(entries: entries, policy: .after(midnight))
    }

    private func makeEntry(at date: Date, prayers: [WidgetPrayer]) -> TrioEntry {
        let accent = WidgetDataSource.loadAccentRaw()
        let trio: [WidgetPrayer] = kind.kindRaws.compactMap { raw in
            prayers.first(where: { $0.kindRaw == raw })
        }
        let nextName: String
        if let next = prayers.first(where: { $0.time > date }) {
            nextName = next.name
        } else {
            nextName = prayers.first?.name ?? ""
        }
        return TrioEntry(date: date, trio: trio,
                         nextPrayerName: nextName, accentThemeRaw: accent, kind: kind)
    }

    private func buildCurrentEntry() -> TrioEntry? {
        guard let prayers = WidgetDataSource.loadPrayers() else { return nil }
        return makeEntry(at: Date(), prayers: prayers)
    }

    private func retryTimeline() -> Timeline<TrioEntry> {
        Timeline(entries: [TrioEntry.makePlaceholder(kind: kind)],
                 policy: .after(Date().addingTimeInterval(900)))
    }
}

// MARK: - Lock-screen Rectangular

private struct TrioRectangularView: View {
    let entry: TrioEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(entry.trio) { prayer in
                HStack(spacing: 4) {
                    Text(prayer.name)
                        .font(.system(size: 12,
                                      weight: prayer.name == entry.nextPrayerName ? .bold : .regular,
                                      design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 4)
                    Text(prayer.timeString)
                        .font(.system(size: 13,
                                      weight: prayer.name == entry.nextPrayerName ? .bold : .semibold,
                                      design: .monospaced))
                        .widgetAccentable(prayer.name == entry.nextPrayerName)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Entry View Router

struct TrioWidgetEntryView: View {
    let entry: TrioEntry

    var body: some View {
        TrioRectangularView(entry: entry)
            .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Widget Definitions

struct MorningPrayersWidget: Widget {
    let kind: String = "MorningPrayersWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrioProvider(kind: .morning)) { entry in
            TrioWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Morgen-Gebete")
        .description("Fajr, Shuruuq und Dhuhr auf dem Sperrbildschirm.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct EveningPrayersWidget: Widget {
    let kind: String = "EveningPrayersWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrioProvider(kind: .evening)) { entry in
            TrioWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Abend-Gebete")
        .description("Asr, Maghrib und Isha auf dem Sperrbildschirm.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Previews

#Preview("Morgen · Rect", as: .accessoryRectangular) {
    MorningPrayersWidget()
} timeline: {
    TrioEntry.makePlaceholder(kind: .morning)
}

#Preview("Abend · Rect", as: .accessoryRectangular) {
    EveningPrayersWidget()
} timeline: {
    TrioEntry.makePlaceholder(kind: .evening)
}
