//
//  PrayerDisplaySettingsView.swift
//  DeenApp
//
//  Einstellungen für die Anzeige von Arabisch, Transliteration, DMG und Übersetzung.
//


import SwiftUI

struct PrayerDisplaySettingsView: View {
    @AppStorage("showArabic") var showArabic: Bool = true
    @AppStorage("showTransliteration") var showTransliteration: Bool = true
    @AppStorage("showDMGTransliteration") var showDMGTransliteration: Bool = true
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
                            displayOptionRow(
                                title: "Arabischer Text",
                                subtitle: "Koranvers und Dua in Arabisch",
                                isOn: $showArabic,
                                previewStyle: PrayerBasmalaPreviewSnippetView.Style.arabic
                            )
                            Divider()
                                .background(Theme.textSecondary.opacity(0.3))
                                .padding(.leading, Theme.cardPadding)
                            displayOptionRow(
                                title: "Transliteration",
                                subtitle: "Aussprache in lateinischer Schrift",
                                isOn: $showTransliteration,
                                previewStyle: PrayerBasmalaPreviewSnippetView.Style.simplifiedLatin
                            )
                            Divider()
                                .background(Theme.textSecondary.opacity(0.3))
                                .padding(.leading, Theme.cardPadding)
                            displayOptionRow(
                                title: "DMG-Transliteration",
                                subtitle: "Wissenschaftliche Umschrift (Deutsche Morgenländische Gesellschaft)",
                                isOn: $showDMGTransliteration,
                                previewStyle: PrayerBasmalaPreviewSnippetView.Style.dmgLatin
                            )
                            Divider()
                                .background(Theme.textSecondary.opacity(0.3))
                                .padding(.leading, Theme.cardPadding)
                            displayOptionRow(
                                title: "Übersetzung",
                                subtitle: "Deutsche Bedeutung",
                                isOn: $showTranslation,
                                previewStyle: PrayerBasmalaPreviewSnippetView.Style.german
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

    private func displayOptionRow(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        previewStyle: PrayerBasmalaPreviewSnippetView.Style
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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

            PrayerBasmalaPreviewSnippetView(style: previewStyle)
        }
        .padding(.horizontal, Theme.cardPadding)
        .padding(.vertical, 12)
    }
}

#Preview {
    PrayerDisplaySettingsView()
}
