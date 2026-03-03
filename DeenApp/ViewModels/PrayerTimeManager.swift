//
//  PrayerTimeManager.swift
//  DeenApp
//
//  Lädt Gebetszeiten via Aladhan API, ermittelt nächstes Gebet & Countdown.
//

import Foundation
import Combine
import CoreLocation

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
        guard response.code == 200 else {
            errorMessage = response.status
            return
        }
        let t = response.data.timings
        let ref = Date()
        timezoneIdentifier = response.data.meta?.timezone ?? "Europe/Berlin"
        prayerTimes = [
            PrayerTime(kind: .fajr, timeString: t.fajr, referenceDate: ref),
            PrayerTime(kind: .dhuhr, timeString: t.dhuhr, referenceDate: ref),
            PrayerTime(kind: .asr, timeString: t.asr, referenceDate: ref),
            PrayerTime(kind: .maghrib, timeString: t.maghrib, referenceDate: ref),
            PrayerTime(kind: .isha, timeString: t.isha, referenceDate: ref)
        ]
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
