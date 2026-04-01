// Path: DeenApp/Views/StateSelectionView.swift
//
//  StateSelectionView.swift
//  DeenApp
//
//  Step 1 of the hierarchical location picker.
//  - Shows up to 5 recent locations at the top for instant re-selection.
//  - Beneath that, lists all 16 hardcoded German federal states.
//  - No network call needed here — data is local.
//

import SwiftUI

struct StateSelectionView: View {

    @ObservedObject var locationVM: LocationSearchViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var prayerTimeManager: PrayerTimeManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    if !locationVM.recentCities.isEmpty {
                        recentsSection
                    }
                    statesSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Standort wählen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
    }

    // MARK: - Recents Section

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Zuletzt verwendet", icon: "clock.arrow.circlepath")

            VStack(spacing: 0) {
                ForEach(Array(locationVM.recentCities.enumerated()), id: \.element.id) { index, city in
                    RecentCityRowView(
                        city: city,
                        isSelected: appState.selectedDitibCity?.id == city.id
                    )
                    .onTapGesture {
                        locationVM.confirmCity(city, appState: appState, prayerTimeManager: prayerTimeManager)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }

                    if index < locationVM.recentCities.count - 1 {
                        Divider()
                            .overlay(Theme.textSecondary.opacity(0.12))
                            .padding(.leading, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
        }
    }

    // MARK: - States Section

    private var statesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Bundesland waehlen", icon: "map")

            LazyVStack(spacing: 10) {
                ForEach(locationVM.states) { state in
                    NavigationLink {
                        CitySelectionView(
                            state: state,
                            locationVM: locationVM,
                            onDone: { dismiss() }
                        )
                        .environmentObject(appState)
                        .environmentObject(prayerTimeManager)
                    } label: {
                        StateRowView(state: state)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundColor(Theme.textSecondary)
            .padding(.horizontal, 4)
    }
}

// MARK: - Recent City Row

private struct RecentCityRowView: View {
    let city: DitibCity
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary.opacity(0.6))
                .frame(width: 24)

            Text(city.name)
                .font(.body)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.accent)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - State Row

private struct StateRowView: View {
    let state: DitibFederalState

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "map.fill")
                .font(.system(size: 15))
                .foregroundColor(Theme.accent)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Theme.accent.opacity(0.15))
                )

            Text(state.name)
                .font(.body)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary.opacity(0.45))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.cardBackground)
        )
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }
}
