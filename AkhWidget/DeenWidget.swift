//
//  DeenWidget.swift
//  AkhWidget
//
//  Prayer-times home-screen widget for DailyDeen.
//  Reads data written by PrayerTimeManager via the shared App Group
//  "group.d.DailyDee" — always in sync with the main app.
//

import WidgetKit
import SwiftUI

// MARK: - Constants

private enum DeenWidgetConst {
    static let suiteName       = "group.d.DailyDee"
    static let todayPrayersKey = "widgetTodayPrayers"
    static let cityKey         = "widgetCityName"
    static let bgColor         = Color(red: 0.04, green: 0.10, blue: 0.04)
    static let accent          = Color(red: 0.18, green: 0.82, blue: 0.32)
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
}

extension DeenEntry {
    static func makePlaceholder() -> DeenEntry {
        let now = Date()
        let cal = Calendar.current
        let d = { (h: Int, m: Int) -> Date in
            cal.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now
        }
        let prayers: [WidgetPrayer] = [
            WidgetPrayer(kindRaw: "Imsak",   name: "İmsak",  iconName: "moon.haze.fill",  timeString: "05:22", time: d(5,  22)),
            WidgetPrayer(kindRaw: "Dhuhr",   name: "Öğle",   iconName: "sun.max.fill",    timeString: "13:08", time: d(13,  8)),
            WidgetPrayer(kindRaw: "Asr",     name: "İkindi", iconName: "cloud.sun.fill",  timeString: "16:45", time: d(16, 45)),
            WidgetPrayer(kindRaw: "Maghrib", name: "Akşam",  iconName: "sunset.fill",     timeString: "19:48", time: d(19, 48)),
            WidgetPrayer(kindRaw: "Isha",    name: "Yatsı",  iconName: "moon.fill",       timeString: "21:18", time: d(21, 18)),
        ]
        let next = prayers.first { $0.time > now } ?? prayers[3]
        return DeenEntry(
            date: now, cityName: "Berlin",
            nextPrayerName: next.name,
            nextPrayerDate: next.time,
            prayers: prayers
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
        guard let prayers = loadPrayers(), let city = loadCity() else {
            // No shared data yet — retry in an hour
            let timeline = Timeline(entries: [DeenEntry.makePlaceholder()],
                                    policy: .after(Date().addingTimeInterval(3600)))
            completion(timeline)
            return
        }

        let now = Date()
        var entries: [DeenEntry] = []

        // Entry for the current moment
        entries.append(makeEntry(at: now, prayers: prayers, city: city))

        // One transition entry per future prayer:
        // at prayer.time the "next prayer" advances to the following one.
        for prayer in prayers where prayer.time > now {
            entries.append(makeEntry(at: prayer.time, prayers: prayers, city: city))
        }

        // Reload at 00:05 tomorrow to pull fresh data from the main app cache.
        let tomorrowRefresh = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(86_400)

        let timeline = Timeline(entries: entries, policy: .after(tomorrowRefresh))
        completion(timeline)
    }

    // MARK: Private helpers

    private func makeEntry(at date: Date, prayers: [WidgetPrayer], city: String) -> DeenEntry {
        if let next = prayers.first(where: { $0.time > date }) {
            return DeenEntry(date: date, cityName: city,
                             nextPrayerName: next.name, nextPrayerDate: next.time,
                             prayers: prayers)
        }
        // All prayers have passed — point to tomorrow's first (İmsak)
        let first = prayers[0]
        let tomorrowFirst = Calendar.current.date(byAdding: .day, value: 1, to: first.time)
            ?? date.addingTimeInterval(3_600)
        return DeenEntry(date: date, cityName: city,
                         nextPrayerName: first.name, nextPrayerDate: tomorrowFirst,
                         prayers: prayers)
    }

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
    }
}

// MARK: - Small Widget View

private struct SmallWidgetView: View {
    let entry: DeenEntry

    private var icon: String {
        entry.prayers.first { $0.name == entry.nextPrayerName }?.iconName
            ?? "moon.stars.fill"
    }

    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(DeenWidgetConst.accent)

            Text(entry.nextPrayerName)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(entry.nextPrayerDate, style: .timer)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(DeenWidgetConst.accent)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Prayer Pill (Medium Widget cell)

private struct PrayerPill: View {
    let prayer: WidgetPrayer
    let isNext: Bool

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: prayer.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isNext ? DeenWidgetConst.accent : Color.white.opacity(0.4))

            Text(prayer.name)
                .font(.system(size: 9, weight: isNext ? .bold : .regular))
                .foregroundStyle(isNext ? .white : Color.white.opacity(0.5))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(prayer.timeString)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(isNext ? DeenWidgetConst.accent : Color.white.opacity(0.65))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 7)
        .background {
            if isNext {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(DeenWidgetConst.accent.opacity(0.17))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(DeenWidgetConst.accent.opacity(0.45), lineWidth: 0.75)
                    )
            }
        }
    }
}

// MARK: - Medium Widget View

private struct MediumWidgetView: View {
    let entry: DeenEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──────────────────────────────────────────────────────
            HStack(alignment: .center) {
                // City
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DeenWidgetConst.accent.opacity(0.8))
                    Text(entry.cityName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                // Next prayer countdown
                VStack(alignment: .trailing, spacing: 1) {
                    Text(entry.nextPrayerName)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                    Text(entry.nextPrayerDate, style: .timer)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(DeenWidgetConst.accent)
                        .frame(minWidth: 62, alignment: .trailing)
                }
            }

            // ── Divider ─────────────────────────────────────────────────────
            Rectangle()
                .fill(DeenWidgetConst.accent.opacity(0.22))
                .frame(height: 0.5)
                .padding(.vertical, 8)

            // ── Prayer pills ─────────────────────────────────────────────────
            HStack(spacing: 0) {
                ForEach(entry.prayers) { prayer in
                    PrayerPill(
                        prayer: prayer,
                        isNext: prayer.name == entry.nextPrayerName
                    )
                    if prayer.id != entry.prayers.last?.id {
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

// MARK: - Entry View Router

struct DeenWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DeenEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct DeenWidget: Widget {
    let kind: String = "DeenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DeenProvider()) { entry in
            DeenWidgetEntryView(entry: entry)
                .containerBackground(DeenWidgetConst.bgColor, for: .widget)
        }
        .configurationDisplayName("Prayer Times")
        .description("Your daily prayer schedule at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
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
