//
//  PrayerSelectionView.swift
//  DeenApp
//
//  Einstiegsansicht für den "Gebet"-Tab: Geschlechtsauswahl → Gebetsauswahl → Tutorial.
//

import SwiftUI

struct PrayerSelectionView: View {
    @Environment(PrayerTutorialViewModel.self) private var viewModel
    @EnvironmentObject var appState: AppState

    @State private var navigateToTutorial = false
    @State private var showDisplaySettings = false

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Theme.sectionSpacing) {
                    genderSection
                    if viewModel.selectedGender != nil {
                        prayerListSection
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
                .animation(.easeInOut(duration: 0.35), value: viewModel.selectedGender)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(L10n.tabGebet(appState.appLanguage))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDisplaySettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showDisplaySettings) {
                PrayerDisplaySettingsView()
            }
            .navigationDestination(isPresented: $navigateToTutorial) {
                PrayerTutorialView()
            }
        }
    }

    // MARK: - Gender Selection

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Geschlecht wählen")
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.textSection)
                .textCase(.uppercase)
                .tracking(1.2)

            HStack(spacing: 14) {
                ForEach(Gender.allCases) { gender in
                    GenderButton(
                        gender: gender,
                        isSelected: viewModel.selectedGender == gender
                    ) {
                        viewModel.selectedGender = gender
                    }
                }
            }
        }
    }

    // MARK: - Prayer List

    private var prayerListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Gebet auswählen")
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.textSection)
                .textCase(.uppercase)
                .tracking(1.2)

            PrayerListButton(
                title: "Morgengebet (Fajr)",
                subtitle: "2 Rak'at Pflicht · Hanafi",
                icon: "sunrise.fill",
                accentColor: Theme.iconFajr
            ) {
                viewModel.loadSteps(for: "fajr_fard")
                navigateToTutorial = true
            }

            PrayerListButton(
                title: "Mittagsgebet (Dhuhr)",
                subtitle: "4 Rak'at Pflicht · Hanafi",
                icon: "sun.max.fill",
                accentColor: Color(hex: "FFD54F")
            ) {
                viewModel.loadSteps(for: "dhuhr_fard")
                navigateToTutorial = true
            }

            PrayerListButton(
                title: "Nachmittagsgebet (Asr)",
                subtitle: "4 Rak'at Pflicht · Hanafi",
                icon: "sun.haze.fill",
                accentColor: Color(hex: "FFB74D")
            ) {
                viewModel.loadSteps(for: "asr_fard")
                navigateToTutorial = true
            }

            PrayerListButton(
                title: "Abendgebet (Maghrib)",
                subtitle: "3 Rak'at Pflicht · Hanafi",
                icon: "sunset.fill",
                accentColor: Color(hex: "FF7043")
            ) {
                viewModel.loadSteps(for: "maghrib_fard")
                navigateToTutorial = true
            }

            PrayerListButton(
                title: "Nachtgebet (Isha)",
                subtitle: "4 Rak'at Pflicht · Hanafi",
                icon: "moon.stars.fill",
                accentColor: Theme.accent
            ) {
                viewModel.loadSteps(for: "isha_fard")
                navigateToTutorial = true
            }
        }
    }
}

// MARK: - Gender Button

private struct GenderButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: gender.iconName)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isSelected ? Theme.background : Theme.accent)

                Text(gender.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isSelected ? Theme.background : Theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .fill(isSelected ? Theme.accent : Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .strokeBorder(
                        isSelected ? Theme.accent : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Prayer List Button

private struct PrayerListButton: View {
    let title: String
    let subtitle: String
    let icon: String
    var accentColor: Color = Theme.accent
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(accentColor)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(accentColor.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(disabled ? Theme.textSecondary : Theme.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                if !disabled {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Theme.accent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .fill(Theme.cardBackground)
                    .shadow(color: Theme.shadowColor, radius: 6, x: 0, y: 3)
            )
            .opacity(disabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

// MARK: - Preview

#Preview {
    PrayerSelectionView()
        .environment(PrayerTutorialViewModel())
        .environmentObject(AppState())
}
