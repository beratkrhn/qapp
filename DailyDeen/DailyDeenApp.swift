//
//  DailyDeeApp.swift
//  DailyDeen
//
//  Created by Berat Karahan on 27.02.26.
//

import SwiftUI

@main
struct DailyDeenApp: App {
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
            .preferredColorScheme(.dark)
        }
    }
}
