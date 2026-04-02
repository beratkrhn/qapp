//
//  PrayerTimeManager.swift
//  DeenApp
//
//  Lädt Gebetszeiten ausschließlich via DITIB/Diyanet API.
//  Aladhan API und CoreLocation wurden vollständig entfernt.
//

import Foundation
import Combine
import WidgetKit
import UIKit

@MainActor
final class PrayerTimeManager: ObservableObject {

    // MARK: - Published

    @Published private(set) var prayerTimes: [PrayerTime] = []
    @Published private(set) var nextPrayer: PrayerTime?
    @Published private(set) var countdownString: String = "--:--:--"
    @Published private(set) var timezoneIdentifier: String = "Europe/Berlin"
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    /// Always reflects the current calendar day; updates automatically at midnight.
    @Published private(set) var currentDate: Date = Date()

    // MARK: - Private

    private var lastLoadedCityName = ""
    private var midnightTimer: Timer?
    private var significantTimeObserver: (any NSObjectProtocol)?
    private var foregroundObserver: (any NSObjectProtocol)?

    // MARK: - Init

    init() {
        if let cached = SharedPrayerData.load(), cached.isToday {
            // Today's data already lives in the shared App Group cache.
            // Restore it directly — no API call, no risk of overwriting
            // correct DITIB data. Widget and app stay perfectly in sync.
            applySharedCache(cached)
        } else {
            // Cache is stale (new day) or empty (first launch).
            // Load using the persisted DITIB city — never fall back to a
            // hard-coded city string that could silently target the wrong city.
            loadSavedCity()
        }
        scheduleNextMidnightTimer()
        observeSignificantTimeChange()
        observeForeground()
    }

    // MARK: - Stale-cache / first-launch reload

    private func loadSavedCity() {
        guard let data = UserDefaults.standard.data(forKey: "dailydee.selectedDitibCity"),
              let city = try? JSONDecoder().decode(DitibCity.self, from: data) else {
            // No city persisted yet — leave prayerTimes empty.
            // The user will be prompted to pick a city from Settings.
            return
        }
        loadPrayerTimes(ditibCity: city)
    }

    // MARK: - Kerahat (Makruh) start times per prayer kind

    var kerahatStartTimes: [PrayerKind: String] {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        var result: [PrayerKind: String] = [:]
        if let shuruuq = prayerTimes.first(where: { $0.kind == .shuruuq }) {
            result[.shuruuq] = shuruuq.timeString
        }
        if let dhuhr = prayerTimes.first(where: { $0.kind == .dhuhr }),
           let start = Calendar.current.date(byAdding: .minute, value: -45, to: dhuhr.time) {
            result[.dhuhr] = fmt.string(from: start)
        }
        if let maghrib = prayerTimes.first(where: { $0.kind == .maghrib }),
           let start = Calendar.current.date(byAdding: .minute, value: -45, to: maghrib.time) {
            result[.maghrib] = fmt.string(from: start)
        }
        return result
    }

    // MARK: - Public load

