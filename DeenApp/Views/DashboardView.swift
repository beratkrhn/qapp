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
<<<<<<< HEAD
    @Binding var showSettings: Bool
=======
>>>>>>> origin/claude/adoring-banach

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
<<<<<<< HEAD
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
=======
                HeaderView(userName: appState.userName, timezone: prayerTimeManager.timezoneIdentifier)
>>>>>>> origin/claude/adoring-banach

                if prayerTimeManager.isLoading {
                    loadingCard
                } else if let next = prayerTimeManager.nextPrayer {
                    NextPrayerCard(
                        prayer: next,
<<<<<<< HEAD
                        countdown: prayerTimeManager.countdownString,
                        language: appState.appLanguage
=======
                        countdown: prayerTimeManager.countdownString
>>>>>>> origin/claude/adoring-banach
                    )
                }

                if !prayerTimeManager.prayerTimes.isEmpty {
                    PrayerTimesCardView(
                        prayers: prayerTimeManager.prayerTimes,
<<<<<<< HEAD
                        nextPrayer: prayerTimeManager.nextPrayer,
                        kerahatTimes: prayerTimeManager.kerahatStartTimes,
                        language: appState.appLanguage
                    )
                }

                DailyReadingGoalCard(appState: appState, language: appState.appLanguage)

                BottomInfoCardsView(language: appState.appLanguage)
=======
                        nextPrayer: prayerTimeManager.nextPrayer
                    )
                }

                BottomInfoCardsView()
>>>>>>> origin/claude/adoring-banach
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
<<<<<<< HEAD
                Text(L10n.loadingPrayerTimes(appState.appLanguage))
=======
                Text("Gebetszeiten werden geladen…")
>>>>>>> origin/claude/adoring-banach
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
}

#Preview {
<<<<<<< HEAD
    DashboardView(showSettings: .constant(false))
=======
    DashboardView()
>>>>>>> origin/claude/adoring-banach
        .environmentObject(PrayerTimeManager())
        .environmentObject(AppState())
}
