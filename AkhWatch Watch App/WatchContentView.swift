//
//  WatchContentView.swift
//  AkhWatch
//
//  Minimal host UI. The watch face complication is the primary surface
//  for this MVP; this view exists so users can launch the app once to
//  trigger the initial WCSession sync.
//

import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject private var store: WatchPrayerStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if let payload = store.payload {
                    header(payload: payload)
                    Divider()
                    ForEach(payload.prayers) { prayer in
                        PrayerRow(prayer: prayer,
                                  isNext: prayer.kindRaw == nextPrayer(payload: payload)?.kindRaw,
                                  accent: WatchAccent.color(for: payload.accentThemeRaw))
                    }
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private func header(payload: WatchPrayerPayload) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "location.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(WatchAccent.color(for: payload.accentThemeRaw))
            Text(payload.cityName)
                .font(.headline)
                .lineLimit(1)
        }
        if let next = nextPrayer(payload: payload) {
            HStack(spacing: 4) {
                Text(next.name)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(next.time, style: .timer)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(WatchAccent.color(for: payload.accentThemeRaw))
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Keine Daten")
                .font(.headline)
            Text("Öffne Akh-ira auf dem iPhone, damit die Uhr die Gebetszeiten erhält.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private func nextPrayer(payload: WatchPrayerPayload) -> WatchPrayer? {
        let now = Date()
        return payload.prayers.first { $0.time > now } ?? payload.prayers.first
    }
}

private struct PrayerRow: View {
    let prayer: WatchPrayer
    let isNext: Bool
    let accent: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: prayer.iconName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isNext ? accent : .secondary)
                .frame(width: 18)
            Text(prayer.name)
                .font(.caption.weight(isNext ? .bold : .regular))
            Spacer()
            Text(prayer.timeString)
                .font(.caption.monospacedDigit())
                .foregroundStyle(isNext ? accent : .secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    WatchContentView()
        .environmentObject(WatchPrayerStore.shared)
}
