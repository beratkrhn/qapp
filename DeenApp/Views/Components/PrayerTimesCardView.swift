//
//  PrayerTimesCardView.swift
//  DeenApp
//

import SwiftUI

struct PrayerTimesCardView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var prayerTimeManager: PrayerTimeManager

    let prayers: [PrayerTime]
    let nextPrayer: PrayerTime?
    var date: Date = Date()

    @State private var showForecast = false

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                // Today's system date — tappable to reveal 10-day forecast
                Button(action: { showForecast = true }) {
                    HStack(spacing: 6) {
                        Text(date, format: .dateTime.weekday(.wide).day().month(.wide).year())
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.accent)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Theme.accent.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 6)
                .sheet(isPresented: $showForecast) {
                    TenDayForecastView()
                        .environmentObject(appState)
                        .environmentObject(prayerTimeManager)
                }

                Text("HEUTIGE GEBETSZEITEN")
                    .font(.caption.weight(.medium))
                    .tracking(0.8)
                    .foregroundColor(Theme.textSection)
                    .padding(.bottom, 14)

                VStack(spacing: 0) {
                    ForEach(Array(prayers.enumerated()), id: \.element.id) { index, prayer in
                        PrayerRowView(
                            prayer: prayer,
                            isNext: nextPrayer?.id == prayer.id,
                            appLanguage: appState.appLanguage
                        )
                        if index < prayers.count - 1 {
                            Divider()
                                .background(Theme.textSecondary.opacity(0.3))
                                .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
    }
}

struct PrayerRowView: View {
    let prayer: PrayerTime
    let isNext: Bool
    let appLanguage: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: prayer.kind.iconName)
                .font(.title3)
                .foregroundColor(prayer.kind.iconColor)
                .frame(width: 28, alignment: .center)

            Text(prayer.kind.localizedName(for: appLanguage))
                .font(.body.weight(isNext ? .semibold : .regular))
                .foregroundColor(Theme.textPrimary)
                .minimumScaleFactor(0.85)
                .lineLimit(1)

            Spacer()

            Text(prayer.timeString)
                .font(.body.weight(.medium).monospacedDigit())
                .foregroundColor(Theme.textPrimary)
                .minimumScaleFactor(0.85)
                .lineLimit(1)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isNext ? Theme.accent.opacity(0.2) : Color.clear)
        )
    }
}

#Preview {
    PrayerTimesCardView(
        prayers: PrayerKind.allCases.map { PrayerTime(kind: $0, timeString: "00:00", referenceDate: Date()) },
        nextPrayer: PrayerTime(kind: .imsak, timeString: "05:22", referenceDate: Date())
    )
    .padding()
    .background(Theme.background)
    .environmentObject(AppState())
    .environmentObject(PrayerTimeManager())
}
