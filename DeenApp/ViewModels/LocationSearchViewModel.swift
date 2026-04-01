// Path: DeenApp/ViewModels/LocationSearchViewModel.swift
//
//  LocationSearchViewModel.swift
//  DeenApp
//
//  Hierarchical DITIB city selection:
//
//  1. Recent locations — persisted in UserDefaults, shown directly in Settings.
//  2. City search — the Diyanet bulk-list endpoint does not exist (404), so cities
//     are loaded via search-as-you-type. Each search result is filtered client-side
//     to the selected Bundesland using the hardcoded Diyanet state_id.
//     A 350 ms debounce prevents excessive API calls while typing.
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

    // MARK: - Search state

    /// Bound to the .searchable modifier; triggers a debounced API call.
    @Published var searchText: String = ""

    /// Results from the last successful search, filtered to the selected state.
    @Published private(set) var cityList: [DitibCity] = []

    /// True while a search request is in flight.
    @Published private(set) var isLoadingCityList = false

    /// Set when the latest search request fails; cleared on the next search attempt.
    @Published private(set) var loadError: String? = nil

    // MARK: - Internals

    private(set) var selectedState: DitibFederalState? = nil
    private var searchTask: Task<Void, Never>? = nil

    // MARK: - Init

    init() {
        loadRecents()
    }

    // MARK: - Derived

    /// Cities matching the search text (API already filters, so just return cityList).
    var displayCities: [DitibCity] { cityList }

    // MARK: - State setup

    /// Called by CitySelectionView.onAppear — resets all search state for the new state.
    func loadCitiesForState(_ state: DitibFederalState) {
        selectedState = state
        searchText    = ""
        cityList      = []
        loadError     = nil
        isLoadingCityList = false
        searchTask?.cancel()
    }

    func clearState() {
        selectedState = nil
        searchText    = ""
        cityList      = []
        loadError     = nil
        searchTask?.cancel()
    }

    // MARK: - Search trigger

    /// Call this from .onChange(of: searchText) in the view.
    /// Debounces 350 ms then calls the search API, filtering results to selectedState.
    func performSearch() {
        searchTask?.cancel()
        loadError = nil

        guard searchText.count >= 2, let state = selectedState else {
            cityList = []
            isLoadingCityList = false
            return
        }

        isLoadingCityList = true
        let query    = searchText
        let stateId  = state.diyanetStateId

        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            do {
                let results = try await DitibAPIService.shared.searchCitiesInGermany(query: query)
                let filtered = results
                    .filter { $0.stateId == stateId }
                    .sorted { $0.name < $1.name }
                guard !Task.isCancelled else { return }
                cityList = filtered
                isLoadingCityList = false
            } catch {
                guard !Task.isCancelled else { return }
                loadError = "Suche fehlgeschlagen. Bitte erneut versuchen."
                cityList  = []
                isLoadingCityList = false
            }
        }
    }

    // MARK: - Confirmation

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
