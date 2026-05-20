//
//  SharedPrayerData.swift
//  Shared between DailyDeen and DailyDeenWidget via App Groups.
//
//  Written by the main app after each API fetch (DITIB or Aladhan),
//  read by the widget's TimelineProvider for instant display.
//

import Foundation

// MARK: - Widget Prayer Entry
// Codable model for the 5 display prayers (excluding Sunrise).
// Encoded by the main app, decoded by the widget extension.
struct WidgetPrayerEntry: Codable {
    let kindRaw: String     // PrayerKind.rawValue
    let name: String        // Localised display name (e.g. "Akşam")
    let iconName: String    // SF Symbol identifier
    let timeString: String  // "HH:mm" string for display
    let time: Date          // Absolute Date for timer / next-prayer logic
}

struct SharedPrayerData: Codable {
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let dateString: String      // "yyyy-MM-dd"
    let timezone: String        // e.g. "Europe/Berlin"
    let cityName: String        // User's selected city / reverse-geocoded name
    let latitude: Double        // Coordinates used for the last fetch
    let longitude: Double
    let methodId: Int           // Aladhan method ID (13 = DITIB default)

    static let suiteName      = "group.d.DailyDee"
    static let key            = "widgetPrayerTimes"
    static let cityKey        = "widgetCityName"
    static let todayPrayersKey = "widgetTodayPrayers"

    // MARK: - Standalone Sync (readable by widget even without full prayer data)

    static func saveCity(_ name: String) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(name, forKey: cityKey)
        defaults.synchronize()
    }

    init(fajr: String, sunrise: String, dhuhr: String, asr: String,
         maghrib: String, isha: String, dateString: String, timezone: String,
         cityName: String = "Berlin",
         latitude: Double = 52.52, longitude: Double = 13.405,
         methodId: Int = 13) {
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
        self.dateString = dateString
        self.timezone = timezone
        self.cityName = cityName
        self.latitude = latitude
        self.longitude = longitude
        self.methodId = methodId
    }

    // Backward-compatible decoder — old cached data may lack newer fields
    enum CodingKeys: String, CodingKey {
        case fajr, sunrise, dhuhr, asr, maghrib, isha, dateString, timezone,
             cityName, latitude, longitude, methodId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        fajr       = try c.decode(String.self, forKey: .fajr)
        sunrise    = try c.decode(String.self, forKey: .sunrise)
        dhuhr      = try c.decode(String.self, forKey: .dhuhr)
        asr        = try c.decode(String.self, forKey: .asr)
        maghrib    = try c.decode(String.self, forKey: .maghrib)
        isha       = try c.decode(String.self, forKey: .isha)
        dateString = try c.decode(String.self, forKey: .dateString)
        timezone   = try c.decode(String.self, forKey: .timezone)
        cityName   = (try? c.decode(String.self, forKey: .cityName))  ?? "Berlin"
        latitude   = (try? c.decode(Double.self, forKey: .latitude))  ?? 52.52
        longitude  = (try? c.decode(Double.self, forKey: .longitude)) ?? 13.405
        methodId   = (try? c.decode(Int.self,    forKey: .methodId))  ?? 13
    }

    // MARK: - Persistence

    static func save(_ data: SharedPrayerData) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(try? JSONEncoder().encode(data), forKey: key)
        defaults.synchronize()
    }

    static func load() -> SharedPrayerData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let raw = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SharedPrayerData.self, from: raw)
    }

    // MARK: - Helpers

    var isToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return dateString == formatter.string(from: Date())
    }

    // MARK: - Today's 5 Display Prayers (widget-facing)

    /// Persist the 5 display prayers (Fajr/Dhuhr/Asr/Maghrib/Isha – no Sunrise)
    /// so the widget can decode them directly without reimplementing prayer logic.
    static func saveTodayPrayers(_ entries: [WidgetPrayerEntry]) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: todayPrayersKey)
        defaults.synchronize()
    }
}
