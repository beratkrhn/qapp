//
//  GoalsListView.swift
//  DeenApp
//
//  Vollständige Verwaltungsansicht für alle Ziele des Nutzers (Sheet vom
//  Dashboard aus). Erlaubt das Anlegen neuer Ziele und das Öffnen einzelner
//  Ziel-Details.
//

import SwiftUI

struct GoalsListView: View {
    @EnvironmentObject var goalsVM: GoalsViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showEditor = false
    @State private var selectedGoal: Goal?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        if goalsVM.activeGoals.isEmpty {
                            emptyState
                        }
                        ForEach(goalsVM.activeGoals) { goal in
                            Button {
                                selectedGoal = goal
                            } label: {
                                CardContainer {
                                    GoalProgressRow(goal: goal, language: appState.appLanguage)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(L10n.goalsSectionTitle(appState.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.commonDone(appState.appLanguage)) { dismiss() }
                        .foregroundColor(Theme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showEditor = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                GoalEditorView()
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailView(goalId: goal.id)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "target")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Theme.accent.opacity(0.7))
            Text(L10n.goalsEmptyTitle(appState.appLanguage))
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text(L10n.goalsEmptyBody(appState.appLanguage))
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button(action: { showEditor = true }) {
                Text(L10n.goalsAddNew(appState.appLanguage))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22).padding(.vertical, 12)
                    .background(Capsule().fill(Theme.accent))
            }
        }
        .padding(.vertical, 32)
    }
}
