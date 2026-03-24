//
//  SharedPrayerData.swift
//  Shared between DailyDeen and DailyDeenWidget via App Groups.
//
//  Written by the main app after each API fetch (DITIB or Aladhan),
//  read by the widget's TimelineProvider for instant display.
//

import Foundation

struct SharedPrayerData: Codable {
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let dateString: String      // "yyyy-MM-dd"
    let timezone: String        // e.g. "Europe/Berlin"
    let cityName: String        // User's selected city for API fallback

    static let suiteName = "group.d.DailyDee"
    static let key = "widgetPrayerTimes"

    init(fajr: String, sunrise: String, dhuhr: String, asr: String,
         maghrib: String, isha: String, dateString: String, timezone: String,
         cityName: String = "Berlin") {
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
        self.dateString = dateString
        self.timezone = timezone
        self.cityName = cityName
    }

    // Backward-compatible decoder — old cached data may lack cityName
    enum CodingKeys: String, CodingKey {
        case fajr, sunrise, dhuhr, asr, maghrib, isha, dateString, timezone, cityName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        fajr      = try c.decode(String.self, forKey: .fajr)
        sunrise   = try c.decode(String.self, forKey: .sunrise)
        dhuhr     = try c.decode(String.self, forKey: .dhuhr)
        asr       = try c.decode(String.self, forKey: .asr)
        maghrib   = try c.decode(String.self, forKey: .maghrib)
        isha      = try c.decode(String.self, forKey: .isha)
        dateString = try c.decode(String.self, forKey: .dateString)
        timezone  = try c.decode(String.self, forKey: .timezone)
        cityName  = (try? c.decode(String.self, forKey: .cityName)) ?? "Berlin"
    }

    // MARK: - Persistence

    static func save(_ data: SharedPrayerData) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(try? JSONEncoder().encode(data), forKey: key)
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

    var allSlots: [(label: String, time: String, icon: String)] {
        [
            ("Fajr",    fajr,    "sunrise.fill"),
            ("Sunrise", sunrise, "sun.horizon.fill"),
            ("Dhuhr",   dhuhr,   "sun.max.fill"),
            ("Asr",     asr,     "cloud.sun.fill"),
            ("Maghrib", maghrib, "sunset.fill"),
            ("Isha",    isha,    "moon.stars.fill"),
        ]
    }

    func dateFrom(timeString: String) -> Date? {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        var cal = Calendar.current
        if let tz = TimeZone(identifier: timezone) { cal.timeZone = tz }
        return cal.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: Date())
    }

    func nextSlotIndex() -> Int? {
        let now = Date()
        let times = allSlots.map { dateFrom(timeString: $0.time) }
        return times.firstIndex(where: { ($0 ?? .distantPast) > now })
    }
}
