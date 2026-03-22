//
//  DeenAppApp.swift
//  DeenApp
//
//  Islamische Gebetszeiten & Spiritualität
//

import SwiftUI
import SwiftData

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
        }
        .modelContainer(for: [
            SRSItem.self,
            DailyActivity.self,
            HifzProgress.self
        ])
    }
}