    /// The single public entry point. Always uses the DITIB/Diyanet API.
    func loadPrayerTimes(ditibCity: DitibCity) {
        isLoading = true
        errorMessage = nil
        lastLoadedCityName = ditibCity.name
        // Write city name to the shared store immediately so the widget
        // already knows the new name before the API response arrives.
        SharedPrayerData.saveCity(ditibCity.name)
        Task {
            do {
                let daily = try await DitibAPIService.shared.fetchDailyPrayerTimes(districtId: ditibCity.id)
                applyDitibTimes(daily)
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Apply DITIB response

    private func applyDitibTimes(_ daily: DitibDailyData) {
        let t   = daily.times
        let ref = Date()
        timezoneIdentifier = "Europe/Berlin"
        prayerTimes = [
            PrayerTime(kind: .imsak,   timeString: t.imsak,  referenceDate: ref),
            PrayerTime(kind: .shuruuq, timeString: t.gunes,  referenceDate: ref),
            PrayerTime(kind: .dhuhr,   timeString: t.ogle,   referenceDate: ref),
            PrayerTime(kind: .asr,     timeString: t.ikindi, referenceDate: ref),
            PrayerTime(kind: .maghrib, timeString: t.aksam,  referenceDate: ref),
            PrayerTime(kind: .isha,    timeString: t.yatsi,  referenceDate: ref)
        ]
        isLoading = false

        // Stamp the cache with the API's own date string (normalised to ISO-8601).
        // This prevents UTC-lag poisoning: if the API returns yesterday's entry at
        // Berlin midnight (because the server clock is UTC), the cache gets marked
        // with YESTERDAY's date so isToday correctly returns false on next launch.
        let localISO = DateFormatter()
        localISO.locale     = Locale(identifier: "en_US_POSIX")
        localISO.dateFormat = "yyyy-MM-dd"
        let todayLocal  = localISO.string(from: ref)
        // Take the first 10 chars of the API date to strip any time component,
        // then verify it looks like an ISO date; fall back to the local date if not.
        let apiPrefix   = String(daily.date.prefix(10))
        let cachedDate  = (localISO.date(from: apiPrefix) != nil) ? apiPrefix : todayLocal

        // Persist to the shared App Group so the widget reads the same data.
        SharedPrayerData.save(SharedPrayerData(
            fajr: t.imsak, sunrise: t.gunes,
            dhuhr: t.ogle, asr: t.ikindi,
            maghrib: t.aksam, isha: t.yatsi,
            dateString: cachedDate,
            timezone: timezoneIdentifier,
            cityName: lastLoadedCityName
        ))
        // Tell WidgetKit to rebuild its timeline from the freshly written cache.
        WidgetCenter.shared.reloadAllTimelines()

        updateNextPrayerAndCountdown()
        syncWidgetPrayers()
        startCountdownTimer()
    }

    // MARK: - Restore from App Group cache (no API call)

    private func applySharedCache(_ cached: SharedPrayerData) {
        lastLoadedCityName = cached.cityName
        timezoneIdentifier = cached.timezone
        let ref = Date()
        prayerTimes = [
            PrayerTime(kind: .imsak,   timeString: cached.fajr,    referenceDate: ref),
            PrayerTime(kind: .shuruuq, timeString: cached.sunrise, referenceDate: ref),
            PrayerTime(kind: .dhuhr,   timeString: cached.dhuhr,   referenceDate: ref),
            PrayerTime(kind: .asr,     timeString: cached.asr,     referenceDate: ref),
            PrayerTime(kind: .maghrib, timeString: cached.maghrib, referenceDate: ref),
            PrayerTime(kind: .isha,    timeString: cached.isha,    referenceDate: ref)
        ]
        updateNextPrayerAndCountdown()
        syncWidgetPrayers()
        startCountdownTimer()
    }

    // MARK: - Widget Sync

    /// Encodes the 5 display prayers (Sunrise excluded) into the shared App Group
    /// so the widget extension can build its timeline without reimplementing prayer logic.
    private func syncWidgetPrayers() {
        let displayKinds: Set<PrayerKind> = [.imsak, .dhuhr, .asr, .maghrib, .isha]
        let entries: [WidgetPrayerEntry] = prayerTimes
            .filter { displayKinds.contains($0.kind) }
            .map { pt in
                WidgetPrayerEntry(
                    kindRaw: pt.kind.rawValue,
                    name: pt.kind.displayName,
                    iconName: pt.kind.iconName,
                    timeString: pt.timeString,
                    time: pt.time
                )
            }
        SharedPrayerData.saveTodayPrayers(entries)
    }

    // MARK: - Countdown

    private var countdownTimer: Timer?

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateNextPrayerAndCountdown()
            }
        }
        countdownTimer?.tolerance = 0.5
        RunLoop.current.add(countdownTimer!, forMode: .common)
    }

    private func updateNextPrayerAndCountdown() {
        let now = Date()
        nextPrayer = prayerTimes.first { $0.time > now }
        if let next = nextPrayer {
            let interval = next.time.timeIntervalSince(now)
            let h = Int(interval) / 3600
            let m = (Int(interval) % 3600) / 60
            let s = Int(interval) % 60
            countdownString = String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            // All prayers have passed — show countdown to tomorrow's Fajr.
            nextPrayer = prayerTimes.first
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
            let nextFajr = prayerTimes.first.flatMap { pt in
                Calendar.current.date(
                    bySettingHour:   Calendar.current.component(.hour,   from: pt.time),
                    minute:          Calendar.current.component(.minute, from: pt.time),
                    second: 0, of: tomorrow)
            }
            if let target = nextFajr {
                let interval = target.timeIntervalSince(now)
                let h = Int(interval) / 3600
                let m = (Int(interval) % 3600) / 60
                let s = Int(interval) % 60
                countdownString = String(format: "%02d:%02d:%02d", h, m, s)
            } else {
                countdownString = "--:--:--"
            }
        }
    }

    // MARK: - Midnight Rollover

    /// Schedules a one-shot timer that fires 2 seconds after the next midnight,
    /// triggering a fresh prayer-time fetch for the new day.
    private func scheduleNextMidnightTimer() {
        midnightTimer?.invalidate()
        let calendar = Calendar.current
        guard let nextMidnight = calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else { return }
        let fireDate = nextMidnight.addingTimeInterval(2)
        let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleMidnightRollover()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        midnightTimer = timer
    }

    /// Subscribes to UIKit's significant-time-change notification, which fires at
    /// midnight and on DST changes — a reliable system-level midnight trigger.
    private func observeSignificantTimeChange() {
        significantTimeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.significantTimeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleMidnightRollover()
            }
        }
    }

    /// Fires every time the app returns to the foreground.
    /// Re-validates the in-memory cache so that a phone left open overnight
    /// always shows fresh data when the user picks it up the next morning.
    private func observeForeground() {
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentDate = Date()
                // Refresh when the cached date no longer matches today.
                if let cached = SharedPrayerData.load(), !cached.isToday {
                    self.loadSavedCity()
                }
            }
        }
    }

    private func handleMidnightRollover() {
        currentDate = Date()
        loadSavedCity()
        scheduleNextMidnightTimer()   // arm for the next midnight
    }

    deinit {
        countdownTimer?.invalidate()
        midnightTimer?.invalidate()
        if let observer = significantTimeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
