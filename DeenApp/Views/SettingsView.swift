//
//  SettingsView.swift
//  DeenApp
//
//  Einstellungen: Name, Sprache, Standort, Zeitrechnungsmethode.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var prayerTimeManager: PrayerTimeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var nameInput: String = ""
    @StateObject private var locationVM = LocationSearchViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: - Name
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text(L10n.settingsName(appState.appLanguage))
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Theme.accent)
                                }

                                TextField(L10n.settingsNamePlaceholder(appState.appLanguage), text: $nameInput)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Theme.background)
                                    )
                                    .foregroundColor(Theme.textPrimary)
                                    .autocorrectionDisabled()
                                    .onSubmit { appState.updateName(nameInput) }
                                    .onChange(of: nameInput) { _, newValue in
                                        appState.updateName(newValue)
                                    }
                            }
                        }

                        // MARK: - Sprache
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text(L10n.onboardingLanguagePrompt(appState.appLanguage))
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "globe")
                                        .foregroundColor(Theme.accent)
                                }

                                ForEach(AppLanguage.allCases) { lang in
                                    Button(action: { appState.updateLanguage(lang) }) {
                                        HStack {
                                            Text(lang.displayName)
                                                .font(.body)
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()
                                            if appState.appLanguage == lang {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Theme.accent)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                    }
                                    if lang != AppLanguage.allCases.last {
                                        Divider().overlay(Theme.textSecondary.opacity(0.2))
                                    }
                                }
                            }
                        }

                        // MARK: - App Theme (Akzentfarbe)
                        settingsCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Label {
                                    Text("Akzentfarbe")
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "paintpalette.fill")
                                        .foregroundColor(Theme.accent)
                                }

                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                                    spacing: 10
                                ) {
                                    ForEach(ThemeColor.allCases) { theme in
                                        Button(action: { appState.updateAccentTheme(theme) }) {
                                            ZStack {
                                                Circle()
                                                    .fill(theme.color)
                                                    .frame(width: 38, height: 38)
                                                if appState.accentTheme == theme {
                                                    Circle()
                                                        .strokeBorder(accentSelectionRingColor, lineWidth: 2.5)
                                                        .frame(width: 38, height: 38)
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 11, weight: .bold))
                                                        .foregroundColor(.primary)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(theme.displayName)
                                    }
                                }

                                Text(appState.accentTheme.displayName)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(Theme.accent)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }

                        // MARK: - Standort (Dynamic DITIB picker)
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text(L10n.settingsLocation(appState.appLanguage))
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(Theme.accent)
                                }

                                // Current selection
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(appState.selectedDitibCity?.name ?? appState.selectedCity.displayName)
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(Theme.textPrimary)
                                        Text("Aktuell ausgewählt")
                                            .font(.caption)
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.accent)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 4)

                                // Recent cities — shown directly (no hidden button)
                                if !locationVM.recentCities.isEmpty {
                                    Divider().overlay(Theme.textSecondary.opacity(0.2))

                                    Label("Zuletzt verwendet", systemImage: "clock.arrow.circlepath")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Theme.textSecondary)
                                        .padding(.horizontal, 4)

                                    ForEach(locationVM.recentCities) { city in
                                        Button(action: {
                                            locationVM.confirmCity(city, appState: appState, prayerTimeManager: prayerTimeManager)
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        }) {
                                            HStack(spacing: 10) {
                                                Image(systemName: "clock")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(Theme.textSecondary.opacity(0.6))
                                                    .frame(width: 20)
                                                Text(city.name)
                                                    .font(.body)
                                                    .foregroundColor(Theme.textPrimary)
                                                Spacer()
                                                if appState.selectedDitibCity?.id == city.id {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(Theme.accent)
                                                }
                                            }
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                Divider().overlay(Theme.textSecondary.opacity(0.2))

                                // Navigate to full state → city picker
                                NavigationLink {
                                    StateSelectionView(locationVM: locationVM)
                                        .environmentObject(appState)
                                        .environmentObject(prayerTimeManager)
                                } label: {
                                    HStack {
                                        Text("Neuen Ort wählen")
                                            .font(.body)
                                            .foregroundColor(Theme.accent)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                }
                            }
                        }

                        // MARK: - Gebetszeiten-Quelle
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text(L10n.settingsPrayerSource(appState.appLanguage))
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .foregroundColor(Theme.accent)
                                }

                                ForEach(PrayerTimeProvider.allCases) { provider in
                                    Button(action: {
                                        appState.updatePrayerTimeProvider(provider)
                                        if let city = appState.selectedDitibCity {
                                            prayerTimeManager.loadPrayerTimes(ditibCity: city)
                                        }
                                    }) {
                                        HStack {
                                            Text(provider.displayName)
                                                .font(.body)
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()
                                            if appState.prayerTimeProvider == provider {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Theme.accent)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                    }
                                    if provider != PrayerTimeProvider.allCases.last {
                                        Divider().overlay(Theme.textSecondary.opacity(0.2))
                                    }
                                }
                            }
                        }

                        // MARK: - Zeitrechnungsmethode (Aladhan / Fazilet / Custom)
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text(L10n.settingsCalculationMethod(appState.appLanguage))
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(Theme.accent)
                                }

                                if appState.prayerTimeProvider == .ditib {
                                    Text("Voreinstellung und eigene Parameter wirken bei der Quelle „Aladhan API“. DITIB liefert feste Vakitler.")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }

                                ForEach(AladhanPresetCalculation.allCases) { preset in
                                    Button(action: {
                                        appState.updatePrayerCalculation(.preset(preset))
                                        if let city = appState.selectedDitibCity {
                                            prayerTimeManager.loadPrayerTimes(ditibCity: city)
                                        }
                                    }) {
                                        HStack {
                                            Text(preset.displayName)
                                                .font(.body)
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()
                                            if appState.prayerCalculation.presetValue == preset, !appState.prayerCalculation.isCustom {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Theme.accent)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                    }
                                    if preset != AladhanPresetCalculation.allCases.last {
                                        Divider().overlay(Theme.textSecondary.opacity(0.2))
                                    }
                                }

                                Divider().overlay(Theme.textSecondary.opacity(0.2))

                                NavigationLink {
                                    CustomPrayerCalculationView()
                                        .environmentObject(appState)
                                        .environmentObject(prayerTimeManager)
                                } label: {
                                    HStack {
                                        Text("Selber rechnen")
                                            .font(.body)
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        if appState.prayerCalculation.isCustom {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Theme.accent)
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(Theme.textSecondary.opacity(0.6))
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle(L10n.settingsTitle(appState.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.settingsDone(appState.appLanguage)) { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .onAppear { nameInput = appState.userName }
        }
    }

    private var accentSelectionRingColor: Color {
        colorScheme == .dark ? Color.white : Color.black.opacity(0.85)
    }

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.cardBackground)
            )
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(PrayerTimeManager())
}
