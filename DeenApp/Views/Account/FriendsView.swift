//
//  FriendsView.swift
//  DeenApp
//
//  Liste der Freunde, ein-/ausgehende Anfragen, Freund-hinzufügen-Feld.
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountVM: AccountViewModel

    @State private var searchInput: String = ""
    @State private var showSentToast: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 22) {
                headerCard
                addFriendCard
                if !accountVM.incomingRequests.isEmpty {
                    requestSection(
                        title: L10n.friendsIncoming(appState.appLanguage),
                        items: accountVM.incomingRequests,
                        actions: incomingActions
                    )
                }
                if !accountVM.outgoingRequests.isEmpty {
                    requestSection(
                        title: L10n.friendsOutgoing(appState.appLanguage),
                        items: accountVM.outgoingRequests,
                        actions: outgoingActions
                    )
                }
                friendsListSection
                signOutButton
                deleteAccountButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .confirmationDialog(
            L10n.accountDeleteConfirmTitle(appState.appLanguage),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.accountDelete(appState.appLanguage), role: .destructive) {
                Task {
                    // Geräte-Token zuerst lösen — wie beim Sign-out.
                    await PushTokenService.shared.removeTokenForCurrentUser()
                    await accountVM.deleteAccount()
                }
            }
            Button(L10n.commonCancel(appState.appLanguage), role: .cancel) {}
        } message: {
            Text(L10n.accountDeleteConfirmMessage(appState.appLanguage))
        }
        .overlay(alignment: .top) {
            if showSentToast {
                Text(L10n.friendsRequestSent(appState.appLanguage))
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Theme.accent))
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.accent)
            Text(accountVM.account?.visibleName ?? "")
                .font(.title3.weight(.semibold))
                .foregroundColor(Theme.textPrimary)
            if let username = accountVM.account?.username {
                Text("@\(username)")
                    .font(.footnote)
                    .foregroundColor(Theme.textSecondary)
            }
            Text(L10n.accountSubtitleSignedIn(appState.appLanguage))
                .font(.caption2)
                .foregroundColor(Theme.textSecondary.opacity(0.7))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
        )
    }

    // MARK: - Add friend

    private var addFriendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(L10n.friendsAdd(appState.appLanguage))
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            } icon: {
                Image(systemName: "person.fill.badge.plus")
                    .foregroundColor(Theme.accent)
            }
            HStack(spacing: 10) {
                Image(systemName: "at")
                    .foregroundColor(Theme.accent)
                    .font(.system(size: 14))
                TextField(L10n.friendsSearchPlaceholder(appState.appLanguage), text: $searchInput)
                    .textFieldStyle(.plain)
                    .foregroundColor(Theme.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($searchFocused)
                    .onSubmit(sendRequest)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.background)
            )

            Button(action: sendRequest) {
                HStack {
                    if accountVM.isWorking {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    }
                    Text(L10n.friendsAdd(appState.appLanguage))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.accent)
                )
            }
            .disabled(accountVM.isWorking || searchInput.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(searchInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.55 : 1)

            if let error = accountVM.errorMessage, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
        )
    }

    private func sendRequest() {
        let raw = searchInput
        searchFocused = false
        Task {
            await accountVM.sendRequest(toUsername: raw)
            if accountVM.errorMessage == nil {
                searchInput = ""
                withAnimation { showSentToast = true }
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                withAnimation { showSentToast = false }
            }
        }
    }

    // MARK: - Requests

    private func requestSection(
        title: String,
        items: [FriendRequest],
        actions: @escaping (FriendRequest) -> AnyView
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.leading, 4)
            VStack(spacing: 8) {
                ForEach(items) { request in
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(Theme.accent)
                            .font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(request.visibleName)
                                .font(.body)
                                .foregroundColor(Theme.textPrimary)
                            Text("@\(request.username)")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                        actions(request)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.cardBackground)
                    )
                }
            }
        }
    }

    private func incomingActions(_ request: FriendRequest) -> AnyView {
        AnyView(
            HStack(spacing: 8) {
                Button {
                    Task { await accountVM.accept(request) }
                } label: {
                    Text(L10n.friendsAccept(appState.appLanguage))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Theme.accent))
                }
                Button {
                    Task { await accountVM.reject(request) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(8)
                        .background(Circle().fill(Theme.background))
                }
            }
        )
    }

    private func outgoingActions(_ request: FriendRequest) -> AnyView {
        AnyView(
            Button {
                Task { await accountVM.cancelOutgoing(request) }
            } label: {
                Text(L10n.friendsCancelRequest(appState.appLanguage))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(Theme.background))
            }
        )
    }

    // MARK: - Friends list

    private var friendsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.friendsTitle(appState.appLanguage))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.leading, 4)

            if accountVM.friends.isEmpty {
                Text(L10n.friendsNone(appState.appLanguage))
                    .font(.footnote)
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                            .fill(Theme.cardBackground)
                    )
            } else {
                VStack(spacing: 8) {
                    ForEach(accountVM.friends) { friend in
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(Theme.accent)
                                .font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.visibleName)
                                    .font(.body)
                                    .foregroundColor(Theme.textPrimary)
                                Text("@\(friend.username)")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                            Button {
                                Task { await accountVM.remove(friend) }
                            } label: {
                                Text(L10n.friendsRemove(appState.appLanguage))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Theme.textSecondary)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Capsule().fill(Theme.background))
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.cardBackground)
                        )
                    }
                }
            }
        }
    }

    private var signOutButton: some View {
        Button {
            accountVM.signOut()
        } label: {
            Text(L10n.accountSignOut(appState.appLanguage))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.red.opacity(0.55), lineWidth: 1)
                )
        }
        .padding(.top, 8)
    }

    private var deleteAccountButton: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            Text(L10n.accountDelete(appState.appLanguage))
                .font(.footnote.weight(.medium))
                .foregroundColor(.red.opacity(0.8))
        }
        .disabled(accountVM.isWorking)
    }
}
