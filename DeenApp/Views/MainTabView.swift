//
//  MainTabView.swift
//  DeenApp
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State private var srsViewModel = SRSViewModel()
    @State private var prayerTutorialViewModel = PrayerTutorialViewModel()
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background
                .ignoresSafeArea()

            Group {
                switch appState.selectedTab {
                case .start:
                    DashboardView(showSettings: $showSettings)
                case .quran:
                    QuranView()
                case .lernen:
                    LearnTabView()
                        .environment(srsViewModel)
                case .gebet:
                    PrayerSelectionView()
                        .environment(prayerTutorialViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBarView()
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(PrayerTimeManager())
        .environmentObject(AppState())
}
