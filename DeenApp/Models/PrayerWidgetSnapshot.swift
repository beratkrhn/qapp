//
//  PrayerWidgetSnapshot.swift
//  DeenApp
//
//  Geteilte Daten für das Home-Screen-Widget (App Group).
//

import Foundation

enum AppGroupConfig {
    /// Muss mit der Capability „App Groups“ im Haupt-App- und Widget-Target übereinstimmen.
    static let identifier = "group.d.DailyDee"
    static let widgetSnapshotKey = "dailydee.widgetPrayerSnapshot_v1"
}

struct PrayerWidgetSnapshot: Codable, Equatable {
    struct Row: Codable, Equatable, Identifiable {
        var id: String { kindRaw + time }
        let kindRaw: String
        let time: String
        let iconSystemName: String
        let title: String
    }

    let savedAt: TimeInterval
    let rows: [Row]
}

enum PrayerWidgetStore {
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConfig.identifier)
    }

    static func save(_ snapshot: PrayerWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        sharedDefaults?.set(data, forKey: AppGroupConfig.widgetSnapshotKey)
    }

    static func load() -> PrayerWidgetSnapshot? {
        guard let data = sharedDefaults?.data(forKey: AppGroupConfig.widgetSnapshotKey) else { return nil }
        return try? JSONDecoder().decode(PrayerWidgetSnapshot.self, from: data)
    }
}
