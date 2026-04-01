//
//  NextPrayerCard.swift
//  DeenApp
//

import SwiftUI

struct NextPrayerCard: View {
    let prayer: PrayerTime
    let countdown: String

    var body: some View {
        CardContainer(useHighlightBackground: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text("NÄCHSTES GEBET")
                    .font(.caption.weight(.medium))
                    .tracking(0.8)
                    .foregroundColor(Theme.textSection)

                // Prayer name (left) aligned on same row as countdown timer (right)
                HStack(alignment: .center) {
                    // Left: icon + prayer name + time string
                    HStack(spacing: 12) {
                        Image(systemName: prayer.kind.iconName)
                            .font(.title3)
                            .foregroundColor(.gray)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(prayer.kind.displayName)
                                .font(.title3.weight(.semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("\(prayer.timeString) Uhr")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }

                    Spacer()

                    // Right: countdown timer — vertically aligned with prayer name
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.subheadline)
                            .foregroundColor(Theme.accent)
                        Text(countdown)
                            .font(.title2.monospacedDigit().weight(.bold))
                            .foregroundColor(Theme.accent)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

#Preview {
    NextPrayerCard(
        prayer: PrayerTime(kind: .imsak, timeString: "05:22", referenceDate: Date()),
        countdown: "05:05:37"
    )
    .padding()
    .background(Theme.background)
}
