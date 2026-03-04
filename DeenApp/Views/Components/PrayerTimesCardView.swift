//
//  PrayerTimesCardView.swift
//  DeenApp
//

import SwiftUI

struct PrayerTimesCardView: View {
    let prayers: [PrayerTime]
    let nextPrayer: PrayerTime?
    var kerahatTimes: [PrayerKind: String] = [:]
    var language: AppLanguage = .german

    /// Subscribing to AppState ensures this card re-renders whenever the accent
    /// theme changes, so Theme.cardBackground (a computed var) is re-evaluated.
    @EnvironmentObject var appState: AppState
    @State private var isExpanded: Bool = false

    // MARK: - Computed Kerahat (Makruh) times

    /// Kerahat 1: Shuruuq → Shuruuq + 45 min
    private var kerahatAfterSunriseString: String {
        guard let shuruuq = prayers.first(where: { $0.kind == .shuruuq }) else { return "—" }
        let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
        let end = Calendar.current.date(byAdding: .minute, value: 45, to: shuruuq.time)
        return "\(shuruuq.timeString) – \(end.map { fmt.string(from: $0) } ?? "—")"
    }

    /// Kerahat 2: Dhuhr − 45 min → Dhuhr
    private var kerahatBeforeDhuhrString: String {
        guard let dhuhr = prayers.first(where: { $0.kind == .dhuhr }) else { return "—" }
        let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
        let start = Calendar.current.date(byAdding: .minute, value: -45, to: dhuhr.time)
        return "\(start.map { fmt.string(from: $0) } ?? "—") – \(dhuhr.timeString)"
    }

    /// Kerahat 3: Maghrib − 45 min → Maghrib
    private var kerahatBeforeMaghribString: String {
        guard let maghrib = prayers.first(where: { $0.kind == .maghrib }) else { return "—" }
        let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
        let start = Calendar.current.date(byAdding: .minute, value: -45, to: maghrib.time)
        return "\(start.map { fmt.string(from: $0) } ?? "—") – \(maghrib.timeString)"
    }

    // MARK: - Kerahat period labels (language-aware)

