//
//  PrayerTimesEntry.swift
//  DailyDeen Widget
//

import WidgetKit

struct PrayerSlot: Identifiable {
    let id: Int
    let label: String
    let time: String
    let icon: String
    let isNext: Bool
}

struct PrayerTimesEntry: TimelineEntry {
    let date: Date
    let slots: [PrayerSlot]
    let dayLabel: String
    let cityName: String
    let isPlaceholder: Bool
    let nextPrayerDate: Date?

    var nextSlot: PrayerSlot? {
        slots.first { $0.isNext }
    }

    var upcomingSlots: [PrayerSlot] {
        if let idx = slots.firstIndex(where: { $0.isNext }) {
            return Array(slots[idx...].prefix(3))
        }
        return Array(slots.prefix(3))
    }

    static let placeholder = PrayerTimesEntry(
        date: .now,
        slots: [
            PrayerSlot(id: 0, label: "İmsak",   time: "05:22", icon: "moon.haze.fill",   isNext: false),
            PrayerSlot(id: 1, label: "Güneş",   time: "06:51", icon: "sunrise.fill",     isNext: false),
            PrayerSlot(id: 2, label: "Dhuhr",   time: "12:45", icon: "sun.max.fill",     isNext: true),
            PrayerSlot(id: 3, label: "Asr",     time: "16:30", icon: "cloud.sun.fill",   isNext: false),
            PrayerSlot(id: 4, label: "Maghrib", time: "19:45", icon: "sunset.fill",      isNext: false),
            PrayerSlot(id: 5, label: "Isha",    time: "21:15", icon: "moon.stars.fill",  isNext: false),
        ],
        dayLabel: "24 March",
        cityName: "Error!",
        isPlaceholder: true,
        nextPrayerDate: Calendar.current.date(byAdding: .hour, value: 2, to: .now)
    )
}
