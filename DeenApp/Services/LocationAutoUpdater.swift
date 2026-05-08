//
//  LocationAutoUpdater.swift
//  DeenApp
//
//  Polls the user's GPS location every 10 minutes while the app is in use
//  and switches the active DITIB city to whichever entry from the hardcoded
//  catalogue best matches the current locality (or, as fallback, whatever the
//  Diyanet search endpoint returns for that name). When the user crosses a
//  city border (e.g. Günzburg → Ulm) the prayer times follow automatically.
//

import Foundation
import Combine
import CoreLocation
import UIKit

@MainActor
final class LocationAutoUpdater: NSObject, ObservableObject {

    // MARK: - Published state

    /// Mirrors the system-level CoreLocation authorization in a UI-friendly form.
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    /// Name of the city last detected and applied. `nil` until the first match.
    @Published private(set) var lastDetectedCityName: String?
    /// Last error surfaced from CoreLocation, geocoding, or the DITIB API.
    @Published private(set) var lastErrorMessage: String?
    /// True while a single location request is in flight.
    @Published private(set) var isFetching: Bool = false

    // MARK: - Bindings (weak — owners outlive this object)

    private weak var appState: AppState?
    private weak var prayerTimeManager: PrayerTimeManager?

    // MARK: - Private

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var pollTimer: Timer?
    private var foregroundObserver: (any NSObjectProtocol)?
    /// Most recent location actually used to update the city — guards against
    /// firing the geocoder + DITIB API for trivial GPS jitter (a few metres).
    private var lastResolvedLocation: CLLocation?
    /// True between `requestLocation()` and the delegate callback so a tick
    /// of the poll timer (or a foreground re-entry) doesn't queue a second one.
    private var requestInFlight = false

    /// 10-minute poll cadence as requested by the spec.
    private static let pollInterval: TimeInterval = 10 * 60
    /// Skip the geocode/API roundtrip if the new GPS reading is within this
    /// distance (meters) of the last resolved location — well below city size.
    private static let minMovementMeters: CLLocationDistance = 500

    // MARK: - Init

