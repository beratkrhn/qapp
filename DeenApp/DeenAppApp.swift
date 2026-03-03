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
                    prayerTimeManager.loadPrayerTimes(for: appState.selectedCity, method: appState.calculationMethod)
                }
                .onChange(of: appState.selectedCity) { _, newCity in
                    prayerTimeManager.loadPrayerTimes(for: newCity, method: appState.calculationMethod)
                }
                .onChange(of: appState.calculationMethod) { _, newMethod in
                    prayerTimeManager.loadPrayerTimes(for: appState.selectedCity, method: newMethod)
                }
        }
    }
}
