//
//  TimerWidgetView.swift
//  DailyDeen Widget — Widget B
//
//  Minimal timer showing only the next prayer name + live countdown.
//  Supports .systemSmall, .accessoryInline, .accessoryRectangular, .accessoryCircular.
//

import SwiftUI
import WidgetKit

struct TimerWidgetView: View {
    let entry: PrayerTimesEntry
    @Environment(\.widgetFamily) var family

    // MARK: - Palette

    private let accent        = Color(red: 0.21, green: 0.82, blue: 0.50)
    private let textPrimary   = Color.white
    private let textSecondary = Color.white.opacity(0.55)

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:      inlineView
            case .accessoryRectangular: rectangularView
            case .accessoryCircular:    circularView
            default:                    smallView
            }
        }
        .containerBackground(for: .widget) { liquidGlass }
    }

    // =========================================================================
    // MARK: - Liquid Glass Background (stripped for Lock Screen by system)
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
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
        .environment(\.colorScheme, .dark)
    }

    // =========================================================================
    // MARK: - Home Screen: Small (minimalist — prayer + timer + city)
    // =========================================================================

    private var smallView: some View {
        VStack(spacing: 4) {
            if let next = entry.nextSlot {
                HStack(spacing: 4) {
                    Image(systemName: next.icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(accent)
                    Text(next.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                }
            }

            if let target = entry.nextPrayerDate {
                let now = Date()
                if target > now {
                    Text(timerInterval: now...target, countsDown: true)
                        .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(textPrimary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                } else {
                    Text("--:--")
                        .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(textSecondary)
                }
            }

            if let next = entry.nextSlot {
                Text(next.time)
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            HStack(spacing: 3) {
                Image(systemName: "location.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(textSecondary.opacity(0.7))
                Text(entry.cityName)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.bottom, 2)
        }
        .padding(12)
    }

    // =========================================================================
    // MARK: - Lock Screen: Inline
    // =========================================================================

    @ViewBuilder
    private var inlineView: some View {
        if let next = entry.nextSlot, let target = entry.nextPrayerDate {
            let now = Date()
            if target > now {
                Text("\(Image(systemName: next.icon)) \(next.label) ") + Text(timerInterval: now...target, countsDown: true)
            } else {
                Label("DailyDeen", systemImage: "moon.stars.fill")
            }
        } else {
            Label("DailyDeen", systemImage: "moon.stars.fill")
        }
    }

    // =========================================================================
    // MARK: - Lock Screen: Rectangular
    // =========================================================================

    @ViewBuilder
    private var rectangularView: some View {
        if let next = entry.nextSlot, let target = entry.nextPrayerDate {
            let now = Date()
            if target > now {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: next.icon)
                            .font(.caption2)
                        Text(next.label)
                            .font(.headline)
                    }
                    .widgetAccentable()

                    Text(timerInterval: now...target, countsDown: true)
                        .font(.title3.weight(.bold).monospacedDigit())
                        .widgetAccentable()

                    Text("at \(next.time)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                fallbackRectangular
            }
        } else {
            fallbackRectangular
        }
    }

    private var fallbackRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text("DailyDeen")
                    .font(.headline)
                    .widgetAccentable()
                Spacer()
                Text(entry.cityName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            ForEach(entry.upcomingSlots) { slot in
                HStack(spacing: 4) {
                    Text(slot.label)
                    Spacer()
                    Text(slot.time).monospacedDigit()
                }
                .font(.caption2)
                .opacity(slot.isNext ? 1 : 0.6)
            }
        }
    }

    // =========================================================================
    // MARK: - Lock Screen: Circular
    // =========================================================================

    @ViewBuilder
    private var circularView: some View {
        if let next = entry.nextSlot, let target = entry.nextPrayerDate {
            let now = Date()
            if target > now {
                VStack(spacing: 1) {
                    Image(systemName: next.icon)
                        .font(.system(size: 11))
                        .widgetAccentable()
                    Text(timerInterval: now...target, countsDown: true)
                        .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                        .widgetAccentable()
                    Text(next.label)
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "moon.stars.fill")
                        .font(.title3)
                        .widgetAccentable()
                    Text("DailyDeen")
                        .font(.system(size: 7))
                }
            }
        } else {
            Image(systemName: "moon.stars.fill")
                .font(.title3)
                .widgetAccentable()
        }
    }
}