    override init() {
        self.authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Wires this updater up to the global app state. Call once after the
    /// `AppState` and `PrayerTimeManager` instances are created.
    func bind(appState: AppState, prayerTimeManager: PrayerTimeManager) {
        self.appState = appState
        self.prayerTimeManager = prayerTimeManager
    }

    // MARK: - Lifecycle

    /// Begin polling. If permission has not yet been requested, this prompts
    /// the user. If permission is denied, it surfaces an error message and
    /// flips `appState.autoLocationEnabled` back off so the toggle reflects
    /// reality.
    func start() {
        let status = locationManager.authorizationStatus
        authorizationStatus = status
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Continue once the user grants — handled in didChangeAuthorization.
        case .authorizedWhenInUse, .authorizedAlways:
            lastErrorMessage = nil
            schedulePollTimer()
            observeForeground()
            requestLocationOnce()
        case .denied, .restricted:
            lastErrorMessage = "Standortzugriff verweigert. Bitte in den iOS-Einstellungen erlauben."
            appState?.autoLocationEnabled = false
        @unknown default:
            break
        }
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
            foregroundObserver = nil
        }
        requestInFlight = false
        isFetching = false
    }

    /// Force a single location read outside the timer cadence (e.g. when the
    /// user re-enables the toggle). Safe to call repeatedly — subsequent calls
    /// are coalesced while a request is already in flight.
    func requestLocationOnce() {
        guard !requestInFlight else { return }
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return }
        requestInFlight = true
        isFetching = true
        locationManager.requestLocation()
    }

    // MARK: - Private: timer + foreground

    private func schedulePollTimer() {
        pollTimer?.invalidate()
        let timer = Timer(timeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.requestLocationOnce()
            }
        }
        timer.tolerance = 30
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    private func observeForeground() {
        guard foregroundObserver == nil else { return }
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.requestLocationOnce()
            }
        }
    }

    // MARK: - Resolve location → DITIB city

    private func handleLocation(_ location: CLLocation) async {
        if let last = lastResolvedLocation,
           location.distance(from: last) < Self.minMovementMeters,
           lastDetectedCityName != nil {
            // Negligible movement — keep the existing city, skip the API calls.
            return
        }

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return }

            let candidates = [placemark.locality,
                              placemark.subAdministrativeArea,
                              placemark.subLocality]
                .compactMap { $0 }
                .filter { !$0.isEmpty }

            for name in candidates {
                if let (city, state) = matchInCatalogue(name: name) {
                    await applyMatched(city, state: state, sourceLocation: location)
                    return
                }
            }
            // No catalogue hit: ask the Diyanet search endpoint.
            if let locality = placemark.locality, !locality.isEmpty {
                await searchAndApply(name: locality, sourceLocation: location)
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    /// Looks up `name` in the hardcoded DITIB city catalogue with a case- and
    /// diacritic-insensitive comparison. Returns the matching city + its state.
    private func matchInCatalogue(name: String) -> (DitibHardcodedCity, DitibFederalState)? {
        let target = normalize(name)
        guard !target.isEmpty else { return nil }

        for state in DitibFederalState.germanStates {
            for city in state.hardcodedCities where normalize(city.name) == target {
                return (city, state)
            }
        }
        // Looser fall-back: the locality may carry a suffix the catalogue omits
        // (e.g. "Frankfurt am Main" vs "Frankfurt" — though our catalogue
        // already has the long form, this still helps for "Köln" ⇆ "Cologne").
        for state in DitibFederalState.germanStates {
            for city in state.hardcodedCities {
                let candidate = normalize(city.name)
                if target.hasPrefix(candidate) || candidate.hasPrefix(target) {
                    return (city, state)
                }
            }
        }
        return nil
    }

    private func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func applyMatched(_ city: DitibHardcodedCity,
                              state: DitibFederalState,
                              sourceLocation: CLLocation) async {
        guard let appState, let prayerTimeManager else { return }

        let districtId: String
        if let known = city.districtId {
            districtId = known
        } else if let resolved = try? await DitibAPIService.shared.searchDistrict(name: city.name),
                  !resolved.isEmpty {
            districtId = resolved
        } else {
            // Couldn't resolve — leave current city untouched.
            return
        }

        let resolvedCity = DitibCity(id: districtId,
                                     name: city.name,
                                     stateId: state.diyanetStateId)
        commit(resolvedCity, sourceLocation: sourceLocation, appState: appState,
               prayerTimeManager: prayerTimeManager)
    }

    private func searchAndApply(name: String, sourceLocation: CLLocation) async {
        guard let appState, let prayerTimeManager else { return }
        guard let cities = try? await DitibAPIService.shared.searchCitiesInGermany(query: name),
              let first = cities.first else { return }
        commit(first, sourceLocation: sourceLocation, appState: appState,
               prayerTimeManager: prayerTimeManager)
    }

    private func commit(_ city: DitibCity,
                        sourceLocation: CLLocation,
                        appState: AppState,
                        prayerTimeManager: PrayerTimeManager) {
        lastDetectedCityName = city.name
        lastResolvedLocation = sourceLocation
        lastErrorMessage = nil

        if appState.selectedDitibCity?.id == city.id {
            // Same city we already had — no need to thrash the API or widget.
            return
        }
        appState.updateDitibCity(city)
        prayerTimeManager.loadPrayerTimes(ditibCity: city)
    }

    deinit {
        pollTimer?.invalidate()
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationAutoUpdater: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.lastErrorMessage = nil
                if self.appState?.autoLocationEnabled == true {
                    self.schedulePollTimer()
                    self.observeForeground()
                    self.requestLocationOnce()
                }
            case .denied, .restricted:
                self.lastErrorMessage = "Standortzugriff verweigert. Bitte in den iOS-Einstellungen erlauben."
                self.stop()
                self.appState?.autoLocationEnabled = false
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.requestInFlight = false
            self.isFetching = false
            await self.handleLocation(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.requestInFlight = false
            self.isFetching = false
            // kCLErrorLocationUnknown is transient — CoreLocation will keep
            // trying. Don't surface it as a user-facing error.
            if (error as NSError).code != CLError.locationUnknown.rawValue {
                self.lastErrorMessage = error.localizedDescription
            }
        }
    }
}
