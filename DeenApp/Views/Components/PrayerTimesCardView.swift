//
//  PrayerTimesCardView.swift
//  DeenApp
//

import SwiftUI

struct PrayerTimesCardView: View {
    let prayers: [PrayerTime]
    let nextPrayer: PrayerTime?

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                Text("HEUTIGE GEBETSZEITEN")
                    .font(.caption.weight(.medium))
                    .tracking(0.8)
                    .foregroundColor(Theme.textSection)
                    .padding(.bottom, 14)

                VStack(spacing: 0) {
                    ForEach(Array(prayers.enumerated()), id: \.element.id) { index, prayer in
                        PrayerRowView(
                            prayer: prayer,
                            isNext: nextPrayer?.id == prayer.id
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: prayer.kind.iconName)
                .font(.body)
                .foregroundColor(prayer.kind.iconColor)
                .frame(width: 24, alignment: .center)

            Text(prayer.kind.displayName)
                .font(.subheadline.weight(isNext ? .semibold : .regular))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Text(prayer.timeString)
                .font(.subheadline.monospacedDigit())
                .foregroundColor(Theme.textPrimary)
        }
        .padding(.vertical, 10)
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
}
