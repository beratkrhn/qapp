//
//  BottomInfoCardsView.swift
//  DeenApp
//

import SwiftUI

struct BottomInfoCardsView: View {
    @EnvironmentObject var appState: AppState
    var language: AppLanguage = .german

    var body: some View {
        HStack(spacing: 14) {
            Button(action: { appState.selectedTab = .quran }) {
                SmallInfoCard(
                    icon: "book.fill",
                    iconColor: Theme.textPrimary,
                    title: L10n.tabQuran(language),
                    subtitle: L10n.quranContinue(language)
                )
            }
            .buttonStyle(.plain)
            Button(action: { appState.selectedTab = .lernen }) {
                SmallInfoCard(
                    icon: "brain",
                    iconColor: Theme.iconBrain,
                    title: L10n.tabLernen(language),
                    subtitle: L10n.flashcards(language)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Daily Reading Goal Card

struct DailyReadingGoalCard: View {
    @ObservedObject var appState: AppState
    var language: AppLanguage = .german

    private var progress: Double {
        guard appState.dailyGoalPages > 0 else { return 0 }
        return min(Double(appState.dailyReadPages) / Double(appState.dailyGoalPages), 1.0)
    }
    private var goalReached: Bool { appState.dailyReadPages >= appState.dailyGoalPages }

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {

                // Header row
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.quranDailyGoal(language))
                            .font(.caption.weight(.medium))
                            .tracking(0.8)
                            .foregroundColor(Theme.textSection)
                        if goalReached {
                            Text(L10n.quranDailyGoalReached(language))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Theme.accent)
                        } else {
                            Text("\(appState.dailyReadPages) / \(appState.dailyGoalPages) \(L10n.quranDailyPages(language))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(
                                goalReached ? Theme.accent.opacity(0.35) : Theme.textSecondary.opacity(0.2),
                                lineWidth: 1.5
                            )
                            .frame(width: 40, height: 40)
                        Image(systemName: goalReached ? "checkmark.seal.fill" : "book.fill")
                            .font(.body)
                            .foregroundColor(goalReached ? Theme.accent : Theme.textSecondary.opacity(0.6))
                    }
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Theme.background.opacity(0.8))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: goalReached
                                        ? [Theme.accent, Theme.accent.opacity(0.7)]
                                        : [Theme.iconFajr, Theme.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * progress, progress > 0 ? 8 : 0), height: 8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: progress)
                    }
                }
                .frame(height: 8)

                // Page dots indicator
                HStack(spacing: 5) {
                    ForEach(0..<appState.dailyGoalPages, id: \.self) { i in
                        Circle()
                            .fill(i < appState.dailyReadPages ? Theme.accent : Theme.textSecondary.opacity(0.2))
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.2).delay(Double(i) * 0.04), value: appState.dailyReadPages)
                    }
                    Spacer()
                    Button(action: { appState.selectedTab = .quran }) {
                        Text(L10n.quranContinue(language))
                            .font(.caption.weight(.medium))
                            .foregroundColor(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct SmallInfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    BottomInfoCardsView(language: .german)
        .environmentObject(AppState())
        .padding()
        .background(Theme.background)
}
