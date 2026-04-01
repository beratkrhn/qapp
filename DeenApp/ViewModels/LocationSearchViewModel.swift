// Path: DeenApp/ViewModels/LocationSearchViewModel.swift
//
//  LocationSearchViewModel.swift
//  DeenApp
//
//  Hierarchical DITIB city selection:
//
//  1. Recent locations — persisted in UserDefaults, shown at the top of StateSelectionView.
//  2. Hardcoded city catalogue — cities are shown instantly per Bundesland with no typing.
//     On selection the VM resolves the Diyanet district ID (baked-in when known; API search
//     otherwise) and then triggers the prayer-time fetch.
//

import Foundation
import Combine

@MainActor
final class LocationSearchViewModel: ObservableObject {

    // MARK: - Persistence keys

    private enum Keys {
        static let recentCities = "dailydee.recentCities"
    }
    private static let maxRecentCities = 5

    // MARK: - States (hardcoded, always ready)

    let states: [DitibFederalState] = DitibFederalState.germanStates

    // MARK: - Recent locations

    @Published private(set) var recentCities: [DitibCity] = []

    // MARK: - City confirmation state

    /// True while the district-ID resolution + prayer-time fetch is in flight.
    @Published private(set) var isConfirmingCity = false

    /// Non-nil when city confirmation fails; cleared automatically on the next attempt.
    @Published private(set) var confirmationError: String? = nil

    // MARK: - Init

    init() {
        loadRecents()
    }

    // MARK: - Hardcoded catalogue

    /// Returns the sorted, hardcoded DITIB city list for `state`.
    func cities(for state: DitibFederalState) -> [DitibHardcodedCity] {
        state.hardcodedCities
    }

    // MARK: - City selection (hardcoded list)

    /// Resolves the Diyanet district ID for `city` (uses the cached value when available,
    /// otherwise performs a single API search), then triggers the prayer-time fetch.
    /// `onSuccess` is called on the main actor after a successful confirmation.
    func selectCity(
        _ city: DitibHardcodedCity,
        inState state: DitibFederalState,
        appState: AppState,
        prayerTimeManager: PrayerTimeManager,
        onSuccess: @escaping () -> Void
    ) {
        isConfirmingCity = true
        confirmationError = nil

        Task {
            let districtId: String

            if let known = city.districtId {
                // ID is baked into the catalogue — no API call needed for resolution.
                districtId = known
            } else {
                guard let resolved = try? await DitibAPIService.shared.searchDistrict(name: city.name),
                      !resolved.isEmpty else {
                    confirmationError = "Stadt nicht gefunden. Bitte erneut versuchen."
                    isConfirmingCity = false
                    return
                }
                districtId = resolved
            }

            let resolvedCity = DitibCity(id: districtId, name: city.name, stateId: state.diyanetStateId)
            confirmCity(resolvedCity, appState: appState, prayerTimeManager: prayerTimeManager)
            isConfirmingCity = false
            onSuccess()
        }
    }

    // MARK: - Confirmation (used for recent-city re-selection too)

    func confirmCity(
        _ city: DitibCity,
        appState: AppState,
        prayerTimeManager: PrayerTimeManager
    ) {
        appState.updateDitibCity(city)
        prayerTimeManager.loadPrayerTimes(ditibCity: city)
        appendRecent(city)
    }

    // MARK: - Private: recents persistence

    private func loadRecents() {
        guard let data   = UserDefaults.standard.data(forKey: Keys.recentCities),
              let cities = try? JSONDecoder().decode([DitibCity].self, from: data) else { return }
        recentCities = cities
    }

    private func appendRecent(_ city: DitibCity) {
        var updated = recentCities.filter { $0.id != city.id }
        updated.insert(city, at: 0)
        recentCities = Array(updated.prefix(Self.maxRecentCities))
        if let data = try? JSONEncoder().encode(recentCities) {
            UserDefaults.standard.set(data, forKey: Keys.recentCities)
        }
    }
}
