//
//  PrayerTime.swift
//  DeenApp
//

import Foundation

struct PrayerTime: Identifiable, Equatable {
    let id: PrayerKind
    let kind: PrayerKind
    let time: Date
    let timeString: String // "05:22" für Anzeige

    init(kind: PrayerKind, time: Date) {
        self.id = kind
        self.kind = kind
        self.time = time
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        self.timeString = formatter.string(from: time)
    }

    init(kind: PrayerKind, timeString: String, referenceDate: Date) {
        self.id = kind
        self.kind = kind
        self.timeString = timeString
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        let hour = components.first ?? 0
        let minute = components.count > 1 ? components[1] : 0
        self.time = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: referenceDate) ?? referenceDate
    }
}
