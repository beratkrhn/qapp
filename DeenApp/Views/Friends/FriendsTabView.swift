//
//  FriendsTabView.swift
//  DeenApp
//
//  Eigener Tab im Hauptnavigation: zeigt die Freundes-Liste plus die
//  öffentlich geteilten Ziele jedes Freundes. Tippt der Nutzer auf einen
//  Freund, öffnet sich ein Sheet mit allen geteilten Zielen + Fortschritt.
//

import SwiftUI
import Combine
import FirebaseFirestore

struct FriendsTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountVM: AccountViewModel
    @StateObject private var feed = FriendGoalsFeed()

    @State private var selectedFriend: FriendInfo?
    @State private var showAccountSheet = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if accountVM.isSignedIn {
                signedInBody
            } else {
                signedOutBody
            }
        }
        .onChange(of: accountVM.friends) { _, newValue in
            feed.refresh(friendUids: newValue.map(\.id))
        }
        .task {
            feed.refresh(friendUids: accountVM.friends.map(\.id))
        }
        .sheet(isPresented: $showAccountSheet) {
            NavigationStack { AccountHomeView() }
        }
        .sheet(item: $selectedFriend) { friend in
            FriendDetailSheet(friend: friend, goals: feed.goalsByUid[friend.id] ?? [])
        }
    }

    // MARK: - Body variants

    private var signedInBody: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if accountVM.friends.isEmpty {
                    emptyFriendsCard
                } else {
                    ForEach(accountVM.friends) { friend in
                        Button {
                            selectedFriend = friend
                        } label: {
                            friendRow(friend, goals: feed.goalsByUid[friend.id] ?? [])
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
    }

    private var signedOutBody: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 52, weight: .light))
                .foregroundColor(Theme.accent)
            Text(L10n.friendsTabSignInTitle(appState.appLanguage))
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text(L10n.friendsTabSignInBody(appState.appLanguage))
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showAccountSheet = true
            } label: {
                Text(L10n.friendsTabSignInButton(appState.appLanguage))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22).padding(.vertical, 12)
                    .background(Capsule().fill(Theme.accent))
            }
        }
        .padding(.bottom, 120)
    }

    // MARK: - Cards

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.friendsTabTitle(appState.appLanguage))
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.textPrimary)
                Text(L10n.friendsTabSubtitle(appState.appLanguage))
                    .font(.footnote)
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
            Button(action: { showAccountSheet = true }) {
                Image(systemName: "person.crop.circle")
                    .font(.title2)
                    .foregroundColor(Theme.accent)
                    .padding(10)
                    .background(Circle().fill(Theme.cardBackground))
            }
        }
    }

    private var emptyFriendsCard: some View {
        CardContainer {
            VStack(spacing: 10) {
                Image(systemName: "person.fill.badge.plus")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Theme.accent.opacity(0.7))
                Text(L10n.friendsTabEmpty(appState.appLanguage))
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                Button {
                    showAccountSheet = true
                } label: {
                    Text(L10n.friendsAdd(appState.appLanguage))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Theme.accent))
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
    }

    private func friendRow(_ friend: FriendInfo, goals: [Goal]) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title2)
                        .foregroundColor(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.visibleName)
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        Text("@\(friend.username)")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    if goals.isEmpty {
                        Text(L10n.friendsTabNoSharedGoals(appState.appLanguage))
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary.opacity(0.7))
                    } else {
                        Text("\(goals.count)")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(Theme.accent))
                    }
                }
                if let firstGoal = goals.first {
                    Divider().background(Theme.textSecondary.opacity(0.2))
                    GoalProgressRow(goal: firstGoal, language: appState.appLanguage)
                    if goals.count > 1 {
                        Text(L10n.goalsMoreCount(appState.appLanguage, goals.count - 1))
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Friend detail sheet

private struct FriendDetailSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let friend: FriendInfo
    let goals: [Goal]

    @State private var nudgeGoal: Goal?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(goals) { goal in
                            CardContainer {
                                VStack(alignment: .leading, spacing: 12) {
                                    GoalProgressRow(goal: goal, language: appState.appLanguage)
                                    Button {
                                        nudgeGoal = goal
                                    } label: {
                                        HStack {
                                            Image(systemName: "bell.badge.fill")
                                            Text(L10n.nudgeButton(appState.appLanguage))
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(Capsule().fill(Theme.accent))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        if goals.isEmpty {
                            Text(L10n.friendsTabNoSharedGoals(appState.appLanguage))
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .padding(.top, 40)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(friend.visibleName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.commonDone(appState.appLanguage)) { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .sheet(item: $nudgeGoal) { goal in
                NudgePickerView(recipient: friend, goal: goal)
            }
        }
    }
}

// MARK: - Live feed

@MainActor
final class FriendGoalsFeed: ObservableObject {
    @Published var goalsByUid: [String: [Goal]] = [:]
    private var listeners: [String: ListenerRegistration] = [:]

    func refresh(friendUids: [String]) {
        let current = Set(listeners.keys)
        let next = Set(friendUids)
        // Entferne Listener für nicht mehr aktuelle Freunde.
        for uid in current.subtracting(next) {
            listeners.removeValue(forKey: uid)?.remove()
            goalsByUid.removeValue(forKey: uid)
        }
        // Neue Listener registrieren.
        for uid in next.subtracting(current) {
            listeners[uid] = GoalsService.shared.observeFriendGoals(friendUid: uid) { [weak self] goals in
                Task { @MainActor in self?.goalsByUid[uid] = goals }
            }
        }
    }

    nonisolated deinit {
        let snapshot = listeners
        for (_, token) in snapshot {
            token.remove()
        }
    }
}
