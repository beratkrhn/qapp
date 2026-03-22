//
//  PrayerTimeManager.swift
//  DeenApp
//
<<<<<<< HEAD
//  Lädt Gebetszeiten via Aladhan API oder DITIB (Diyanet) API
//  basierend auf der gewählten Stadt und dem ausgewählten Provider.
=======
//  Lädt Gebetszeiten via Aladhan API, ermittelt nächstes Gebet & Countdown.
>>>>>>> origin/claude/adoring-banach
//

import Foundation
import Combine
<<<<<<< HEAD
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class PrayerTimeManager: ObservableObject {
=======
import CoreLocation

@MainActor
final class PrayerTimeManager: NSObject, ObservableObject {
>>>>>>> origin/claude/adoring-banach

    // MARK: - Published

    @Published private(set) var prayerTimes: [PrayerTime] = []
    @Published private(set) var nextPrayer: PrayerTime?
    @Published private(set) var countdownString: String = "--:--:--"
    @Published private(set) var timezoneIdentifier: String = "Europe/Berlin"
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Private

<<<<<<< HEAD
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
        publishWidgetSnapshotIfPossible()
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
        calculation: PrayerCalculationSettings,
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
                    calculation: calculation
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
        publishWidgetSnapshotIfPossible()
    }

    // MARK: - Aladhan Fetch

    private func fetchAladhanPrayerTimes(
        latitude: Double,
        longitude: Double,
        calculation: PrayerCalculationSettings
    ) async {
        isLoading = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: Date())

        guard let url = aladhanTimingsURL(dateString: dateString, latitude: latitude, longitude: longitude, calculation: calculation) else {
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

    /// Fazilet: eigene Voreinstellung über `method=99` und typische TR/EU-Winkel (18° / 17°), s. Aladhan-Doku zu `methodSettings`.
    private func aladhanTimingsURL(
        dateString: String,
        latitude: Double,
        longitude: Double,
        calculation: PrayerCalculationSettings
    ) -> URL? {
        var components = URLComponents(string: "\(aladhanBaseURL)/timings/\(dateString)")
        var items: [URLQueryItem] = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude))
        ]
        switch calculation {
        case .preset(let preset):
            items.append(URLQueryItem(name: "method", value: String(preset.aladhanMethodId)))
            if preset == .fazilet {
                items.append(URLQueryItem(name: "methodSettings", value: "18,null,17"))
            }
        case .custom(let custom):
            items.append(URLQueryItem(name: "method", value: "99"))
            items.append(URLQueryItem(name: "methodSettings", value: custom.methodSettingsQueryValue))
            items.append(URLQueryItem(name: "tune", value: custom.tuneQueryValue))
        }
        components?.queryItems = items
        return components?.url
    }

    private func applyAladhanResponse(_ response: AladhanResponse) {
=======
    private let baseURL = "https://api.aladhan.com/v1"
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        startLocationAndLoad()
    }

    /// Standort anfordern und Gebetszeiten laden (Address-Fallback: Berlin)
    func startLocationAndLoad() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            loadPrayerTimes(address: "Berlin")
        }
    }

    /// Gebetszeiten per Adresse laden (z. B. "Berlin" oder "Europe/Berlin")
    func loadPrayerTimes(address: String) {
        isLoading = true
        errorMessage = nil
        guard let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/timingsByAddress?address=\(encoded)") else {
            isLoading = false
            errorMessage = "Ungültige Adresse"
            return
        }

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AladhanResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.errorMessage = err.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.applyResponse(response)
            }
            .store(in: &cancellables)
    }

    /// Gebetszeiten per Koordinaten laden
    func loadPrayerTimes(latitude: Double, longitude: Double) {
        isLoading = true
        errorMessage = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: Date())
        guard let url = URL(string: "\(baseURL)/timings/\(dateString)?latitude=\(latitude)&longitude=\(longitude)") else {
            isLoading = false
            return
        }

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AladhanResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.errorMessage = err.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.applyResponse(response)
            }
            .store(in: &cancellables)
    }

    private func applyResponse(_ response: AladhanResponse) {
>>>>>>> origin/claude/adoring-banach
        guard response.code == 200 else {
            errorMessage = response.status
            return
        }
        let t = response.data.timings
        let ref = Date()
        timezoneIdentifier = response.data.meta?.timezone ?? "Europe/Berlin"
        prayerTimes = [
<<<<<<< HEAD
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
        publishWidgetSnapshotIfPossible()
    }

    /// Aladhan sometimes returns "05:22 (CET)" – strip the timezone suffix.
    private func cleanTimeString(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if let spaceIndex = trimmed.firstIndex(of: " ") {
            return String(trimmed[trimmed.startIndex..<spaceIndex])
        }
        return trimmed
    }

    // MARK: - Widget snapshot (App Group)

    private func publishWidgetSnapshotIfPossible() {
        let kinds: [PrayerKind] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        let rows: [PrayerWidgetSnapshot.Row] = kinds.compactMap { kind in
            let pt = prayerTimes.first(where: { $0.kind == kind })
                ?? (kind == .fajr ? prayerTimes.first(where: { $0.kind == .imsak }) : nil)
            guard let pt else { return nil }
            return PrayerWidgetSnapshot.Row(
                kindRaw: kind.rawValue,
                time: pt.timeString,
                iconSystemName: kind.iconName,
                title: kind.displayName
            )
        }
        guard rows.count == kinds.count else { return }
        let snap = PrayerWidgetSnapshot(savedAt: Date().timeIntervalSince1970, rows: rows)
        PrayerWidgetStore.save(snap)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    // MARK: - Countdown Timer

=======
            PrayerTime(kind: .fajr, timeString: t.fajr, referenceDate: ref),
            PrayerTime(kind: .dhuhr, timeString: t.dhuhr, referenceDate: ref),
            PrayerTime(kind: .asr, timeString: t.asr, referenceDate: ref),
            PrayerTime(kind: .maghrib, timeString: t.maghrib, referenceDate: ref),
            PrayerTime(kind: .isha, timeString: t.isha, referenceDate: ref)
        ]
        updateNextPrayerAndCountdown()
        startCountdownTimer()
    }

