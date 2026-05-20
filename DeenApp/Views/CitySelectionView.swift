// Path: DeenApp/Views/CitySelectionView.swift
//
//  CitySelectionView.swift
//  DeenApp
//
//  Step 2 of the hierarchical location picker.
//  Displays the hardcoded, scrollable list of DITIB-supported cities for the
//  selected Bundesland. No search bar — the user scrolls and taps.
//  A brief confirming overlay appears while the ViewModel resolves the Diyanet
//  district ID (if not already cached) and triggers the prayer-time fetch.
//

import SwiftUI

struct CitySelectionView: View {

    let state: DitibFederalState
    @ObservedObject var locationVM: LocationSearchViewModel
    let onDone: () -> Void

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var prayerTimeManager: PrayerTimeManager

    @State private var searchText: String = ""
    @State private var searchResults: [DitibCity] = []
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            content
                .animation(.easeInOut(duration: 0.15), value: appState.selectedDitibCity?.id)

            if locationVM.isConfirmingCity {
                confirmingOverlay
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .navigationTitle(state.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Stadt suchen"
        )
        .onChange(of: searchText) { _, newValue in
            scheduleSearch(for: newValue)
        }
        .alert(
            "Fehler",
            isPresented: Binding(
                get: { locationVM.confirmationError != nil },
                set: { _ in }   // VM clears the error on the next attempt
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(locationVM.confirmationError ?? "")
        }
    }

    // MARK: - Content switcher

    @ViewBuilder
    private var content: some View {
        if trimmedQuery.count >= 2 {
            searchResultsView
        } else {
            cityListView
        }
    }

    // MARK: - City List

    private var cityListView: some View {
        let cities = locationVM.cities(for: state)
        return ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(cities.enumerated()), id: \.element.id) { index, city in
                    CityRowView(
                        name: city.name,
                        isSelected: appState.selectedDitibCity?.name == city.name &&
                                    appState.selectedDitibCity?.stateId == city.stateId
                    )
                    .onTapGesture { handleSelection(city) }
                    .disabled(locationVM.isConfirmingCity)

                    if index < cities.count - 1 {
                        Divider()
                            .overlay(Theme.textSecondary.opacity(0.12))
                            .padding(.leading, 52)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Search results

    private var searchResultsView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if isSearching && searchResults.isEmpty {
                    HStack(spacing: 10) {
                        ProgressView().tint(Theme.accent)
                        Text("Suche…")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.vertical, 24)
                } else if searchResults.isEmpty {
                    Text("Keine Treffer")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.vertical, 24)
                } else {
                    ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, city in
                        CityRowView(
                            name: cityDisplayName(city),
                            isSelected: appState.selectedDitibCity?.id == city.id
                        )
                        .onTapGesture { handleSearchSelection(city) }
                        .disabled(locationVM.isConfirmingCity)

                        if index < searchResults.count - 1 {
                            Divider()
                                .overlay(Theme.textSecondary.opacity(0.12))
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private func cityDisplayName(_ city: DitibCity) -> String {
        let titled = city.name.capitalized(with: Locale(identifier: "de_DE"))
        if city.stateId == state.diyanetStateId { return titled }
        let stateName = DitibFederalState.germanStates.first(where: { $0.diyanetStateId == city.stateId })?.name
        return stateName.map { "\(titled) — \($0)" } ?? titled
    }

    // MARK: - Confirming Overlay

    private var confirmingOverlay: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Theme.accent)
                    .scaleEffect(1.3)

                Text("Stadt wird geladen…")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.cardBackground)
                    .shadow(color: Theme.shadowColor, radius: 24, x: 0, y: 10)
            )
        }
    }

    // MARK: - Actions

    private func handleSelection(_ city: DitibHardcodedCity) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        locationVM.selectCity(
            city,
            inState: state,
            appState: appState,
            prayerTimeManager: prayerTimeManager,
            onSuccess: onDone
        )
    }

    private func handleSearchSelection(_ city: DitibCity) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        locationVM.confirmCity(city, appState: appState, prayerTimeManager: prayerTimeManager)
        onDone()
    }

    // MARK: - Search debounce

    private func scheduleSearch(for raw: String) {
        searchTask?.cancel()
        let q = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }
            let results = (try? await DitibAPIService.shared.searchCitiesInGermany(query: q)) ?? []
            if Task.isCancelled { return }
            // prefer same-state matches first, then everything else
            let same = results.filter { $0.stateId == state.diyanetStateId }
            let other = results.filter { $0.stateId != state.diyanetStateId }
            searchResults = same + other
            isSearching = false
        }
    }
}

// MARK: - City Row

private struct CityRowView: View {
    let name: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "mappin.circle.fill" : "mappin.circle")
                .font(.system(size: 20))
                .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary.opacity(0.35))
                .frame(width: 28)
                .animation(.easeInOut(duration: 0.15), value: isSelected)

            Text(name)
                .font(.body)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.accent)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
