//
//  NextPrayerCard.swift
//  DeenApp
//

import SwiftUI

struct NextPrayerCard: View {
    let prayer: PrayerTime
    let countdown: String
<<<<<<< HEAD
    var language: AppLanguage = .german
=======
>>>>>>> origin/claude/adoring-banach

    var body: some View {
        CardContainer(useHighlightBackground: true) {
            VStack(alignment: .leading, spacing: 12) {
<<<<<<< HEAD
                Text(L10n.nextPrayer(language))
=======
                Text("NÄCHSTES GEBET")
>>>>>>> origin/claude/adoring-banach
                    .font(.caption.weight(.medium))
                    .tracking(0.8)
                    .foregroundColor(Theme.textSection)

                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        Image(systemName: prayer.kind.iconName)
                            .font(.body)
                            .foregroundColor(prayer.kind.iconColor)
<<<<<<< HEAD
                        Text(L10n.prayerName(prayer.kind, language))
=======
                        Text(prayer.kind.displayName)
>>>>>>> origin/claude/adoring-banach
                            .font(.title3.weight(.semibold))
                            .foregroundColor(Theme.textPrimary)
                    }
                    Spacer()
<<<<<<< HEAD
                    Text("\(prayer.timeString) \(L10n.oClock(language))")
=======
                    Text("\(prayer.timeString) Uhr")
>>>>>>> origin/claude/adoring-banach
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