>>>>>>> origin/claude/adoring-banach
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
<<<<<<< HEAD
        let prayerOnly = prayerTimes.filter { $0.kind != .shuruuq }
        nextPrayer = prayerOnly.first { $0.time > now }
=======
        nextPrayer = prayerTimes.first { $0.time > now }
>>>>>>> origin/claude/adoring-banach
        if let next = nextPrayer {
            let interval = next.time.timeIntervalSince(now)
            let h = Int(interval) / 3600
            let m = (Int(interval) % 3600) / 60
            let s = Int(interval) % 60
            countdownString = String(format: "%02d:%02d:%02d", h, m, s)
        } else {
<<<<<<< HEAD
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
=======
            // Nächstes Gebet ist morgen Fajr
            nextPrayer = prayerTimes.first
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
            let nextFajr = prayerTimes.first.flatMap { pt in
                Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: pt.time), minute: Calendar.current.component(.minute, from: pt.time), second: 0, of: tomorrow)
            }
            if let target = nextFajr {
>>>>>>> origin/claude/adoring-banach
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

<<<<<<< HEAD
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

=======
>>>>>>> origin/claude/adoring-banach
    deinit {
        countdownTimer?.invalidate()
    }
}
<<<<<<< HEAD
=======

// MARK: - CLLocationManagerDelegate

extension PrayerTimeManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            currentLocation = loc.coordinate
            loadPrayerTimes(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            loadPrayerTimes(address: "Berlin")
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            } else {
                loadPrayerTimes(address: "Berlin")
            }
        }
    }
}
>>>>>>> origin/claude/adoring-banach
