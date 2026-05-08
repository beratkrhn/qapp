//
//  QiblaCompassViewModel.swift
//  DeenApp
//
//  Drives the Qibla compass UI:
//    • Live magnetic/true heading via CLLocationManager.startUpdatingHeading.
//    • Initial-bearing computation from the current GPS position to the
//      Kaaba (21.4225° N, 39.8262° E).
//    • Great-circle (Luftlinie) distance from current GPS to the user's
//      Heimatstadt; emits an `isSeferi` flag once the distance crosses 90 km
//      — the classical Hanafi Seferi threshold (~3 days' travel).
//

import Foundation
import Combine
import CoreLocation

@MainActor
final class QiblaCompassViewModel: NSObject, ObservableObject {

    // MARK: - Constants

    /// Coordinates of the Kaaba inside the Masjid al-Haram, Mecca.
    static let kaabaLatitude: Double  = 21.4225
    static let kaabaLongitude: Double = 39.8262
    /// Hanafi-school Seferi threshold — straight-line distance from home above
    /// which the traveler may shorten obligatory prayers.
    static let seferThresholdKm: Double = 90.0

    // MARK: - Published state

    /// Device heading in degrees (0° = true north, clockwise positive).
    @Published private(set) var headingDegrees: Double = 0
    /// Initial bearing from the current location to the Kaaba (0° = N, CW).
    @Published private(set) var qiblaBearing: Double = 0
    /// Great-circle distance from the current location to the home city, km.
    @Published private(set) var distanceToHomeKm: Double?
    /// `true` once `distanceToHomeKm` exceeds the Seferi threshold.
    @Published private(set) var isSeferi: Bool = false
    /// True after the first valid GPS fix has been received.
    @Published private(set) var hasLocation: Bool = false
    /// Mirrors the system authorization status for the UI.
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    /// Last localized error surfaced to the UI.
    @Published private(set) var errorMessage: String?
    /// True while the heading reading is unreliable and needs calibration.
    @Published private(set) var needsCalibration: Bool = false

    // MARK: - Private

    private let locationManager = CLLocationManager()
    private weak var appState: AppState?
    private var cancellables: Set<AnyCancellable> = []
    private var lastLocation: CLLocation?

    // MARK: - Init

    override init() {
        self.authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.headingFilter = 1
        locationManager.headingOrientation = .portrait
    }

    func bind(appState: AppState) {
        self.appState = appState
        // Re-evaluate Seferi state if the user changes their home city while
        // the compass is open.
        appState.$homeCity
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.recomputeDistanceAndSeferi() }
            .store(in: &cancellables)
    }

    // MARK: - Lifecycle

    /// Begin streaming heading + location. If permission has not yet been
    /// requested, this prompts the user.
    func start() {
        let status = locationManager.authorizationStatus
        authorizationStatus = status
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            errorMessage = nil
            beginUpdates()
        case .denied, .restricted:
            errorMessage = "Standortzugriff verweigert. Bitte in den iOS-Einstellungen erlauben, sonst kann der Qibla-Kompass die Richtung nicht berechnen."
        @unknown default:
            break
        }
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    private func beginUpdates() {
        locationManager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        } else {
            errorMessage = "Dieses Gerät besitzt keinen Magnetometer-Sensor — der Kompass kann die Blickrichtung nicht erkennen."
        }
    }

    // MARK: - Math

    /// Initial bearing from `from` to `to`, in degrees (0–360, clockwise from
    /// true north). Standard great-circle formula on a spherical Earth — the
    /// few-meter error from the ellipsoidal model is irrelevant for a Qibla
    /// arrow shown on a phone screen.
    static func initialBearing(from a: CLLocationCoordinate2D,
                               to b: CLLocationCoordinate2D) -> Double {
        let φ1 = a.latitude  * .pi / 180
        let φ2 = b.latitude  * .pi / 180
        let Δλ = (b.longitude - a.longitude) * .pi / 180
        let y = sin(Δλ) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
        let θ = atan2(y, x) * 180 / .pi
        return (θ + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Great-circle (Luftlinie) distance in kilometers between two points.
    /// Uses CLLocation's built-in haversine implementation so we don't have
    /// to maintain our own.
    static func distanceKm(from a: CLLocationCoordinate2D,
                           to b: CLLocationCoordinate2D) -> Double {
        let l1 = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let l2 = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return l1.distance(from: l2) / 1000.0
    }

    // MARK: - Recompute helpers

    private func recomputeDistanceAndSeferi() {
        guard let location = lastLocation, let home = appState?.homeCity else {
            distanceToHomeKm = nil
            isSeferi = false
            return
        }
        let km = Self.distanceKm(from: location.coordinate, to: home.coordinate)
        distanceToHomeKm = km
        isSeferi = km > Self.seferThresholdKm
    }

    private func updateQiblaBearing(for location: CLLocation) {
        let kaaba = CLLocationCoordinate2D(latitude: Self.kaabaLatitude,
                                           longitude: Self.kaabaLongitude)
        qiblaBearing = Self.initialBearing(from: location.coordinate, to: kaaba)
    }
}

// MARK: - CLLocationManagerDelegate

extension QiblaCompassViewModel: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.errorMessage = nil
                self.beginUpdates()
            case .denied, .restricted:
                self.errorMessage = "Standortzugriff verweigert. Bitte in den iOS-Einstellungen erlauben."
                self.stop()
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
            self.lastLocation = location
            self.hasLocation = true
            self.errorMessage = nil
            self.updateQiblaBearing(for: location)
            self.recomputeDistanceAndSeferi()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateHeading newHeading: CLHeading) {
        // Use trueHeading when valid (>= 0); fall back to magnetic if the
        // device hasn't yet calibrated against location-derived declination.
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        let needsCal = newHeading.headingAccuracy < 0
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.headingDegrees = value
            self.needsCalibration = needsCal
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        let nsErr = error as NSError
        Task { @MainActor [weak self] in
            guard let self else { return }
            // kCLErrorLocationUnknown is transient; CoreLocation will keep
            // trying. Don't surface it as a user-facing error.
            if nsErr.code != CLError.locationUnknown.rawValue {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        // Let iOS show its built-in figure-8 calibration prompt when needed.
        true
    }
}
