//
//  TenDayForecastView.swift
//  DeenApp
//
//  Zeigt die Gebetszeiten der nächsten 10 Tage in einer schön formatierten Liste.
//

import SwiftUI

// MARK: - ForecastDay Model

struct ForecastDay: Identifiable {
    var id: String { dateString }
    let date: Date
    let dateString: String
    let prayers: [PrayerTime]
}

// MARK: - View

struct TenDayForecastView: View {
    @EnvironmentObject private var prayerTimeManager: PrayerTimeManager
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                Group {
                    if prayerTimeManager.isForecastLoading {
                        loadingView
                    } else if prayerTimeManager.tenDayForecast.isEmpty {
                        emptyView
                    } else {
                        forecastList
                    }
                }
            }
            .navigationTitle("10-Tage Vorschau")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .onAppear {
                prayerTimeManager.loadTenDayForecast()
            }
        }
    }

    // MARK: - Subviews

    private var forecastList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(prayerTimeManager.tenDayForecast) { day in
                    ForecastDayCard(day: day, appLanguage: appState.appLanguage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .padding(.bottom, 40)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Theme.accent)
                .scaleEffect(1.4)
            Text("Gebetszeiten werden geladen…")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundColor(Theme.accent.opacity(0.6))
            Text("Keine Daten verfügbar")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text("Bitte öffne zuerst den Gebetszeiten-Tab, damit die Daten geladen werden.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Day Card

private struct ForecastDayCard: View {
    let day: ForecastDay
    let appLanguage: AppLanguage

    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: appLanguage == .german ? "de_DE" : "ar_SA")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: day.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date header
            HStack(spacing: 8) {
                if isToday {
                    Text("Heute")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(Theme.accent)
                        )
                }
                Text(dateLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isToday ? Theme.accent : Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .background(Theme.accent.opacity(0.18))
                .padding(.horizontal, 12)

            // Prayer rows
            VStack(spacing: 0) {
                ForEach(Array(day.prayers.enumerated()), id: \.element.id) { index, prayer in
                    ForecastPrayerRow(prayer: prayer, appLanguage: appLanguage)
                    if index < day.prayers.count - 1 {
                        Divider()
                            .background(Theme.textSecondary.opacity(0.12))
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.shadowColor,
                        radius: isToday ? 10 : 6,
                        x: 0,
                        y: isToday ? 5 : 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                .strokeBorder(isToday ? Theme.accent.opacity(0.35) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Prayer Row

private struct ForecastPrayerRow: View {
    let prayer: PrayerTime
    let appLanguage: AppLanguage

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: prayer.kind.iconName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(prayer.kind.iconColor)
                .frame(width: 22, alignment: .center)

            Text(prayer.kind.localizedName(for: appLanguage))
                .font(.body)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Text(prayer.timeString)
                .font(.body.weight(.medium).monospacedDigit())
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }
}

#Preview {
    TenDayForecastView()
        .environmentObject(PrayerTimeManager())
        .environmentObject(AppState())
}
