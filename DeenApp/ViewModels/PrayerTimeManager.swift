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

@MainActor
final class PrayerTimeManager: ObservableObject {

    // MARK: - Published

    @Published private(set) var prayerTimes: [PrayerTime] = []
    @Published private(set) var nextPrayer: PrayerTime?
    @Published private(set) var countdownString: String = "--:--:--"
    @Published private(set) var timezoneIdentifier: String = "Europe/Berlin"
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Private

    private var lastLoadedCityName = ""

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
                let times = try await DitibAPIService.shared.fetchDailyPrayerTimes(districtId: ditibCity.id)
                applyDitibTimes(times)
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Apply DITIB response

    private func applyDitibTimes(_ t: DitibTimes) {
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

        // Persist to the shared App Group so the widget reads the same data.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        SharedPrayerData.save(SharedPrayerData(
            fajr: t.imsak, sunrise: t.gunes,
            dhuhr: t.ogle, asr: t.ikindi,
            maghrib: t.aksam, isha: t.yatsi,
            dateString: formatter.string(from: ref),
            timezone: timezoneIdentifier,
            cityName: lastLoadedCityName
        ))
        // Tell WidgetKit to rebuild its timeline from the freshly written cache.
        WidgetCenter.shared.reloadAllTimelines()

        updateNextPrayerAndCountdown()
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
        startCountdownTimer()
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

    deinit {
        countdownTimer?.invalidate()
    }
}
