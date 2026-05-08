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
    @StateObject private var locationAutoUpdater = LocationAutoUpdater()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(prayerTimeManager)
            .environmentObject(appState)
            .environmentObject(locationAutoUpdater)
            .preferredColorScheme(appState.preferredSwiftUIColorScheme)
            .task {
                locationAutoUpdater.bind(appState: appState,
                                         prayerTimeManager: prayerTimeManager)
                if appState.autoLocationEnabled {
                    locationAutoUpdater.start()
                }
            }
        }
    }
}
