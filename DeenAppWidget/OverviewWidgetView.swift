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
        VStack(spacing: 6) {
            mediumHeader
            HStack(spacing: 8) {
                VStack(spacing: 6) {
                    ForEach(Array(entry.slots.prefix(3))) { slot in
                        glassCell(slot)
                    }
                }
                VStack(spacing: 6) {
                    ForEach(Array(entry.slots.suffix(3))) { slot in
                        glassCell(slot)
                    }
                }
            }
        }
        .padding(14)
    }

    private var mediumHeader: some View {
        HStack {
            HStack(spacing: 5) {
                Image(systemName: "moon.stars.fill")
                    .font(.caption2)
                    .foregroundStyle(accent)
                Text("DailyDeen")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(textPrimary)
            }

            Spacer()

            if let next = entry.nextSlot, let target = entry.nextPrayerDate {
                let now = Date()
                if target > now {
                    HStack(spacing: 4) {
                        Text(next.label)
                            .font(.caption2.weight(.medium))
                        Text(timerInterval: now...target, countsDown: true)
                            .font(.caption.weight(.bold).monospacedDigit())
                    }
                    .foregroundStyle(accent)
                }
            }
        }
    }

    // MARK: - Glass Cell (shared by medium grid)

    private func glassCell(_ slot: PrayerSlot) -> some View {
        HStack(spacing: 6) {
            Image(systemName: slot.icon)
                .font(.system(size: 10))
                .foregroundStyle(slot.isNext ? accent : textSecondary)
                .frame(width: 14)

            Text(slot.label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(slot.isNext ? accent : textSecondary)
                .lineLimit(1)

            Spacer()

            Text(slot.time)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(slot.isNext ? accent : textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
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
    // MARK: - Large: Countdown Card + Full Glass List
    // =========================================================================

    private var largeView: some View {
        VStack(spacing: 0) {
            largeHeader
                .padding(.bottom, 10)

            countdownCard
                .padding(.bottom, 10)

            glassDivider
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                ForEach(entry.slots) { slot in
                    glassLargeRow(slot)
                    if slot.id < entry.slots.count - 1 {
                        glassDivider.padding(.leading, 44)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var largeHeader: some View {
        HStack {
            HStack(spacing: 5) {
                Image(systemName: "moon.stars.fill")
                    .font(.caption2)
                    .foregroundStyle(accent)
                Text("DailyDeen")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(textPrimary)
            }
            Spacer()
            Text(entry.dayLabel)
                .font(.caption2.weight(.medium))
                .foregroundStyle(textSecondary)
        }
    }

    @ViewBuilder
    private var countdownCard: some View {
        if let next = entry.nextSlot, let target = entry.nextPrayerDate {
            let now = Date()
            if target > now {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next Prayer")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(textSecondary)
                        Text(next.label)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(accent)
                    }
                    Spacer()
                    Text(timerInterval: now...target, countsDown: true)
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(accent)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(accent.opacity(0.25), lineWidth: 0.5)
                        )
                )
            }
        }
    }

    // MARK: - Large Row

    private func glassLargeRow(_ slot: PrayerSlot) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(slot.isNext ? accent.opacity(0.15) : Color.white.opacity(0.06))
                    .overlay(
                        Circle().stroke(
                            slot.isNext ? accent.opacity(0.3) : Color.white.opacity(0.08),
                            lineWidth: 0.5
                        )
                    )
                Image(systemName: slot.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(slot.isNext ? accent : textSecondary)
            }
            .frame(width: 32, height: 32)

            Text(slot.label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(slot.isNext ? accent : textPrimary)

            Spacer()

            Text(slot.time)
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundStyle(slot.isNext ? accent : textPrimary)

            if slot.isNext {
                Circle().fill(accent).frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background {
            if slot.isNext {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accent.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
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
