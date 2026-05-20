//
//  CountdownWidget.swift
//  AkhWidget
//
//  Lock-screen accessory widget that shows nothing but a live countdown
//  to the next prayer. Supports the three lock-screen families:
//   • accessoryRectangular — name + live timer + exact time
//   • accessoryCircular    — live timer inside the ring
//   • accessoryInline      — single line above the clock
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct CountdownEntry: TimelineEntry {
    let date: Date
    let nextName: String
    let nextDate: Date
    let nextTimeString: String
    let nextIcon: String
    let accentThemeRaw: String

    var accentColor: Color { WidgetTheme.accentColor(rawValue: accentThemeRaw) }

    static func makePlaceholder() -> CountdownEntry {
        let now = Date()
        let next = Calendar.current.date(byAdding: .minute, value: 73, to: now) ?? now
        return CountdownEntry(
            date: now,
            nextName: "Dhuhr",
            nextDate: next,
            nextTimeString: "13:08",
            nextIcon: "sun.max.fill",
            accentThemeRaw: "emerald_green"
        )
    }
}

// MARK: - Timeline Provider

struct CountdownProvider: TimelineProvider {

    func placeholder(in context: Context) -> CountdownEntry { .makePlaceholder() }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        completion(buildCurrentEntry() ?? .makePlaceholder())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
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

    private func buildTimeline(prayers: [WidgetPrayer], from now: Date) -> Timeline<CountdownEntry> {
        let midnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 1),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(86_400)

        var entries: [CountdownEntry] = [makeEntry(at: now, prayers: prayers)]
        for prayer in prayers where prayer.time > now {
            entries.append(makeEntry(at: prayer.time, prayers: prayers))
        }
        return Timeline(entries: entries, policy: .after(midnight))
    }

    private func makeEntry(at date: Date, prayers: [WidgetPrayer]) -> CountdownEntry {
        let accent = WidgetDataSource.loadAccentRaw()
        if let next = prayers.first(where: { $0.time > date }) {
            return CountdownEntry(
                date: date,
                nextName: next.name,
                nextDate: next.time,
                nextTimeString: next.timeString,
                nextIcon: next.iconName,
                accentThemeRaw: accent
            )
        }
        let first = prayers[0]
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: first.time)
            ?? date.addingTimeInterval(3_600)
        return CountdownEntry(
            date: date,
            nextName: first.name,
            nextDate: tomorrow,
            nextTimeString: first.timeString,
            nextIcon: first.iconName,
            accentThemeRaw: accent
        )
    }

    private func buildCurrentEntry() -> CountdownEntry? {
        guard let prayers = WidgetDataSource.loadPrayers() else { return nil }
        return makeEntry(at: Date(), prayers: prayers)
    }

    private func retryTimeline() -> Timeline<CountdownEntry> {
        Timeline(entries: [CountdownEntry.makePlaceholder()],
                 policy: .after(Date().addingTimeInterval(900)))
    }
}

// MARK: - Lock-screen Rectangular

private struct CountdownRectangularView: View {
    let entry: CountdownEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: entry.nextIcon)
                    .font(.system(size: 11, weight: .semibold))
                    .widgetAccentable()
                Text(entry.nextName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(entry.nextTimeString)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Text(entry.nextDate, style: .timer)
                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                .widgetAccentable()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Lock-screen Circular

private struct CountdownCircularView: View {
    let entry: CountdownEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: entry.nextIcon)
                    .font(.system(size: 10, weight: .semibold))
                    .widgetAccentable()
                Text(entry.nextDate, style: .timer)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .widgetAccentable()
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .padding(2)
        }
    }
}

// MARK: - Lock-screen Inline

private struct CountdownInlineView: View {
    let entry: CountdownEntry

    var body: some View {
        // Inline lock-screen widgets render as a single line above the clock —
        // mix prayer name with the live timer.
        HStack(spacing: 4) {
            Image(systemName: entry.nextIcon)
            Text(entry.nextName)
            Text(entry.nextDate, style: .timer)
        }
    }
}

// MARK: - Entry View Router

struct CountdownWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountdownEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:    CountdownCircularView(entry: entry)
            case .accessoryInline:      CountdownInlineView(entry: entry)
            default:                    CountdownRectangularView(entry: entry)
            }
        }
        // Lock-screen accessory widgets must use the system vibrancy — no
        // custom background. Matches the existing rectangular widget pattern.
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Widget Definition

struct CountdownWidget: Widget {
    let kind: String = "CountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownProvider()) { entry in
            CountdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Gebets-Countdown")
        .description("Live-Countdown bis zum nächsten Gebet auf dem Sperrbildschirm.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

// MARK: - Previews

#Preview("Countdown · Rect", as: .accessoryRectangular) {
    CountdownWidget()
} timeline: {
    CountdownEntry.makePlaceholder()
}

#Preview("Countdown · Circ", as: .accessoryCircular) {
    CountdownWidget()
} timeline: {
    CountdownEntry.makePlaceholder()
}

#Preview("Countdown · Inline", as: .accessoryInline) {
    CountdownWidget()
} timeline: {
    CountdownEntry.makePlaceholder()
}
