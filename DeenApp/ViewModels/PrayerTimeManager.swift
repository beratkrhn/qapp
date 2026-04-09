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
    /// 10-day prayer time forecast, loaded on demand.
    @Published private(set) var tenDayForecast: [ForecastDay] = []
    @Published private(set) var isForecastLoading = false

    // MARK: - Private

    private var lastLoadedCityName = ""
    /// The last city used to successfully fetch prayer times — used by the forecast loader.
    private(set) var currentDitibCity: DitibCity?
    private var midnightTimer: Timer?
    /// Set to true when all today's prayers have passed, preventing repeated
    /// tomorrow-preload requests from the per-second countdown timer.
    private var nextDayFetchTriggered = false
    private var significantTimeObserver: (any NSObjectProtocol)?
    private var foregroundObserver: (any NSObjectProtocol)?
    private var languageObserver: (any NSObjectProtocol)?

    // MARK: - Init

    init() {
        // Always restore the DITIB city from UserDefaults first, so
        // loadTenDayForecast() works even when prayer times come from cache.
        if let data = UserDefaults.standard.data(forKey: "dailydee.selectedDitibCity"),
           let city = try? JSONDecoder().decode(DitibCity.self, from: data) {
            currentDitibCity = city
        }

        if let cached = SharedPrayerData.load(), isCacheCurrentlyValid(cached) {
            // Cache holds data for today OR for tomorrow (pre-loaded after Isha).
            // Restore directly — no API call needed.
            applySharedCache(cached)
        } else {
            // Cache is stale (past day) or empty (first launch).
            loadSavedCity()
        }
        scheduleNextMidnightTimer()
        observeSignificantTimeChange()
        observeForeground()
        observeLanguageChange()
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

    /// A cache entry is valid if its dateString represents today OR a future date.
    /// This allows post-Isha next-day data (stored with tomorrow's date) to survive
    /// foreground re-enters and app restarts without being thrown away.
    private func isCacheCurrentlyValid(_ cached: SharedPrayerData) -> Bool {
        let fmt = DateFormatter()
        fmt.locale     = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        guard let cacheDate = fmt.date(from: cached.dateString) else { return false }
        let todayStart = Calendar.current.startOfDay(for: Date())
        let cacheStart = Calendar.current.startOfDay(for: cacheDate)
        return cacheStart >= todayStart
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
        currentDitibCity = ditibCity
        // Write city name and district ID to the shared App Group so the
        // widget knows the new city before the API response arrives, and
        // can self-fetch prayer times when its cached data becomes stale.
        SharedPrayerData.saveCity(ditibCity.name)
        UserDefaults(suiteName: "group.d.DailyDee")?.set(ditibCity.id, forKey: "widgetDistrictId")
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

    private func applyDitibTimes(_ daily: DitibDailyData, skipStaleCheck: Bool = false) {
        let t = daily.times

        // MARK: Stale Data Detection
        if !skipStaleCheck {
            let localISO = DateFormatter()
            localISO.locale     = Locale(identifier: "en_US_POSIX")
            localISO.dateFormat = "yyyy-MM-dd"
            let todayLocal = localISO.string(from: Date())
            let apiPrefix  = String(daily.date.prefix(10))

            // Primary signal: the API's own date field doesn't match today in the
            // local (Berlin) timezone. This is the definitive stale-data indicator —
            // localTodayEntry() fell back to .first and returned yesterday's entry.
            let apiDateMismatch = localISO.date(from: apiPrefix) != nil && apiPrefix != todayLocal

            // Secondary signal: all six time strings are identical to a cache entry
            // that is NOT from today. Catches the edge-case where the server stamps
            // the correct date but ships yesterday's time values.
            var timesMirrorCache = false
            if let cached = SharedPrayerData.load(), !cached.isToday {
                let cachedTimes = [cached.fajr, cached.sunrise, cached.dhuhr,
                                   cached.asr,  cached.maghrib, cached.isha]
                let newTimes    = [t.imsak, t.gunes, t.ogle, t.ikindi, t.aksam, t.yatsi]
                timesMirrorCache = cachedTimes == newTimes
            }

            if apiDateMismatch || timesMirrorCache {
                isLoading = false
                fetchNextDayAsFallback()
                return
            }
        }

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

    // MARK: - Stale-Data Fallback

    /// Triggered when applyDitibTimes detects that the API returned time strings
    /// identical to yesterday's cache (UTC-lag / stale CDN response).
    /// Re-fetches the multi-day list and applies the entry that correctly represents
    /// today in the local (Berlin) timezone. `skipStaleCheck: true` prevents loops.
    private func fetchNextDayAsFallback() {
        guard let city = currentDitibCity else { return }
        Task {
            do {
                let days = try await DitibAPIService.shared.fetchNextTenDays(districtId: city.id)
                guard !days.isEmpty else {
                    errorMessage = "Keine Gebetszeiten für heute verfügbar"
                    return
                }
                // fetchNextTenDays starts its slice from today's local date (index 0),
                // so days[0] is the correct current-local-day entry.
                applyDitibTimes(days[0], skipStaleCheck: true)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Restore from App Group cache (no API call)

    private func applySharedCache(_ cached: SharedPrayerData) {
        lastLoadedCityName = cached.cityName
        timezoneIdentifier = cached.timezone
        // Use the cache's own date as referenceDate so that a next-day entry
        // (stored with tomorrow's date after Isha) produces PrayerTime.time values
        // that are correctly anchored to tomorrow, not to today.
        let fmt = DateFormatter()
        fmt.locale     = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        let ref = fmt.date(from: cached.dateString) ?? Date()
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

    /// Encodes all 6 display prayers (including Shuruuq) into the shared App Group
    /// so the widget extension can build its timeline. Names are localised to the
    /// currently selected app language so all widget sizes show the correct names.
    private func syncWidgetPrayers() {
        let rawLang = UserDefaults.standard.string(forKey: "dailydee.appLanguage")
        let language = rawLang.flatMap(AppLanguage.init(rawValue:)) ?? .german

        let entries: [WidgetPrayerEntry] = prayerTimes.map { pt in
            WidgetPrayerEntry(
                kindRaw: pt.kind.rawValue,
                name: pt.kind.localizedName(for: language),
                iconName: pt.kind.iconName,
                timeString: pt.timeString,
                time: pt.time
            )
        }
        SharedPrayerData.saveTodayPrayers(entries)
    }

    /// Re-syncs widget data when the user changes the app language so the widget
    /// immediately reflects the new prayer name style without an API refetch.
    private func observeLanguageChange() {
        languageObserver = NotificationCenter.default.addObserver(
            forName: .appLanguageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncWidgetPrayers()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
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
            // Prayers remain today — reset trigger so it can re-arm tomorrow.
            nextDayFetchTriggered = false
            let interval = next.time.timeIntervalSince(now)
            let h = Int(interval) / 3600
            let m = (Int(interval) % 3600) / 60
            let s = Int(interval) % 60
            countdownString = String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            // All of today's prayers have passed.
            // Fire the tomorrow-preload exactly once so we can show an exact Fajr countdown
            // rather than an approximated time-shift. The flag prevents repeat Task launches.
            if !nextDayFetchTriggered {
                nextDayFetchTriggered = true
                loadTomorrowFully()
            }

            // Placeholder countdown (today's Fajr time-components pushed to tomorrow).
            // Replaced with exact values once loadTomorrowFully() completes.
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
                // Only re-fetch when the cache is genuinely stale (past day).
                // A cache with tomorrow's date (post-Isha next-day load) is still valid.
                if let cached = SharedPrayerData.load(), !self.isCacheCurrentlyValid(cached) {
                    self.loadSavedCity()
                } else if let cached = SharedPrayerData.load(), self.isCacheCurrentlyValid(cached) {
                    // Re-apply so PrayerTime.time values are re-anchored to the correct date.
                    self.applySharedCache(cached)
                }
            }
        }
    }

    private func handleMidnightRollover() {
        currentDate = Date()
        nextDayFetchTriggered = false
        // If tomorrow's prayer times were pre-loaded after Isha, they are now
        // today's times. Apply from cache — no API call needed.
        // Otherwise fetch fresh data for the new day.
        if let cached = SharedPrayerData.load(), isCacheCurrentlyValid(cached) {
            applySharedCache(cached)
        } else {
            loadSavedCity()
        }
        scheduleNextMidnightTimer()
    }

    // MARK: - Next-Day Full Commit (post-Isha)

    /// Called once after Isha passes. Fetches tomorrow's prayer times and fully
    /// commits them to the app, cache, and widget — so both the app and the widget
    /// immediately display Saturday's schedule after Friday's Isha.
    private func loadTomorrowFully() {
        guard let city = currentDitibCity else { return }
        Task {
            do {
                let days = try await DitibAPIService.shared.fetchNextTenDays(districtId: city.id)
                // days[0] = today, days[1] = tomorrow
                guard days.count > 1 else { return }
                applyNextDayData(days[1])
            } catch {
                // Non-critical: the approximate placeholder countdown stays visible.
            }
        }
    }

    /// Applies tomorrow's prayer times as the active schedule.
    /// Uses tomorrow as referenceDate so every PrayerTime.time is a real future Date.
    /// Writes to the shared cache (with tomorrow's dateString) and reloads the widget
    /// so the widget also immediately shows the next day's times.
    private func applyNextDayData(_ daily: DitibDailyData) {
        let t        = daily.times
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        prayerTimes = [
            PrayerTime(kind: .imsak,   timeString: t.imsak,  referenceDate: tomorrow),
            PrayerTime(kind: .shuruuq, timeString: t.gunes,  referenceDate: tomorrow),
            PrayerTime(kind: .dhuhr,   timeString: t.ogle,   referenceDate: tomorrow),
            PrayerTime(kind: .asr,     timeString: t.ikindi, referenceDate: tomorrow),
            PrayerTime(kind: .maghrib, timeString: t.aksam,  referenceDate: tomorrow),
            PrayerTime(kind: .isha,    timeString: t.yatsi,  referenceDate: tomorrow)
        ]

        // Determine the ISO date string for the cache entry.
        // Prefer the API's own date field; fall back to our computed tomorrow.
        let iso = DateFormatter()
        iso.locale     = Locale(identifier: "en_US_POSIX")
        iso.dateFormat = "yyyy-MM-dd"
        let apiPrefix    = String(daily.date.prefix(10))
        let tomorrowISO  = iso.string(from: tomorrow)
        let cacheDateStr = (iso.date(from: apiPrefix) != nil) ? apiPrefix : tomorrowISO

        // Full commit: write cache with tomorrow's date so isCacheCurrentlyValid
        // keeps it alive, and reload the widget so it also shows tomorrow's times.
        SharedPrayerData.save(SharedPrayerData(
            fajr: t.imsak, sunrise: t.gunes,
            dhuhr: t.ogle, asr: t.ikindi,
            maghrib: t.aksam, isha: t.yatsi,
            dateString: cacheDateStr,
            timezone: timezoneIdentifier,
            cityName: lastLoadedCityName
        ))
        syncWidgetPrayers()
        WidgetCenter.shared.reloadAllTimelines()

        // Re-evaluate: countdown timer will now find tomorrow's Fajr as nextPrayer.
        updateNextPrayerAndCountdown()
    }

    // MARK: - 10-Day Forecast

    /// Loads the 10-day prayer time forecast using the internally stored city.
    /// No parameter needed — uses the city that produced today's prayer times.
    /// After Isha has passed today, the first card shown is tomorrow.
    func loadTenDayForecast() {
        guard let city = currentDitibCity else { return }
        guard !isForecastLoading else { return }
        isForecastLoading = true
        Task {
            do {
                var days = try await DitibAPIService.shared.fetchNextTenDays(districtId: city.id)

                // Once Isha has passed, today is fully done — the user only cares
                // about upcoming days, so drop today's entry from the list.
                if let isha = prayerTimes.first(where: { $0.kind == .isha }),
                   Date() >= isha.time {
                    days = Array(days.dropFirst())
                }

                let isoFmt = DateFormatter()
                isoFmt.locale     = Locale(identifier: "en_US_POSIX")
                isoFmt.dateFormat = "yyyy-MM-dd"

                let forecast: [ForecastDay] = Array(days.prefix(10)).compactMap { daily in
                    // Use guard-let so that days with unparseable date strings are
                    // excluded entirely, instead of silently defaulting to today
                    // (which would make every card appear to show today's date).
                    guard let date = Self.parseAPIDate(daily.date) else { return nil }
                    let t = daily.times
                    let prayers: [PrayerTime] = [
                        PrayerTime(kind: .imsak,   timeString: t.imsak,  referenceDate: date),
                        PrayerTime(kind: .shuruuq, timeString: t.gunes,  referenceDate: date),
                        PrayerTime(kind: .dhuhr,   timeString: t.ogle,   referenceDate: date),
                        PrayerTime(kind: .asr,     timeString: t.ikindi, referenceDate: date),
                        PrayerTime(kind: .maghrib, timeString: t.aksam,  referenceDate: date),
                        PrayerTime(kind: .isha,    timeString: t.yatsi,  referenceDate: date)
                    ]
                    // Normalise the dateString to "yyyy-MM-dd" so IDs are stable
                    // and consistent regardless of what format the API returned.
                    return ForecastDay(date: date,
                                       dateString: isoFmt.string(from: date),
                                       prayers: prayers)
                }
                tenDayForecast = forecast
                isForecastLoading = false
            } catch {
                isForecastLoading = false
            }
        }
    }

    /// Parses API date strings in multiple formats (ISO, German, Unix epoch, etc.).
    /// Returns nil if the string cannot be interpreted — callers should exclude
    /// nil results rather than falling back to today's date.
    static func parseAPIDate(_ raw: String) -> Date? {
        let prefix10 = String(raw.prefix(10))

        // Unix epoch (all-digit string, 10 chars = seconds since 1970)
        if prefix10.allSatisfy(\.isNumber), let ts = TimeInterval(prefix10) {
            // Normalise to local-calendar midnight so referenceDate arithmetic works.
            let tsDate = Date(timeIntervalSince1970: ts)
            return Calendar.current.startOfDay(for: tsDate)
        }

        let candidates = [prefix10, raw]
        let formats    = ["yyyy-MM-dd", "dd.MM.yyyy", "MM/dd/yyyy", "yyyy/MM/dd"]
        let df         = DateFormatter()
        df.locale      = Locale(identifier: "en_US_POSIX")
        for candidate in candidates {
            for fmt in formats {
                df.dateFormat = fmt
                if let date = df.date(from: candidate) {
                    // Normalise to local-calendar midnight for safe referenceDate use.
                    return Calendar.current.startOfDay(for: date)
                }
            }
        }
        return nil
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
        if let observer = languageObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
