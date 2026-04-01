// Path: DeenApp/Views/CitySelectionView.swift
//
//  CitySelectionView.swift
//  DeenApp
//
//  Step 2 of the hierarchical location picker.
//  Cities are loaded via search-as-you-type (the Diyanet bulk-list endpoint
//  is unavailable). Results are filtered server-side via the search API and
//  then narrowed client-side to the selected Bundesland using its Diyanet state_id.
//

import SwiftUI

struct CitySelectionView: View {

    let state: DitibFederalState
    @ObservedObject var locationVM: LocationSearchViewModel
    let onDone: () -> Void

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var prayerTimeManager: PrayerTimeManager

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            Group {
                if locationVM.isLoadingCityList {
                    loadingOverlay

                } else if let error = locationVM.loadError {
                    errorState(message: error)

                } else if locationVM.cityList.isEmpty {
                    emptyState

                } else {
                    populatedList(locationVM.displayCities)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: locationVM.isLoadingCityList)
            .animation(.easeInOut(duration: 0.15), value: locationVM.cityList.isEmpty)
        }
        .navigationTitle(state.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
        .searchable(
            text: $locationVM.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Stadt suchen…"
        )
        .onAppear { locationVM.loadCitiesForState(state) }
        .onChange(of: locationVM.searchText) {
            locationVM.performSearch()
        }
    }

    // MARK: - City List

    private func populatedList(_ cities: [DitibCity]) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(cities.enumerated()), id: \.element.id) { index, city in
                    CityRowView(
                        city: city,
                        isSelected: appState.selectedDitibCity?.id == city.id
                    )
                    .onTapGesture { handleSelection(city) }

                    if index < cities.count - 1 {
                        Divider()
                            .overlay(Theme.textSecondary.opacity(0.12))
                            .padding(.leading, 16)
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

    // MARK: - Supporting Views

    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Theme.accent)
                .scaleEffect(1.3)
            Text("Städte werden gesucht…")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 38))
                .foregroundColor(Theme.textSecondary.opacity(0.5))
            Text("Suche fehlgeschlagen")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button(action: { locationVM.performSearch() }) {
                Text("Erneut versuchen")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Theme.accent)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 32)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            if locationVM.searchText.isEmpty {
                // No search entered yet — prompt the user
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 38))
                    .foregroundColor(Theme.accent.opacity(0.6))
                Text("Stadt eingeben")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text("Tippe oben deinen Stadtnamen ein,\num Städte in \(state.name) zu finden.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                // Search returned nothing
                Image(systemName: "xmark.circle")
                    .font(.system(size: 38))
                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                Text("Keine Ergebnisse")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text("Anderen Suchbegriff versuchen")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Actions

    private func handleSelection(_ city: DitibCity) {
        locationVM.confirmCity(city, appState: appState, prayerTimeManager: prayerTimeManager)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onDone()
    }
}

// MARK: - City Row

private struct CityRowView: View {
    let city: DitibCity
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(city.name)
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
