//
//  HomeCityPickerView.swift
//  DeenApp
//
//  Hierarchical picker for the user's "Heimatstadt".
//  Reuses the same hardcoded German DITIB catalogue (state → city), but on
//  selection geocodes the city name to lat/lon and stores a HomeCity in
//  AppState — without touching the active prayer-time city or the recents
//  list (those flows belong to LocationSearchViewModel).
//

import SwiftUI
import CoreLocation

struct HomeCityPickerView: View {

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private let states: [DitibFederalState] = DitibFederalState.germanStates

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(states) { state in
                        NavigationLink {
                            HomeCityList(state: state, onPicked: { dismiss() })
                                .environmentObject(appState)
                        } label: {
                            stateRow(state)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Heimatstadt wählen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
    }

    private func stateRow(_ state: DitibFederalState) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "house.fill")
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
    }
}

// MARK: - City list for a Bundesland

private struct HomeCityList: View {
    let state: DitibFederalState
    let onPicked: () -> Void

    @EnvironmentObject var appState: AppState

    @State private var isResolving = false
    @State private var resolveError: String? = nil
    @State private var resolvingCityName: String? = nil

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    let cities = state.hardcodedCities
                    ForEach(Array(cities.enumerated()), id: \.element.id) { index, city in
                        row(for: city)
                            .onTapGesture {
                                Task { await resolveAndStore(city) }
                            }
                            .disabled(isResolving)
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
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            if isResolving {
                Color.black.opacity(0.28).ignoresSafeArea()
                VStack(spacing: 14) {
                    ProgressView().tint(Theme.accent).scaleEffect(1.3)
                    Text(resolvingCityName.map { "Standort wird ermittelt: \($0)" } ?? "Standort wird ermittelt…")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Theme.textPrimary)
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.cardBackground)
                )
            }
        }
        .navigationTitle(state.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
        .alert("Fehler", isPresented: Binding(
            get: { resolveError != nil },
            set: { if !$0 { resolveError = nil } }
        )) {
            Button("OK", role: .cancel) { resolveError = nil }
        } message: {
            Text(resolveError ?? "")
        }
    }

    private func row(for city: DitibHardcodedCity) -> some View {
        let isSelected = appState.homeCity?.name.caseInsensitiveCompare(city.name) == .orderedSame
        return HStack(spacing: 12) {
            Image(systemName: isSelected ? "house.circle.fill" : "house.circle")
                .font(.system(size: 20))
                .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary.opacity(0.35))
                .frame(width: 28)
            Text(city.name)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.accent)
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private func resolveAndStore(_ city: DitibHardcodedCity) async {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isResolving = true
        resolvingCityName = city.name
        defer {
            isResolving = false
            resolvingCityName = nil
        }

        let geocoder = CLGeocoder()
        let query = "\(city.name), Deutschland"
        do {
            let placemarks = try await geocoder.geocodeAddressString(query)
            guard let coord = placemarks.first?.location?.coordinate else {
                resolveError = "Koordinaten für \(city.name) konnten nicht ermittelt werden."
                return
            }
            let home = HomeCity(name: city.name,
                                latitude: coord.latitude,
                                longitude: coord.longitude)
            appState.updateHomeCity(home)
            onPicked()
        } catch {
            resolveError = "Geocoding fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}