    private func kerahatLabel1(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "After Sunrise (45 min)"
        case .turkish: return "Güneş Doğuşu Sonrası"
        default:       return "Nach Shuruuq (45 min)"
        }
    }

    private func kerahatLabel2(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Before Dhuhr (45 min)"
        case .turkish: return "Öğle Öncesi (45 dk)"
        default:       return "Vor Dhuhr (45 min)"
        }
    }

    private func kerahatLabel3(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Before Maghrib (45 min)"
        case .turkish: return "Akşam Öncesi (45 dk)"
        default:       return "Vor Maghrib (45 min)"
        }
    }

    /// Last Third of the Night: Isha → tomorrow Imsak/Fajr, last 1/3 of night.
    /// Uses Imsak as morning reference (Fajr no longer in the display array).
    private var lastThirdString: String {
        guard let isha = prayers.first(where: { $0.kind == .isha }) else { return "—" }
        // Imsak serves as the morning reference (≈ Fajr – 10 min, close enough)
        guard let morningRef = prayers.first(where: { $0.kind == .imsak }) else { return "—" }
        var morningDate = morningRef.time
        if morningDate <= isha.time {
            morningDate = Calendar.current.date(byAdding: .day, value: 1, to: morningDate) ?? morningDate
        }
        let nightDuration = morningDate.timeIntervalSince(isha.time)
        let lastThirdStart = isha.time.addingTimeInterval(nightDuration * (2.0 / 3.0))
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return "\(fmt.string(from: lastThirdStart)) – \(morningRef.timeString)"
    }

    // MARK: - Body

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {

                // Section header
                Text(L10n.todayPrayerTimes(language))
                    .font(.caption.weight(.medium))
                    .tracking(0.8)
                    .foregroundColor(Theme.textSection)
                    .padding(.bottom, 14)

                // Prayer rows
                VStack(spacing: 0) {
                    ForEach(Array(prayers.enumerated()), id: \.element.id) { index, prayer in
                        PrayerRowView(
                            prayer: prayer,
                            isNext: nextPrayer?.id == prayer.id,
                            language: language,
                            kerahatTimeString: kerahatTimes[prayer.kind]
                        )
                        if index < prayers.count - 1 {
                            Divider()
                                .background(Theme.textSecondary.opacity(0.15))
                                .padding(.vertical, 4)
                        }
                    }
                }

                // Expand / Collapse toggle
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundColor(Theme.accent.opacity(0.8))
                        Text(L10n.showDetails(language))
                            .font(.caption.weight(.medium))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Theme.textSecondary.opacity(0.7))
                    }
                    .padding(.top, 14)
                    .padding(.bottom, isExpanded ? 10 : 0)
                }
                .buttonStyle(.plain)

                // Expandable special-times section
                if isExpanded {
                    specialTimesSection
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - Special Times sub-section

    @ViewBuilder
    private var specialTimesSection: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Sub-header
            Text(L10n.specialTimes(language))
                .font(.caption.weight(.medium))
                .tracking(0.8)
                .foregroundColor(Theme.accent.opacity(0.85))
                .padding(.bottom, 10)

            // Kerahat header label
            Text(L10n.kerahatTimes(language))
                .font(.caption.weight(.semibold))
                .tracking(0.5)
                .foregroundColor(Color(hex: "FF7043").opacity(0.9))
                .padding(.bottom, 4)

            // Kerahat 1: After Sunrise
            SpecialTimeRow(
                iconName: "exclamationmark.circle.fill",
                iconColor: Color(hex: "FF7043"),
                label: kerahatLabel1(language),
                timeRange: kerahatAfterSunriseString
            )

            Divider()
                .background(Theme.textSecondary.opacity(0.10))
                .padding(.vertical, 3)

            // Kerahat 2: Before Dhuhr
            SpecialTimeRow(
                iconName: "exclamationmark.circle.fill",
                iconColor: Color(hex: "FF7043"),
                label: kerahatLabel2(language),
                timeRange: kerahatBeforeDhuhrString
            )

            Divider()
                .background(Theme.textSecondary.opacity(0.10))
                .padding(.vertical, 3)

            // Kerahat 3: Before Maghrib
            SpecialTimeRow(
                iconName: "exclamationmark.circle.fill",
                iconColor: Color(hex: "FF7043"),
                label: kerahatLabel3(language),
                timeRange: kerahatBeforeMaghribString
            )

            Divider()
                .background(Theme.textSecondary.opacity(0.12))
                .padding(.vertical, 6)

            // Last Third of the Night
            SpecialTimeRow(
                iconName: "moon.stars.fill",
                iconColor: Theme.accent.opacity(0.75),
                label: L10n.lastThirdNight(language),
                timeRange: lastThirdString
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.background.opacity(0.65))
        )
        .padding(.bottom, 2)
    }
}

// MARK: - Prayer Row

struct PrayerRowView: View {
    let prayer: PrayerTime
    let isNext: Bool
    var language: AppLanguage = .german
    /// Kerahat (disliked) period start time for prayers that have one (Dhuhr, Maghrib).
    /// Displayed in small red text immediately before the prayer time.
    var kerahatTimeString: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: prayer.kind.iconName)
                .font(.body)
                .foregroundColor(prayer.kind.iconColor)
                .frame(width: 24, alignment: .center)

            Text(L10n.prayerName(prayer.kind, language))
                .font(.subheadline.weight(isNext ? .semibold : .regular))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            if let kerahat = kerahatTimeString {
                Text(kerahat)
                    .font(.caption2.weight(.medium).monospacedDigit())
                    .foregroundColor(Color(hex: "FF5252"))
                    .padding(.trailing, 4)
            }

            Text(prayer.timeString)
                .font(.subheadline.monospacedDigit())
                .foregroundColor(isNext ? Theme.accent : Theme.textPrimary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isNext ? Theme.accent.opacity(0.15) : Color.clear)
        )
    }
}

// MARK: - Special Time Row

private struct SpecialTimeRow: View {
    let iconName: String
    let iconColor: Color
    let label: String
    let timeRange: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.body)
                .foregroundColor(iconColor)
                .frame(width: 24, alignment: .center)

            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Text(timeRange)
                .font(.subheadline.monospacedDigit())
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
    }
}

// MARK: - Preview

#Preview {
    PrayerTimesCardView(
        prayers: PrayerKind.allCases.map { PrayerTime(kind: $0, timeString: "00:00", referenceDate: Date()) },
        nextPrayer: PrayerTime(kind: .fajr, timeString: "05:22", referenceDate: Date()),
        kerahatTimes: [.dhuhr: "11:45", .maghrib: "16:45"],
        language: .german
    )
    .environmentObject(AppState())
    .padding()
    .background(Theme.background)
}
