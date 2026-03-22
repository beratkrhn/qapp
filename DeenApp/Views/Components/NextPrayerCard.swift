//
//  NextPrayerCard.swift
//  DeenApp
//

import SwiftUI

struct NextPrayerCard: View {
    let prayer: PrayerTime
    let countdown: String
    var language: AppLanguage = .german

    var body: some View {
        CardContainer(useHighlightBackground: true) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.nextPrayer(language))
                    .font(.caption.weight(.medium))
                    .tracking(0.8)
                    .foregroundColor(Theme.textSection)

                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        Image(systemName: prayer.kind.iconName)
                            .font(.body)
                            .foregroundColor(prayer.kind.iconColor)
                        Text(L10n.prayerName(prayer.kind, language))
                            .font(.title3.weight(.semibold))
                            .foregroundColor(Theme.textPrimary)
                    }
                    Spacer()
                    Text("\(prayer.timeString) \(L10n.oClock(language))")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }

                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.subheadline)
                        .foregroundColor(Theme.accent)
                    Text(countdown)
                        .font(.title2.monospacedDigit().weight(.bold))
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }
}

#Preview {
    NextPrayerCard(
        prayer: PrayerTime(kind: .fajr, timeString: "05:22", referenceDate: Date()),
        countdown: "05:05:37"
    )
    .padding()
    .background(Theme.background)
}
