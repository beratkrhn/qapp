//
//  HomeGoalsCard.swift
//  DeenApp
//
//  Ersatz für die alte "Tagesziel"-Karte: zeigt eine kompakte Übersicht der
//  aktiven Ziele auf dem Dashboard. Tipp → öffnet die vollständige Ziel-Liste.
//

import SwiftUI

struct HomeGoalsCard: View {
    @EnvironmentObject var goalsVM: GoalsViewModel
    @EnvironmentObject var appState: AppState
    var onTap: () -> Void

    private var visible: [Goal] { Array(goalsVM.activeGoals.prefix(3)) }

    var body: some View {
        Button(action: onTap) {
            CardContainer {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    if visible.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 10) {
                            ForEach(visible) { goal in
                                GoalProgressRow(goal: goal, language: appState.appLanguage)
                            }
                        }
                        if goalsVM.activeGoals.count > visible.count {
                            Text(L10n.goalsMoreCount(appState.appLanguage,
                                                     goalsVM.activeGoals.count - visible.count))
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.goalsSectionTitle(appState.appLanguage))
                    .font(.caption.weight(.medium))
                    .tracking(0.8)
                    .foregroundColor(Theme.textSection)
                Text(visible.isEmpty
                     ? L10n.goalsSetFirst(appState.appLanguage)
                     : L10n.goalsActiveCount(appState.appLanguage, goalsVM.activeGoals.count))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(Theme.accent.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 40, height: 40)
                Image(systemName: "target")
                    .font(.body)
                    .foregroundColor(Theme.accent)
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(Theme.accent)
            Text(L10n.goalsAddTapHint(appState.appLanguage))
                .font(.footnote)
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Single goal row

struct GoalProgressRow: View {
    let goal: Goal
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: goal.type.iconName)
                    .foregroundColor(Theme.accent)
                    .frame(width: 22)
                Text(goal.title(language: language))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text(goal.progressLabel(language: language))
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Theme.textSecondary)
                if goal.visibleToFriends {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundColor(Theme.accent.opacity(0.7))
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Theme.background.opacity(0.8))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Theme.iconFajr, Theme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * goal.progressFraction,
                                          goal.progressFraction > 0 ? 6 : 0), height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75),
                                   value: goal.progressFraction)
                }
            }
            .frame(height: 6)
        }
    }
}
