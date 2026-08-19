//
//  GoalDetailView.swift
//  DeenApp
//
//  Detail-Sheet eines Ziels: zeigt Fortschritt, erlaubt das Abhaken von
//  Gebeten/Sunnah-Einheiten, die Sichtbarkeit zu wechseln oder das Ziel zu
//  löschen.
//

import SwiftUI

struct GoalDetailView: View {
    @EnvironmentObject var goalsVM: GoalsViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let goalId: String

    @State private var showDeleteConfirm = false

    private var goal: Goal? { goalsVM.goals.first(where: { $0.id == goalId }) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    if let goal {
                        VStack(alignment: .leading, spacing: 18) {
                            headerCard(goal: goal)
                            progressCard(goal: goal)
                            typeBody(goal: goal)
                            visibilityCard(goal: goal)
                            deleteButton(goal: goal)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                    }
                }
            }
            .navigationTitle(L10n.goalsDetailTitle(appState.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.commonDone(appState.appLanguage)) { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .confirmationDialog(
                L10n.goalsDelete(appState.appLanguage),
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.goalsDelete(appState.appLanguage), role: .destructive) {
                    if let goal {
                        goalsVM.delete(goal)
                        dismiss()
                    }
                }
                Button(L10n.commonCancel(appState.appLanguage), role: .cancel) {}
            }
        }
    }

    // MARK: - Cards

    private func headerCard(goal: Goal) -> some View {
        CardContainer {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: goal.type.iconName)
                        .font(.title3)
                        .foregroundColor(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title(language: appState.appLanguage))
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Text(goal.progressLabel(language: appState.appLanguage))
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }
        }
    }

    private func progressCard(goal: Goal) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.goalsProgress(appState.appLanguage).uppercased())
                    .font(.caption.weight(.medium))
                    .tracking(0.8)
                    .foregroundColor(Theme.textSection)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Theme.background.opacity(0.8))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.iconFajr, Theme.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * goal.progressFraction,
                                              goal.progressFraction > 0 ? 8 : 0),
                                   height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
    }

    @ViewBuilder
    private func typeBody(goal: Goal) -> some View {
        switch goal.type {
        case .khatmByDate:
            khatmCard(goal: goal)
        case .dailyQuranPages:
            dailyPagesCard(goal: goal)
        case .fivePrayersDaily:
            prayersCard(goal: goal)
        case .sunnahPrayer:
            sunnahCard(goal: goal)
        }
    }

    private func khatmCard(goal: Goal) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                row(L10n.goalsKhatmReadSoFar(appState.appLanguage),
                    "\(goal.khatmPagesRead) / \(Goal.totalMushafPages)")
                row(L10n.goalsKhatmDaysLeft(appState.appLanguage),
                    "\(goal.khatmDaysRemaining)")
                row(L10n.goalsKhatmPerDay(appState.appLanguage),
                    "\(goal.khatmPagesPerDayNeeded) \(L10n.goalsPagesUnit(appState.appLanguage))")
                pageAdjustRow(goal: goal)
            }
        }
    }

    private func dailyPagesCard(goal: Goal) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                row(L10n.goalsDailyReadToday(appState.appLanguage),
                    "\(goal.pagesReadToday) \(L10n.goalsPagesUnit(appState.appLanguage))")
                row(L10n.goalsDailyTarget(appState.appLanguage),
                    "\(goal.dailyPagesTarget ?? 0) \(L10n.goalsPagesUnit(appState.appLanguage))")
                pageAdjustRow(goal: goal)
            }
        }
    }

    /// Manuelle +/- Korrektur für die heutige Seitenanzahl.
    private func pageAdjustRow(goal: Goal) -> some View {
        HStack {
            Text(L10n.goalsAdjustToday(appState.appLanguage))
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            Spacer()
            HStack(spacing: 4) {
                stepperButton(systemName: "minus.circle.fill") {
                    goalsVM.adjustPagesToday(on: goal, by: -1)
                }
                Text("\(goal.pagesReadToday)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundColor(Theme.textPrimary)
                    .frame(minWidth: 32)
                stepperButton(systemName: "plus.circle.fill") {
                    goalsVM.adjustPagesToday(on: goal, by: +1)
                }
            }
        }
        .padding(.top, 6)
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3)
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func prayersCard(goal: Goal) -> some View {
        let prayedToday = goal.prayersToday
        return CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.goalsTickPrayersToday(appState.appLanguage))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.textPrimary)
                VStack(spacing: 6) {
                    ForEach(FardPrayer.allCases, id: \.self) { prayer in
                        Button {
                            goalsVM.togglePrayer(prayer, on: goal)
                        } label: {
                            HStack {
                                Image(systemName: prayedToday.contains(prayer) ?
                                      "checkmark.circle.fill" : "circle")
                                    .foregroundColor(prayedToday.contains(prayer) ?
                                                     Theme.accent : Theme.textSecondary)
                                Text(prayer.localizedName(language: appState.appLanguage))
                                    .font(.body)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func sunnahCard(goal: Goal) -> some View {
        let loggedToday = goal.sunnahDates.contains(GoalDateKey.today)
        return CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                row(L10n.goalsSunnahThisWeek(appState.appLanguage),
                    "\(goal.sunnahCountThisWeek) / \(goal.sunnahWeeklyTarget ?? 0)")
                Button {
                    if loggedToday { goalsVM.unlogSunnah(on: goal) }
                    else { goalsVM.logSunnah(on: goal) }
                } label: {
                    HStack {
                        Image(systemName: loggedToday ? "checkmark.circle.fill" : "plus.circle.fill")
                        Text(loggedToday
                             ? L10n.goalsSunnahLoggedToday(appState.appLanguage)
                             : L10n.goalsSunnahLogToday(appState.appLanguage))
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(loggedToday ? Theme.textSecondary : Theme.accent))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func visibilityCard(goal: Goal) -> some View {
        CardContainer {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(Theme.accent)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.goalsShareWithFriends(appState.appLanguage))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text(L10n.goalsShareBlurb(appState.appLanguage))
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { goal.visibleToFriends },
                    set: { goalsVM.setVisibleToFriends(goal, visible: $0) }
                ))
                .labelsHidden()
                .tint(Theme.accent)
            }
        }
    }

    private func deleteButton(goal: Goal) -> some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Text(L10n.goalsDelete(appState.appLanguage))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.destructive)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.destructive.opacity(0.55), lineWidth: 1)
                )
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.textPrimary)
        }
    }
}
