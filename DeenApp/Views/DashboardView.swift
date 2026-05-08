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
    @State private var showQadaTracker = false
    @State private var showQiblaCompass = false

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

                HeaderView(userName: appState.userName, cityName: appState.currentCityName)
                
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
                        nextPrayer: prayerTimeManager.nextPrayer,
                        date: prayerTimeManager.currentDate
                    )
                }

                QiblaCompassCard(onTap: { showQiblaCompass = true })

                QadaTrackerCard(onTap: { showQadaTracker = true })

                DailyReadingGoalCard(appState: appState, language: appState.appLanguage)

                BottomInfoCardsView(language: appState.appLanguage)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .background(Theme.background)
        .sheet(isPresented: $showQadaTracker) {
            QadaTrackerView()
        }
        .sheet(isPresented: $showQiblaCompass) {
            QiblaCompassView()
                .environmentObject(appState)
        }
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

struct QiblaCompassCard: View {
    @EnvironmentObject var appState: AppState
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            CardContainer {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "location.north.line.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("QIBLA-KOMPASS")
                            .font(.caption.weight(.medium))
                            .tracking(0.8)
                            .foregroundStyle(Theme.textSection)
                        Text(appState.homeCity == nil
                             ? "Richtung zur Kaaba & Seferi-Distanz"
                             : "Richtung zur Kaaba — Heimat: \(appState.homeCity!.name)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView(showSettings: .constant(false))
        .environmentObject(PrayerTimeManager())
        .environmentObject(AppState())
}
