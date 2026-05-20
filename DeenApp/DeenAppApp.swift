//
//  DeenAppApp.swift
//  DeenApp
//
//  Islamische Gebetszeiten & Spiritualität
//

import SwiftUI
import FirebaseCore

@main
struct DeenAppApp: App {
    @StateObject private var prayerTimeManager = PrayerTimeManager()
    @StateObject private var appState = AppState()
    @StateObject private var locationAutoUpdater = LocationAutoUpdater()
    @StateObject private var accountVM: AccountViewModel

    init() {
        FirebaseApp.configure()
        _accountVM = StateObject(wrappedValue: AccountViewModel())
    }

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
            .environmentObject(accountVM)
            .preferredColorScheme(.dark)
            .task {
                locationAutoUpdater.bind(appState: appState,
                                         prayerTimeManager: prayerTimeManager)
                if appState.autoLocationEnabled {
                    locationAutoUpdater.start()
                }
                PhoneWatchSession.shared.activate()
            }
        }
    }
}
