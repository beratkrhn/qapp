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
                                                        .foregroundColor(.white)
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

                        // MARK: - Standort
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

                                ForEach(AppCity.allCases) { city in
                    Button(action: {
                        appState.updateCity(city)
                        prayerTimeManager.loadPrayerTimes(
                            for: city,
                            calculation: appState.prayerCalculation,
                            provider: appState.prayerTimeProvider
                        )
                    }) {
                                        HStack {
                                            Text(city.displayName)
                                                .font(.body)
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()
                                            if appState.selectedCity == city {
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
                                    if city != AppCity.allCases.last {
                                        Divider().overlay(Theme.textSecondary.opacity(0.2))
                                    }
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
                                        prayerTimeManager.loadPrayerTimes(
                                            for: appState.selectedCity,
                                            calculation: appState.prayerCalculation,
                                            provider: provider
                                        )
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
                                        prayerTimeManager.loadPrayerTimes(
                                            for: appState.selectedCity,
                                            calculation: .preset(preset),
                                            provider: appState.prayerTimeProvider
                                        )
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
                                        Text("Eigene Winkel & Minuten-Offsets")
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
