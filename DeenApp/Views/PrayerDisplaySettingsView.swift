//
//  PrayerDisplaySettingsView.swift
//  DeenApp
//
//  Einstellungen für die Anzeige von Arabisch, Transliteration und Übersetzung.
//


import SwiftUI

struct PrayerDisplaySettingsView: View {
    @AppStorage("showArabic") var showArabic: Bool = true
    @AppStorage("showTransliteration") var showTransliteration: Bool = true
    @AppStorage("showTranslation") var showTranslation: Bool = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.sectionSpacing) {
                        VStack(spacing: 0) {
                            settingsRow(
                                title: "Arabischer Text",
                                subtitle: "Koranvers und Dua in Arabisch",
                                isOn: $showArabic
                            )
                            Divider()
                                .background(Theme.textSecondary.opacity(0.3))
                                .padding(.leading, Theme.cardPadding)
                            settingsRow(
                                title: "Transliteration",
                                subtitle: "Aussprache in lateinischer Schrift",
                                isOn: $showTransliteration
                            )
                            Divider()
                                .background(Theme.textSecondary.opacity(0.3))
                                .padding(.leading, Theme.cardPadding)
                            settingsRow(
                                title: "Übersetzung",
                                subtitle: "Deutsche Bedeutung",
                                isOn: $showTranslation
                            )
                        }
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))

                        Text("Die Schriftgröße im Tutorial passt sich automatisch an die gewählten Optionen an.")
                            .font(.footnote)
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, Theme.cardPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Gebet-Anzeige")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }

    private func settingsRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.vertical, 4)
        }
        .tint(Theme.accent)
        .padding(.horizontal, Theme.cardPadding)
        .padding(.vertical, 12)
    }
}

#Preview {
    PrayerDisplaySettingsView()
}
