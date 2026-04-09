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
        }
    }
}
