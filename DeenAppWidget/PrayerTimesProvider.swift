//
//  PrayerTimesProvider.swift
//  DailyDeen Widget
//
//  Reads cached SharedPrayerData written exclusively by the main app (DITIB).
//  NO fallback APIs. NO cache overwriting.
//

import WidgetKit
import Foundation

struct PrayerTimesProvider: TimelineProvider {

    // MARK: - Protocol

    func placeholder(in context: Context) -> PrayerTimesEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimesEntry) -> Void) {
        if let data = SharedPrayerData.load() {
            completion(makeEntry(from: data, at: .now))
        } else {
            completion(.placeholder)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimesEntry>) -> Void) {
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        )

        if let data = SharedPrayerData.load() {
            let baseEntry = makeEntry(from: data, at: .now)
            let entries = timelineEntries(from: baseEntry, using: data)
            completion(Timeline(entries: entries, policy: .after(midnight)))
        } else {
            // Wenn kein Cache da ist, zeige den Placeholder.
            // Die Haupt-App zwingt das Widget zum Reload, sobald sie geöffnet wird.
            completion(Timeline(entries: [.placeholder], policy: .after(midnight)))
        }
    }

    // MARK: - Entry Building

    private func makeEntry(from data: SharedPrayerData, at date: Date) -> PrayerTimesEntry {
        let nextIndex = data.nextSlotIndex()
        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "d MMMM"

        let slots = data.allSlots.enumerated().map { i, s in
            PrayerSlot(id: i, label: s.label, time: s.time, icon: s.icon, isNext: i == nextIndex)
        }

        let nextPrayerDate: Date? = nextIndex.flatMap {
            data.dateFrom(timeString: data.allSlots[$0].time)
        }

        // Always prefer the standalone city key (updated instantly by the main app)
        let resolvedCity = SharedPrayerData.loadCity() ?? data.cityName

        return PrayerTimesEntry(
            date: date,
            slots: slots,          
            dayLabel: dayFmt.string(from: .now),
            cityName: resolvedCity,
            isPlaceholder: false,
            nextPrayerDate: nextPrayerDate
        )
    }

    /// One entry per remaining prayer so the "next" indicator auto-advances.
    private func timelineEntries(from base: PrayerTimesEntry, using data: SharedPrayerData) -> [PrayerTimesEntry] {
        var entries = [base]

        for slot in data.allSlots {
            if let prayerDate = data.dateFrom(timeString: slot.time), prayerDate > .now {
                entries.append(makeEntry(from: data, at: prayerDate))
            }
        }
        return entries
    }
}
