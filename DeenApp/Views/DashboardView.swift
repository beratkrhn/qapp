//
//  DashboardView.swift
//  DeenApp
//
//  Main Dashboard: Header, Nächstes Gebet, Heutige Gebetszeiten, Kur'an/Vokabeln-Karten.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var prayerTimeManager: PrayerTimeManager
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                HeaderView(userName: appState.userName, timezone: prayerTimeManager.timezoneIdentifier)

                if prayerTimeManager.isLoading {
                    loadingCard
                } else if let next = prayerTimeManager.nextPrayer {
                    NextPrayerCard(
                        prayer: next,
                        countdown: prayerTimeManager.countdownString
                    )
                }

                if !prayerTimeManager.prayerTimes.isEmpty {
                    PrayerTimesCardView(
                        prayers: prayerTimeManager.prayerTimes,
                        nextPrayer: prayerTimeManager.nextPrayer
                    )
                }

                BottomInfoCardsView()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .background(Theme.background)
    }

    private var loadingCard: some View {
        CardContainer {
            HStack {
                ProgressView()
                    .tint(Theme.accent)
                Text("Gebetszeiten werden geladen…")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(PrayerTimeManager())
        .environmentObject(AppState())
}
