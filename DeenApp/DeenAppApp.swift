//
//  DeenAppApp.swift
//  DeenApp
//
//  Islamische Gebetszeiten & Spiritualität
//

import SwiftUI

@main
struct DeenAppApp: App {
    @StateObject private var prayerTimeManager = PrayerTimeManager()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(prayerTimeManager)
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .task {
                    prayerTimeManager.loadPrayerTimes(
                        for: appState.selectedCity,
                        method: appState.calculationMethod,
                        provider: appState.prayerTimeProvider
                    )
                }
                .onChange(of: appState.selectedCity) { _, newCity in
                    prayerTimeManager.loadPrayerTimes(
                        for: newCity,
                        method: appState.calculationMethod,
                        provider: appState.prayerTimeProvider
                    )
                }
                .onChange(of: appState.calculationMethod) { _, newMethod in
                    prayerTimeManager.loadPrayerTimes(
                        for: appState.selectedCity,
                        method: newMethod,
                        provider: appState.prayerTimeProvider
                    )
                }
                .onChange(of: appState.prayerTimeProvider) { _, _ in
                    prayerTimeManager.loadPrayerTimes(
                        for: appState.selectedCity,
                        method: appState.calculationMethod,
                        provider: appState.prayerTimeProvider
                    )
                }
        }
    }
}
