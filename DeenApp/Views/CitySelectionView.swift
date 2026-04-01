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

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            cityListView
                .animation(.easeInOut(duration: 0.15), value: appState.selectedDitibCity?.id)

            if locationVM.isConfirmingCity {
                confirmingOverlay
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .navigationTitle(state.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
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

    // MARK: - City List

    private var cityListView: some View {
        let cities = locationVM.cities(for: state)
        return ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(cities.enumerated()), id: \.element.id) { index, city in
                    CityRowView(
                        city: city,
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
}

// MARK: - City Row

private struct CityRowView: View {
    let city: DitibHardcodedCity
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "mappin.circle.fill" : "mappin.circle")
                .font(.system(size: 20))
                .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary.opacity(0.35))
                .frame(width: 28)
                .animation(.easeInOut(duration: 0.15), value: isSelected)

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
