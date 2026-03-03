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
    @Binding var showSettings: Bool

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                // Settings gear row
                HStack {
                    Spacer()
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(Theme.textSecondary)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(Theme.cardBackground)
                            )
                    }
                }
                .padding(.trailing, 4)

                HeaderView(userName: appState.userName, cityName: appState.selectedCity.displayName)

                if prayerTimeManager.isLoading {
                    loadingCard
                } else if let next = prayerTimeManager.nextPrayer {
                    NextPrayerCard(
                        prayer: next,
                        countdown: prayerTimeManager.countdownString,
                        language: appState.appLanguage
                    )
                }

                if !prayerTimeManager.prayerTimes.isEmpty {
                    PrayerTimesCardView(
                        prayers: prayerTimeManager.prayerTimes,
                        nextPrayer: prayerTimeManager.nextPrayer,
                        language: appState.appLanguage
                    )
                }

                DailyReadingGoalCard(appState: appState, language: appState.appLanguage)

                BottomInfoCardsView(language: appState.appLanguage)
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
                Text(L10n.loadingPrayerTimes(appState.appLanguage))
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
}

#Preview {
    DashboardView(showSettings: .constant(false))
        .environmentObject(PrayerTimeManager())
        .environmentObject(AppState())
}
