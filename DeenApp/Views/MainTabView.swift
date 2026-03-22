//
//  MainTabView.swift
//  DeenApp
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background
                .ignoresSafeArea()

            Group {
                switch appState.selectedTab {
                case .start:
                    DashboardView()
                case .quran:
                    PlaceholderView(title: "Quran", subtitle: "Weiterlesen")
                case .lernen:
                    PlaceholderView(title: "Lernen", subtitle: "Vokabeln & Karteikarten")
                case .gebet:
                    PlaceholderView(title: "Gebet", subtitle: "Gebetszeiten & Qibla")
                case .hifz:
                    HifzMainView(modelContext: modelContext)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBarView()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct PlaceholderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title.weight(.semibold))
                .foregroundColor(Theme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MainTabView()
        .environmentObject(PrayerTimeManager())
        .environmentObject(AppState())
}
