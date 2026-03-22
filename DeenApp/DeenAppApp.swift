//
//  DeenAppApp.swift
//  DeenApp
//
//  Islamische Gebetszeiten & Spiritualität
//

import SwiftUI
<<<<<<< HEAD
=======
import SwiftData
>>>>>>> origin/claude/adoring-banach

@main
struct DeenAppApp: App {
    @StateObject private var prayerTimeManager = PrayerTimeManager()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
<<<<<<< HEAD
            Group {
                if appState.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(prayerTimeManager)
            .environmentObject(appState)
            .preferredColorScheme(appState.preferredSwiftUIColorScheme)
            .task {
                prayerTimeManager.loadPrayerTimes(
                    for: appState.selectedCity,
                    calculation: appState.prayerCalculation,
                    provider: appState.prayerTimeProvider
                )
            }
            .onChange(of: appState.selectedCity) { _, newCity in
                prayerTimeManager.loadPrayerTimes(
                    for: newCity,
                    calculation: appState.prayerCalculation,
                    provider: appState.prayerTimeProvider
                )
            }
            .onChange(of: appState.prayerCalculation) { _, newCalc in
                prayerTimeManager.loadPrayerTimes(
                    for: appState.selectedCity,
                    calculation: newCalc,
                    provider: appState.prayerTimeProvider
                )
            }
            .onChange(of: appState.prayerTimeProvider) { _, _ in
                prayerTimeManager.loadPrayerTimes(
                    for: appState.selectedCity,
                    calculation: appState.prayerCalculation,
                    provider: appState.prayerTimeProvider
                )
            }
        }
=======
            MainTabView()
                .environmentObject(prayerTimeManager)
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            SRSItem.self,
            DailyActivity.self,
            HifzProgress.self
        ])
>>>>>>> origin/claude/adoring-banach
    }
}
