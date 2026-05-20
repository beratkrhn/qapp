//
//  WatchPrayerPayload.swift
//
//  Shared between the iPhone app and the watchOS app/widget. Sent via
//  WCSession.updateApplicationContext after each prayer-time refresh
//  on the phone; persisted into the watch's own UserDefaults so the
//  widget can build its timeline offline.
//
//  Target membership: DailyDee, AkhWatch, AkhWatchWidget.
//

import Foundation

public struct WatchPrayer: Codable, Identifiable, Hashable {
    public var id: String { kindRaw }
    public let kindRaw: String     // PrayerKind.rawValue (Imsak / Sunrise / Dhuhr / …)
    public let name: String        // Localised display name
    public let iconName: String    // SF Symbol
    public let timeString: String  // "HH:mm"
    public let time: Date

    public init(kindRaw: String, name: String, iconName: String,
                timeString: String, time: Date) {
        self.kindRaw = kindRaw
        self.name = name
        self.iconName = iconName
        self.timeString = timeString
        self.time = time
    }
}

public struct WatchPrayerPayload: Codable {
    public let cityName: String
    public let accentThemeRaw: String   // e.g. "emerald_green"
    public let prayers: [WatchPrayer]
    public let issuedAt: Date

    public init(cityName: String, accentThemeRaw: String,
                prayers: [WatchPrayer], issuedAt: Date = Date()) {
        self.cityName = cityName
        self.accentThemeRaw = accentThemeRaw
        self.prayers = prayers
        self.issuedAt = issuedAt
    }

    // MARK: - Watch-side persistence

    /// App Group shared by the watch app and the watch widget extension.
    /// Different from the iOS App Group — watchOS has its own sandbox.
    public static let watchSuiteName = "group.d.DailyDee.watch"
    public static let storageKey     = "akhira.watch.prayerPayload"

    /// Dictionary representation suited for WCSession.updateApplicationContext.
    public func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        return ["payload": data]
    }

    public static func decode(from context: [String: Any]) -> WatchPrayerPayload? {
        guard let data = context["payload"] as? Data else { return nil }
        return try? JSONDecoder().decode(WatchPrayerPayload.self, from: data)
    }

    /// Read the most recently stored payload. Safe to call from the
    /// widget extension — falls back to `UserDefaults.standard` when no
    /// App Group is configured (early development).
    public static func loadFromDisk() -> WatchPrayerPayload? {
        let defaults = UserDefaults(suiteName: watchSuiteName) ?? .standard
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(WatchPrayerPayload.self, from: data)
    }

    /// Persist to the watch-side App Group so the widget extension can read it.
    public func saveToDisk() {
        let defaults = UserDefaults(suiteName: Self.watchSuiteName) ?? .standard
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
