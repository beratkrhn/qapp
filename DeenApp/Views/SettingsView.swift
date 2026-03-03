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

                        // MARK: - App Theme
                        settingsCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Label {
                                    Text("App Theme")
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                } icon: {
                                    Image(systemName: "paintpalette.fill")
                                        .foregroundColor(Theme.accent)
                                }

                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7),
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
                                                        .strokeBorder(Color.white, lineWidth: 2.5)
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
                                        prayerTimeManager.loadPrayerTimes(for: city, method: appState.calculationMethod)
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

                        // MARK: - Zeitrechnungsmethode
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

                                ForEach(CalculationMethod.allCases) { method in
                                    Button(action: {
                                        appState.updateCalculationMethod(method)
                                        prayerTimeManager.loadPrayerTimes(for: appState.selectedCity, method: method)
                                    }) {
                                        HStack {
                                            Text(method.displayName)
                                                .font(.body)
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()
                                            if appState.calculationMethod == method {
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
                                    if method != CalculationMethod.allCases.last {
                                        Divider().overlay(Theme.textSecondary.opacity(0.2))
                                    }
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
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.settingsDone(appState.appLanguage)) { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .onAppear { nameInput = appState.userName }
        }
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
