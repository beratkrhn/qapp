//
//  HifzNotificationScheduler.swift
//  DeenApp
//
//  Plant lokale Wiederholungs-Benachrichtigungen für gelernte Hifz-Abschnitte.
//  Mehrere am selben Tag fällige Suren werden in **eine** Notification gebündelt
//  (max. 1 Reminder pro Kalendertag); vorgeplant werden bis zu 14 zukünftige
//  Fälligkeitstage, damit die Reminder auch dann weiterlaufen, wenn die App
//  einige Tage nicht geöffnet wird (iOS-Limit: 64 pending Notifications).
//

import Foundation
import UserNotifications

final class HifzNotificationScheduler {
    static let shared = HifzNotificationScheduler()
    private init() {}

    private static let notificationPrefix = "hifz_revision_"

    /// Wie viele zukünftige Fälligkeitstage maximal vorgeplant werden
    /// (1 gebündelte Notification pro Tag).
    private static let maxScheduledDays = 14

    /// Uhrzeit (Stunde, Minute), zu der die täglichen Hifz-Reminder feuern.
    private static let reminderHour = 10
    private static let reminderMinute = 0

    /// Wie viele Suren-Namen maximal im Body aufgezählt werden, bevor abgekürzt
    /// wird (Rest als "und N weitere").
    private static let maxNamesInBody = 4

    /// Fragt die Notification-Berechtigung an, falls noch nicht entschieden.
    /// Liefert true, wenn (jetzt oder bereits zuvor) erteilt.
    func requestPermissionIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    /// Plant Erinnerungen für die gesamte Sammlung: alle alten Hifz-Notifications
    /// werden entfernt, dann pro Fälligkeitstag eine gebündelte Reminder-Notification
    /// eingeplant — bis zu `maxScheduledDays` Tage im Voraus.
    func rescheduleAll(_ entries: [HifzEntry], language: AppLanguage) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            let toRemove = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(Self.notificationPrefix) }
            if !toRemove.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: toRemove)
            }
            self.scheduleBatched(entries, language: language)
        }
    }

    /// Entfernt alle Hifz-Reminder (z. B. bei Löschen des letzten Eintrags).
    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(Self.notificationPrefix) }
            if !ids.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: ids)
            }
        }
    }

    // MARK: - Batching

    private func scheduleBatched(_ entries: [HifzEntry], language: AppLanguage) {
        guard !entries.isEmpty else { return }
        let calendar = Calendar.current
        let now = Date()

        // Gruppiere fällige Einträge nach Start-of-Day des `nextRevisionDue`.
        var byDay: [Date: [HifzEntry]] = [:]
        for entry in entries {
            let due = entry.nextRevisionDue
            let day = calendar.startOfDay(for: due)
            byDay[day, default: []].append(entry)
        }

        // Sortiere die Tage chronologisch, nimm nur zukünftige Tage,
        // und kappe auf maxScheduledDays.
        let sortedDays = byDay.keys.sorted()
        var scheduledCount = 0

        for day in sortedDays {
            guard scheduledCount < Self.maxScheduledDays else { break }
            guard let triggerDate = reminderDate(on: day),
                  triggerDate > now else { continue }
            let dayEntries = byDay[day] ?? []
            guard !dayEntries.isEmpty else { continue }
            scheduleDay(triggerDate: triggerDate, entries: dayEntries, language: language)
            scheduledCount += 1
        }
    }

    private func reminderDate(on day: Date) -> Date? {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
        comps.hour = Self.reminderHour
        comps.minute = Self.reminderMinute
        return Calendar.current.date(from: comps)
    }

    private func scheduleDay(triggerDate: Date, entries: [HifzEntry], language: AppLanguage) {
        let content = UNMutableNotificationContent()
        content.title = L10n.hifzNotificationTitle(language)
        content.body = batchedBody(for: entries, language: language)
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let id = Self.notificationPrefix + "\(Int(triggerDate.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func batchedBody(for entries: [HifzEntry], language: AppLanguage) -> String {
        let names = entries.map(\.surahTransliteration)
        if names.count == 1 {
            return L10n.hifzNotificationBody(language, surahName: names[0])
        }
        let shown = Array(names.prefix(Self.maxNamesInBody))
        let remainder = names.count - shown.count
        let list = shown.joined(separator: ", ")
        return L10n.hifzNotificationBodyMulti(
            language,
            count: names.count,
            namesList: list,
            remainder: remainder
        )
    }
}
