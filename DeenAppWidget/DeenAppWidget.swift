//
//  DeenAppWidget.swift
//  DailyDeen Widget
//
//  Two distinct widget configurations sharing the same PrayerTimesProvider:
//    • Overview — All prayer times + live countdown  (.systemMedium / .systemLarge)
//    • Timer   — Minimal next-prayer countdown       (.systemSmall / accessory families)
//

import WidgetKit
import SwiftUI

// MARK: - Widget A: Full Overview

struct DailyDeenOverviewWidget: Widget {
    let kind = "DailyDeenOverview_v2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            OverviewWidgetView(entry: entry)
        }
        .configurationDisplayName("DailyDeen – Gebetszeiten")
        .description("Alle Gebetszeiten mit Live-Countdown.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Widget B: Minimal Timer

struct DailyDeenTimerWidget: Widget {
    let kind = "DailyDeenTimer"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            TimerWidgetView(entry: entry)
        }
        .configurationDisplayName("DailyDeen – Timer")
        .description("Live-Countdown zum nächsten Gebet.")
        .supportedFamilies([
            .systemSmall,
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCircular,
        ])
    }
}

// MARK: - Previews

#Preview("Overview Medium", as: .systemMedium) {
    DailyDeenOverviewWidget()
} timeline: {
    PrayerTimesEntry.placeholder
}

#Preview("Overview Large", as: .systemLarge) {
    DailyDeenOverviewWidget()
} timeline: {
    PrayerTimesEntry.placeholder
}

#Preview("Timer Small", as: .systemSmall) {
    DailyDeenTimerWidget()
} timeline: {
    PrayerTimesEntry.placeholder
}

#Preview("Timer Rectangular", as: .accessoryRectangular) {
    DailyDeenTimerWidget()
} timeline: {
    PrayerTimesEntry.placeholder
}

#Preview("Timer Inline", as: .accessoryInline) {
    DailyDeenTimerWidget()
} timeline: {
    PrayerTimesEntry.placeholder
}

#Preview("Timer Circular", as: .accessoryCircular) {
    DailyDeenTimerWidget()
} timeline: {
    PrayerTimesEntry.placeholder
}
