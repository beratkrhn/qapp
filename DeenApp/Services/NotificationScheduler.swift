//
//  NotificationScheduler.swift
//  DeenApp
//
//  Schedules local notifications for each prayer time:
//  one at the prayer start and one configurable number of minutes before.
//

import UserNotifications
import Foundation

final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    static let enabledKey = "dailydee.notificationsEnabled"
    static let minutesBeforeKey = "dailydee.notificationMinutesBefore"
    static let allowedMinutes = [15, 30, 45, 60]

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.enabledKey) }
    }

    /// How many minutes before the prayer time the early notification fires.
    /// Defaults to 15 if never set.
    var minutesBeforePrayer: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: Self.minutesBeforeKey)
            return stored > 0 ? stored : 15
        }
        set { UserDefaults.standard.set(newValue, forKey: Self.minutesBeforeKey) }
    }

    // MARK: - Permission

    /// Requests authorization and returns whether it was granted.
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Returns the current authorization status without prompting.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Schedule

    /// Cancels all previously scheduled prayer notifications and schedules
    /// fresh ones for the given prayer times (at start + minutesBeforePrayer before each).
    /// Also schedules a Jumu'ah notification when the prayer day is a Friday.
    func schedulePrayerNotifications(for prayerTimes: [PrayerTime], cityName: String, language: AppLanguage) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: allNotificationIDs())

        let now = Date()
        let minutesBefore = minutesBeforePrayer
        for prayer in prayerTimes {
            // At prayer time
            if prayer.time > now {
                schedule(prayer: prayer, minutesBefore: 0, cityName: cityName, language: language)
            }
            // X minutes before
            if let earlyTime = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: prayer.time),
               earlyTime > now {
                schedule(prayer: prayer, minutesBefore: minutesBefore, cityName: cityName, language: language)
            }
        }

        // Jumu'ah: 60 min before Dhuhr on Fridays
        if let dhuhr = prayerTimes.first(where: { $0.kind == .dhuhr }) {
            let weekday = Calendar.current.component(.weekday, from: dhuhr.time)
            // weekday 6 = Friday in Gregorian calendar (1=Sun, 2=Mon, …, 6=Fri)
            if weekday == 6, let jumuahTime = Calendar.current.date(byAdding: .minute, value: -60, to: dhuhr.time),
               jumuahTime > now {
                scheduleJumuah(at: jumuahTime, language: language)
            }
        }
    }

    /// Cancels all pending prayer notifications.
    func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allNotificationIDs())
    }

    // MARK: - Private

    private func schedule(prayer: PrayerTime, minutesBefore: Int, cityName: String, language: AppLanguage) {
        let content = UNMutableNotificationContent()
        let prayerName = prayer.kind.localizedName(for: language)

        if minutesBefore == 0 {
            content.title = prayerName
            // Use the per-prayer hadith quote as body; fall back to default for Shuruuq
            let quote = L10n.notificationPrayerQuote(prayer.kind, language)
            content.body = (quote ?? L10n.notificationAtPrayer(language)) + " · " + cityName
        } else {
            content.title = L10n.notificationBefore(language, prayerName: prayerName, minutes: minutesBefore)
            content.body = L10n.notificationGetReady(language) + " · " + cityName
        }
        content.sound = .default

        let triggerDate = minutesBefore == 0
            ? prayer.time
            : Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: prayer.time)!

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationID(kind: prayer.kind, minutesBefore: minutesBefore),
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleJumuah(at triggerDate: Date, language: AppLanguage) {
        let content = UNMutableNotificationContent()
        content.title = L10n.notificationJumuahTitle(language)
        content.body = L10n.notificationJumuahBody(language)
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "prayer_jumuah_60min",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func notificationID(kind: PrayerKind, minutesBefore: Int) -> String {
        "prayer_\(kind.rawValue)_\(minutesBefore)min"
    }

    private func allNotificationIDs() -> [String] {
        // Include 0 + all allowed early-notification values so switching intervals
        // always cancels the previously scheduled set.
        let allMinutes = [0] + Self.allowedMinutes
        var ids = PrayerKind.allCases.flatMap { kind in
            allMinutes.map { notificationID(kind: kind, minutesBefore: $0) }
        }
        ids.append("prayer_jumuah_60min")
        return ids
    }
}
