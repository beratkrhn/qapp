//
//  OverviewWidgetView.swift
//  DailyDeen Widget — Widget A
//
//  Full prayer-time overview with live countdown.
//  Supports .systemMedium and .systemLarge.
//  Liquid Glass aesthetic with green-highlighted next prayer.
//

import SwiftUI
import WidgetKit

struct OverviewWidgetView: View {
    let entry: PrayerTimesEntry
    @Environment(\.widgetFamily) var family

    // MARK: - Palette

    private let accent        = Color(red: 0.21, green: 0.82, blue: 0.50)
    private let textPrimary   = Color.white
    private let textSecondary = Color.white.opacity(0.55)

    var body: some View {
        Group {
            switch family {
            case .systemLarge: largeView
            default:           mediumView
            }
        }
        .containerBackground(for: .widget) { liquidGlass }
    }

    // =========================================================================
    // MARK: - Liquid Glass Background
    // =========================================================================

    private var liquidGlass: some View {
        ZStack {
            Color(red: 0.05, green: 0.07, blue: 0.10)
            Rectangle().fill(.ultraThinMaterial)
            LinearGradient(
                stops: [
                    .init(color: Color.white.opacity(0.14), location: 0),
                    .init(color: Color.white.opacity(0.04), location: 0.35),
                    .init(color: Color.clear, location: 0.65),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.white.opacity(0.08), Color.clear],
                    startPoint: .top, endPoint: .bottom
                ).frame(height: 50)
                Spacer()
            }
        }
        .environment(\.colorScheme, .dark)
    }

    // =========================================================================
    // MARK: - Medium: Header + 2×3 Glass Grid
    // =========================================================================

    private var mediumView: some View {
        VStack(spacing: 4) {
            mediumHeader
            HStack(spacing: 6) {
                VStack(spacing: 4) {
                    ForEach(Array(entry.slots.prefix(3))) { slot in
                        glassCell(slot)
                    }
                }
                VStack(spacing: 4) {
                    ForEach(Array(entry.slots.suffix(3))) { slot in
                        glassCell(slot)
                    }
                }
            }
        }
        .padding(12)
    }

    private var mediumHeader: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(accent)
                Text("DailyDeen")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(textPrimary)
                    .lineLimit(1)
                Text("· \(entry.cityName)")
                    .font(.system(size: 10))
                    .foregroundStyle(textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer()

            if let next = entry.nextSlot, let target = entry.nextPrayerDate {
                let now = Date()
                if target > now {
                    HStack(spacing: 3) {
                        Text(next.label)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                        Text(timerInterval: now...target, countsDown: true)
                            .font(.system(size: 11, weight: .bold).monospacedDigit())
                            .lineLimit(1)
                    }
                    .foregroundStyle(accent)
                    .minimumScaleFactor(0.6)
                }
            }
        }
    }

    // MARK: - Glass Cell (shared by medium grid)

    private func glassCell(_ slot: PrayerSlot) -> some View {
        HStack(spacing: 5) {
            Image(systemName: slot.icon)
                .font(.system(size: 9))
                .foregroundStyle(slot.isNext ? accent : textSecondary)
                .frame(width: 12)

            Text(slot.label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(slot.isNext ? accent : textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer()

            Text(slot.time)
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(slot.isNext ? accent : textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(slot.isNext ? accent.opacity(0.14) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    slot.isNext ? accent.opacity(0.45) : Color.white.opacity(0.18),
                                    slot.isNext ? accent.opacity(0.1)  : Color.white.opacity(0.04),
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
    }

    // =========================================================================
    // MARK: - Large: Compact Countdown Card + Full Prayer List
    // =========================================================================

    private var largeView: some View {
        VStack(spacing: 0) {
            largeHeader
                .padding(.bottom, 6)

            countdownCard
                .padding(.bottom, 6)

            glassDivider
                .padding(.bottom, 4)

            // All 6 prayer rows
            VStack(spacing: 2) {
                ForEach(entry.slots) { slot in
                    glassLargeRow(slot)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private var largeHeader: some View {
        HStack(spacing: 5) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 10))
                .foregroundStyle(accent)
            Text("DailyDeen")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(textPrimary)
            Text("·")
                .font(.system(size: 10))
                .foregroundStyle(textSecondary)
            Image(systemName: "location.fill")
                .font(.system(size: 7))
                .foregroundStyle(textSecondary)
            Text(entry.cityName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer()
            Text(entry.dayLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(textSecondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var countdownCard: some View {
        if let next = entry.nextSlot, let target = entry.nextPrayerDate {
            let now = Date()
            if target > now {
                HStack(spacing: 8) {
                    Image(systemName: next.icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(accent)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Nächstes Gebet")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(textSecondary)
                        Text(next.label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(accent)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(timerInterval: now...target, countsDown: true)
                            .font(.system(size: 15, weight: .bold).monospacedDigit())
                            .foregroundStyle(accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("um \(next.time)")
                            .font(.system(size: 8))
                            .foregroundStyle(textSecondary)
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(accent.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(accent.opacity(0.25), lineWidth: 0.5)
                        )
                )
            }
        }
    }

    // MARK: - Large Row (compact — no inter-row dividers)

    private func glassLargeRow(_ slot: PrayerSlot) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(slot.isNext ? accent.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        Circle().stroke(
                            slot.isNext ? accent.opacity(0.3) : Color.white.opacity(0.07),
                            lineWidth: 0.5
                        )
                    )
                Image(systemName: slot.icon)
                    .font(.system(size: 10))
                    .foregroundStyle(slot.isNext ? accent : textSecondary)
            }
            .frame(width: 24, height: 24)

            Text(slot.label)
                .font(.system(size: 12, weight: slot.isNext ? .semibold : .regular))
                .foregroundStyle(slot.isNext ? accent : textPrimary)
                .lineLimit(1)

            Spacer()

            Text(slot.time)
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(slot.isNext ? accent : textPrimary)
                .lineLimit(1)

            if slot.isNext {
                Circle().fill(accent).frame(width: 4, height: 4)
            } else {
                Circle().fill(Color.clear).frame(width: 4, height: 4)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 7)
        .background {
            if slot.isNext {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(accent.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(accent.opacity(0.18), lineWidth: 0.5)
                    )
            }
        }
    }

    // MARK: - Shared

    private var glassDivider: some View {
        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
    }
}
