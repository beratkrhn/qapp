//
//  PrayerTimeManager.swift
//  DeenApp
//
//  Lädt Gebetszeiten via Aladhan API, ermittelt nächstes Gebet & Countdown.
//

import Foundation
import Combine
import CoreLocation
import WidgetKit

@MainActor
final class PrayerTimeManager: NSObject, ObservableObject {

    // MARK: - Published

    @Published private(set) var prayerTimes: [PrayerTime] = []
    @Published private(set) var nextPrayer: PrayerTime?
    @Published private(set) var countdownString: String = "--:--:--"
    @Published private(set) var timezoneIdentifier: String = "Europe/Berlin"
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Private

    private let baseURL = "https://api.aladhan.com/v1"
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D?
    private var lastLoadedCityName = "Berlin"

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
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

    // MARK: - Unified load (city + calculation + provider)

    func loadPrayerTimes(for city: AppCity, calculation: PrayerCalculationSettings, provider: PrayerTimeProvider) {
        isLoading = true
        errorMessage = nil
        lastLoadedCityName = city.displayName

        switch provider {
        case .ditib:
            loadFromDitib(city: city)
        case .aladhan:
            loadFromAladhan(city: city, calculation: calculation)
        }
    }

    // MARK: - DITIB provider

    private func loadFromDitib(city: AppCity) {
        Task {
            do {
                let districtId = await DitibAPIService.shared.resolveDistrictId(for: city.rawValue)
                let times = try await DitibAPIService.shared.fetchDailyPrayerTimes(districtId: districtId)
                applyDitibTimes(times)
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func applyDitibTimes(_ t: DitibTimes) {
        let ref = Date()
        timezoneIdentifier = "Europe/Berlin"
        prayerTimes = [
            PrayerTime(kind: .imsak, timeString: t.imsak, referenceDate: ref),
            PrayerTime(kind: .fajr, timeString: t.imsak, referenceDate: ref),
            PrayerTime(kind: .shuruuq, timeString: t.gunes, referenceDate: ref),
            PrayerTime(kind: .dhuhr, timeString: t.ogle, referenceDate: ref),
            PrayerTime(kind: .asr, timeString: t.ikindi, referenceDate: ref),
            PrayerTime(kind: .maghrib, timeString: t.aksam, referenceDate: ref),
            PrayerTime(kind: .isha, timeString: t.yatsi, referenceDate: ref)
        ]
        isLoading = false

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
        WidgetCenter.shared.reloadAllTimelines()

        updateNextPrayerAndCountdown()
        startCountdownTimer()
    }

    // MARK: - Aladhan provider

    private func loadFromAladhan(city: AppCity, calculation: PrayerCalculationSettings) {
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "dd-MM-yyyy"
        let dateString = dateFmt.string(from: Date())

        var urlString = "\(baseURL)/timings/\(dateString)?latitude=\(city.latitude)&longitude=\(city.longitude)"

        switch calculation {
        case .preset(let preset):
            urlString += "&method=\(preset.aladhanMethodId)"
            if preset == .fazilet {
                urlString += "&methodSettings=18,null,17"
            }
        case .custom(let params):
            urlString += "&method=99"
            urlString += "&methodSettings=\(params.methodSettingsQueryValue)"
            urlString += "&tune=\(params.tuneQueryValue)"
        }

        guard let url = URL(string: urlString) else {
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

    /// Fallback: load by address (used by location delegate)
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

    /// Fallback: load by coordinates (used by location delegate)
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
        guard response.code == 200 else {
            errorMessage = response.status
            return
        }
        let t = response.data.timings
        let ref = Date()
        timezoneIdentifier = response.data.meta?.timezone ?? "Europe/Berlin"
        prayerTimes = [
            PrayerTime(kind: .imsak, timeString: t.imsak, referenceDate: ref),
            PrayerTime(kind: .fajr, timeString: t.fajr, referenceDate: ref),
            PrayerTime(kind: .shuruuq, timeString: t.sunrise, referenceDate: ref),
            PrayerTime(kind: .dhuhr, timeString: t.dhuhr, referenceDate: ref),
            PrayerTime(kind: .asr, timeString: t.asr, referenceDate: ref),
            PrayerTime(kind: .maghrib, timeString: t.maghrib, referenceDate: ref),
            PrayerTime(kind: .isha, timeString: t.isha, referenceDate: ref)
        ]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        SharedPrayerData.save(SharedPrayerData(
            fajr: t.fajr, sunrise: t.sunrise,
            dhuhr: t.dhuhr, asr: t.asr,
            maghrib: t.maghrib, isha: t.isha,
            dateString: formatter.string(from: ref),
            timezone: timezoneIdentifier,
            cityName: lastLoadedCityName
        ))
        WidgetCenter.shared.reloadAllTimelines()

        updateNextPrayerAndCountdown()
        startCountdownTimer()
    }

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
            // Nächstes Gebet ist morgen Fajr
            nextPrayer = prayerTimes.first
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
            let nextFajr = prayerTimes.first.flatMap { pt in
                Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: pt.time), minute: Calendar.current.component(.minute, from: pt.time), second: 0, of: tomorrow)
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
