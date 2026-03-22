//
//  CustomPrayerCalculationView.swift
//  DeenApp
//
//  Benutzerdefinierte Aladhan-Berechnung: method=99, Winkel + Minuten-Offsets.
//

import SwiftUI

struct CustomPrayerCalculationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var prayerTimeManager: PrayerTimeManager
    @Environment(\.dismiss) private var dismiss

    @State private var draft = CustomPrayerParameters.default

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            Form {
                Section {
                    Text("Winkel und Maghrib entsprechen der Aladhan-Parameter `methodSettings` (Fajr, Maghrib, Isha). Minuten-Offsets entsprechen `tune` (Reihenfolge laut Aladhan-Doku).")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .listRowBackground(Theme.cardBackground)
                }

                Section("Winkel & Maghrib") {
                    HStack {
                        Text("Fajr-Winkel (°)")
                        Spacer()
                        TextField("", value: $draft.fajrAngle, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                    }
                    .listRowBackground(Theme.cardBackground)

                    Stepper(value: $draft.maghribMinutesAfterSunset, in: 0...30) {
                        Text("Maghrib nach Sonnenuntergang: \(draft.maghribMinutesAfterSunset) min")
                    }
                    .listRowBackground(Theme.cardBackground)

                    HStack {
                        Text("Isha-Winkel (°)")
                        Spacer()
                        TextField("", value: $draft.ishaAngle, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                    }
                    .listRowBackground(Theme.cardBackground)
                }

                Section("Minuten-Offsets (tune)") {
                    tuneStepper(title: "İmsak", value: $draft.offsetImsak)
                    tuneStepper(title: "Fajr", value: $draft.offsetFajr)
                    tuneStepper(title: "Sonnenaufgang", value: $draft.offsetSunrise)
                    tuneStepper(title: "Dhuhr", value: $draft.offsetDhuhr)
                    tuneStepper(title: "Asr", value: $draft.offsetAsr)
                    tuneStepper(title: "Maghrib", value: $draft.offsetMaghrib)
                    tuneStepper(title: "Isha", value: $draft.offsetIsha)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Eigene Berechnung")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Zurück") { dismiss() }
                    .foregroundColor(Theme.accent)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Übernehmen") {
                    appState.updatePrayerCalculation(.custom(draft))
                    prayerTimeManager.loadPrayerTimes(
                        for: appState.selectedCity,
                        calculation: .custom(draft),
                        provider: appState.prayerTimeProvider
                    )
                    dismiss()
                }
                .foregroundColor(Theme.accent)
            }
        }
        .onAppear {
            draft = appState.prayerCalculation.customValue ?? .default
        }
    }

    private func tuneStepper(title: String, value: Binding<Int>) -> some View {
        Stepper(value: value, in: -30...30) {
            Text("\(title): \(value.wrappedValue > 0 ? "+" : "")\(value.wrappedValue) min")
                .foregroundColor(Theme.textPrimary)
        }
        .listRowBackground(Theme.cardBackground)
    }
}

#Preview {
    NavigationStack {
        CustomPrayerCalculationView()
            .environmentObject(AppState())
            .environmentObject(PrayerTimeManager())
    }
}
