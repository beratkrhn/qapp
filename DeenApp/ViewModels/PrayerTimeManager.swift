//
//  PrayerTimeManager.swift
//  DeenApp
//
//  Lädt Gebetszeiten via Aladhan API oder DITIB (Diyanet) API
//  basierend auf der gewählten Stadt und dem ausgewählten Provider.
//

import Foundation
import Combine

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

    private let aladhanBaseURL = "https://api.aladhan.com/v1"
    private let kCachedTimesKey  = "prayerTimesCache_v2"
    private let kCachedDateKey   = "prayerTimesCacheDate_v2"

    private struct CachedTime: Codable {
        let kind: PrayerKind
        let ts: String
    }

    init() {
        restoreCachedPrayerTimes()
    }

    // MARK: - Cache Restore

    private func restoreCachedPrayerTimes() {
        let fmt = DateFormatter()
        fmt.dateFormat = "dd-MM-yyyy"
        let today = fmt.string(from: Date())
        guard
            let cachedDate = UserDefaults.standard.string(forKey: kCachedDateKey),
            cachedDate == today,
            let data = UserDefaults.standard.data(forKey: kCachedTimesKey),
            let cached = try? JSONDecoder().decode([CachedTime].self, from: data),
            !cached.isEmpty
        else { return }
        let ref = Date()
        prayerTimes = cached.map { PrayerTime(kind: $0.kind, timeString: $0.ts, referenceDate: ref) }
        updateNextPrayerAndCountdown()
        startCountdownTimer()
    }

    private func savePrayerTimesCache() {
        let fmt = DateFormatter()
        fmt.dateFormat = "dd-MM-yyyy"
        UserDefaults.standard.set(fmt.string(from: Date()), forKey: kCachedDateKey)
        let toCache = prayerTimes.map { CachedTime(kind: $0.kind, ts: $0.timeString) }
        if let data = try? JSONEncoder().encode(toCache) {
            UserDefaults.standard.set(data, forKey: kCachedTimesKey)
        }
    }

    // MARK: - Public Load Entry Point

    func loadPrayerTimes(
        for city: AppCity,
        method: CalculationMethod = .ditib,
        provider: PrayerTimeProvider = .ditib
    ) {
        Task {
            switch provider {
            case .ditib:
                await fetchDitibPrayerTimes(for: city)
            case .aladhan:
                await fetchAladhanPrayerTimes(
                    latitude: city.latitude,
                    longitude: city.longitude,
                    method: method
                )
            }
        }
    }

    // MARK: - DITIB Fetch

    private func fetchDitibPrayerTimes(for city: AppCity) async {
        isLoading = true
        errorMessage = nil

        do {
            let districtId = city.ditibDistrictId
            let times = try await DitibAPIService.shared.fetchDailyPrayerTimes(districtId: districtId)
            isLoading = false
            applyDitibTimes(times)
        } catch {
            print("DITIB Fetch Error: \(error.localizedDescription) – falling back to Aladhan")
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func applyDitibTimes(_ t: DitibTimes) {
        let ref = Date()
        timezoneIdentifier = "Europe/Berlin"
        prayerTimes = [
            PrayerTime(kind: .imsak,   timeString: t.imsak,   referenceDate: ref),
            PrayerTime(kind: .shuruuq, timeString: t.gunes,   referenceDate: ref),
            PrayerTime(kind: .dhuhr,   timeString: t.ogle,    referenceDate: ref),
            PrayerTime(kind: .asr,     timeString: t.ikindi,  referenceDate: ref),
            PrayerTime(kind: .maghrib, timeString: t.aksam,   referenceDate: ref),
            PrayerTime(kind: .isha,    timeString: t.yatsi,   referenceDate: ref)
        ]
        updateNextPrayerAndCountdown()
        startCountdownTimer()
        savePrayerTimesCache()
    }

    // MARK: - Aladhan Fetch

    private func fetchAladhanPrayerTimes(
        latitude: Double,
        longitude: Double,
        method: CalculationMethod = .ditib
    ) async {
        isLoading = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: Date())

        guard let url = URL(string: "\(aladhanBaseURL)/timings/\(dateString)?latitude=\(latitude)&longitude=\(longitude)&method=\(method.rawValue)") else {
            isLoading = false
            errorMessage = "Ungültige URL"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print("Aladhan Fetch Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            print("Aladhan Fetch Response Body: \(String(data: data, encoding: .utf8) ?? "NONE")")
            let aladhanResponse = try JSONDecoder().decode(AladhanResponse.self, from: data)
            isLoading = false
            applyAladhanResponse(aladhanResponse)
        } catch {
            print("Aladhan Fetch Error: \(error.localizedDescription)")
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func applyAladhanResponse(_ response: AladhanResponse) {
        guard response.code == 200 else {
            errorMessage = response.status
            return
        }
        let t = response.data.timings
        let ref = Date()
        timezoneIdentifier = response.data.meta?.timezone ?? "Europe/Berlin"
        prayerTimes = [
            PrayerTime(kind: .imsak,   timeString: cleanTimeString(t.imsak),   referenceDate: ref),
            PrayerTime(kind: .shuruuq, timeString: cleanTimeString(t.sunrise), referenceDate: ref),
            PrayerTime(kind: .dhuhr,   timeString: cleanTimeString(t.dhuhr),   referenceDate: ref),
            PrayerTime(kind: .asr,     timeString: cleanTimeString(t.asr),     referenceDate: ref),
            PrayerTime(kind: .maghrib, timeString: cleanTimeString(t.maghrib), referenceDate: ref),
            PrayerTime(kind: .isha,    timeString: cleanTimeString(t.isha),    referenceDate: ref)
        ]
        updateNextPrayerAndCountdown()
        startCountdownTimer()
        savePrayerTimesCache()
    }

    /// Aladhan sometimes returns "05:22 (CET)" – strip the timezone suffix.
    private func cleanTimeString(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if let spaceIndex = trimmed.firstIndex(of: " ") {
            return String(trimmed[trimmed.startIndex..<spaceIndex])
        }
        return trimmed
    }

    // MARK: - Countdown Timer

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
        let prayerOnly = prayerTimes.filter { $0.kind != .shuruuq }
        nextPrayer = prayerOnly.first { $0.time > now }
        if let next = nextPrayer {
            let interval = next.time.timeIntervalSince(now)
            let h = Int(interval) / 3600
            let m = (Int(interval) % 3600) / 60
            let s = Int(interval) % 60
            countdownString = String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            nextPrayer = prayerOnly.first(where: { $0.kind == .imsak }) ?? prayerOnly.first
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
            let nextImsak = prayerTimes.first(where: { $0.kind == .imsak }).flatMap { pt in
                Calendar.current.date(
                    bySettingHour: Calendar.current.component(.hour, from: pt.time),
                    minute: Calendar.current.component(.minute, from: pt.time),
                    second: 0, of: tomorrow
                )
            }
            if let target = nextImsak {
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

    // MARK: - Kerahat (Makruh) Start Times

    var kerahatStartTimes: [PrayerKind: String] {
        var result: [PrayerKind: String] = [:]
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        let kerahatPrayers: [PrayerKind] = [.dhuhr, .maghrib]
        for kind in kerahatPrayers {
            guard let prayer = prayerTimes.first(where: { $0.kind == kind }),
                  let start = Calendar.current.date(byAdding: .minute, value: -45, to: prayer.time)
            else { continue }
            result[kind] = fmt.string(from: start)
        }
        return result
    }

    deinit {
        countdownTimer?.invalidate()
    }
}
