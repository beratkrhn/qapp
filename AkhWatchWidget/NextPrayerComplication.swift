//
//  NextPrayerComplication.swift
//  AkhWatchWidget
//
//  accessoryRectangular complication showing the next prayer name,
//  a live countdown, and the time it begins. Data is read from the
//  watch's UserDefaults.standard, populated by WatchSessionReceiver
//  in the host app whenever the iPhone sends a payload.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct NextPrayerEntry: TimelineEntry {
    let date: Date
    let cityName: String
    let nextPrayer: WatchPrayer?
    let accentRaw: String

    static func placeholder() -> NextPrayerEntry {
        let now = Date()
        let in30 = now.addingTimeInterval(30 * 60)
        return NextPrayerEntry(
            date: now,
            cityName: "Berlin",
            nextPrayer: WatchPrayer(
                kindRaw: "Dhuhr",
                name: "Dhuhr",
                iconName: "sun.max.fill",
                timeString: shortTime(in30),
                time: in30
            ),
            accentRaw: "emerald_green"
        )
    }

    private static func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Provider

struct NextPrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextPrayerEntry { .placeholder() }

    func getSnapshot(in context: Context, completion: @escaping (NextPrayerEntry) -> Void) {
        completion(currentEntry() ?? .placeholder())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextPrayerEntry>) -> Void) {
        let now = Date()
        guard let payload = WatchPrayerPayload.loadFromDisk() else {
            // Retry in 15 min — payload may arrive once the user opens the app.
            completion(Timeline(entries: [.placeholder()],
                                policy: .after(now.addingTimeInterval(900))))
            return
        }

        // One entry per upcoming prayer transition, so the displayed name
        // rolls over without needing a WCSession round-trip.
        let upcoming = payload.prayers.filter { $0.time > now }
        var entries: [NextPrayerEntry] = [makeEntry(at: now, payload: payload)]
        for p in upcoming {
            entries.append(makeEntry(at: p.time, payload: payload))
        }

        let endOfDay = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 5),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(86_400)

        completion(Timeline(entries: entries, policy: .after(endOfDay)))
    }

    private func makeEntry(at date: Date, payload: WatchPrayerPayload) -> NextPrayerEntry {
        let next = payload.prayers.first { $0.time > date } ?? payload.prayers.first
        return NextPrayerEntry(
            date: date,
            cityName: payload.cityName,
            nextPrayer: next,
            accentRaw: payload.accentThemeRaw
        )
    }

    private func currentEntry() -> NextPrayerEntry? {
        guard let payload = WatchPrayerPayload.loadFromDisk() else { return nil }
        return makeEntry(at: Date(), payload: payload)
    }
}

// MARK: - View

struct NextPrayerComplicationView: View {
    let entry: NextPrayerEntry

    var body: some View {
        let accent = WatchAccent.color(for: entry.accentRaw)
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: entry.nextPrayer?.iconName ?? "moon.stars.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                    .widgetAccentable()
                Text(entry.nextPrayer?.name ?? "—")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(entry.cityName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let time = entry.nextPrayer?.time {
                Text(time, style: .timer)
                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(accent)
                    .widgetAccentable()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Text("--:--")
                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
            }
            Text("Beginnt um \(entry.nextPrayer?.timeString ?? "--:--")")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Widget

struct NextPrayerComplication: Widget {
    let kind = "NextPrayerComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextPrayerProvider()) { entry in
            NextPrayerComplicationView(entry: entry)
        }
        .configurationDisplayName("Nächstes Gebet")
        .description("Zeigt das nächste Gebet und den Countdown.")
        .supportedFamilies([.accessoryRectangular,
                            .accessoryCircular,
                            .accessoryInline])
    }
}

#Preview(as: .accessoryRectangular) {
    NextPrayerComplication()
} timeline: {
    NextPrayerEntry.placeholder()
}
