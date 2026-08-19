//
//  AccountViewModel.swift
//  DeenApp
//
//  Hält den Auth-Zustand sowie die Freunde-/Anfrage-Listen.
//  Wird in DeenAppApp als @StateObject erzeugt und per .environmentObject
//  in den View-Baum gereicht.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class AccountViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var account: UserAccount?
    @Published private(set) var friends: [FriendInfo] = []
    @Published private(set) var incomingRequests: [FriendRequest] = []
    @Published private(set) var outgoingRequests: [FriendRequest] = []
    @Published var isWorking: Bool = false
    @Published var errorMessage: String?
    /// Nicht-Fehler-Rückmeldung (z. B. "Reset-Mail verschickt").
    @Published var infoMessage: String?

    var isSignedIn: Bool { account != nil }

    // MARK: - Internal

    private var accountSub: AnyCancellable?
    private var friendsListener: ListenerRegistration?
    private var incomingListener: ListenerRegistration?
    private var outgoingListener: ListenerRegistration?

    init() {
        accountSub = AuthService.shared.currentAccountSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] account in
                guard let self else { return }
                self.account = account
                self.tearDownListeners()
                if let account { self.attachListeners(uid: account.id) }
                else { self.clearLists() }
            }
    }

    deinit {
        friendsListener?.remove()
        incomingListener?.remove()
        outgoingListener?.remove()
    }

    // MARK: - Auth actions

    func signUp(email: String, password: String, username: String, displayName: String?) async {
        await perform {
            _ = try await AuthService.shared.signUp(
                email: email, password: password,
                username: username, displayName: displayName
            )
        }
    }

    func signIn(email: String, password: String) async {
        await perform {
            _ = try await AuthService.shared.signIn(email: email, password: password)
        }
    }

    func signOut() {
        Task { @MainActor in
            // Geräte-Token vom Account lösen, solange die Rules den Zugriff
            // noch erlauben — sonst kämen Pushes des alten Accounts weiter an.
            await PushTokenService.shared.removeTokenForCurrentUser()
            do { try AuthService.shared.signOut() }
            catch { errorMessage = error.localizedDescription }
        }
    }

    func sendPasswordReset(email: String, confirmation: String) async {
        await perform {
            try await AuthService.shared.sendPasswordReset(email: email)
        }
        if errorMessage == nil { infoMessage = confirmation }
    }

    /// Löscht das Konto endgültig (Firestore-Spuren + Auth-Nutzer).
    func deleteAccount() async {
        await perform {
            try await AuthService.shared.deleteAccount()
        }
    }

    // MARK: - Friend actions

    func sendRequest(toUsername raw: String) async {
        guard let me = account else { errorMessage = AuthError.notSignedIn.localizedDescription; return }
        await perform {
            guard let other = try await FriendsService.shared.findUser(byUsername: raw) else {
                throw FriendsError.userNotFound
            }
            try await FriendsService.shared.sendRequest(to: other, from: me)
        }
    }

    func accept(_ request: FriendRequest) async {
        guard let me = account else { return }
        await perform {
            // Das Profil des Anfragestellers ist vor der Freundschaft nicht
            // lesbar (Rules); die denormalisierten Felder aus dem Request-Doc
            // reichen für das Friend-Doc aus.
            let other = UserAccount(
                id: request.id,
                username: request.username,
                usernameLower: request.username.lowercased(),
                email: "",
                displayName: request.displayName,
                createdAt: request.sentAt
            )
            try await FriendsService.shared.acceptIncomingRequest(from: other, me: me)
        }
    }

    func reject(_ request: FriendRequest) async {
        guard let me = account else { return }
        await perform {
            try await FriendsService.shared.rejectIncomingRequest(fromUid: request.id, myUid: me.id)
        }
    }

    func cancelOutgoing(_ request: FriendRequest) async {
        guard let me = account else { return }
        await perform {
            try await FriendsService.shared.cancelOutgoingRequest(toUid: request.id, myUid: me.id)
        }
    }

    func remove(_ friend: FriendInfo) async {
        guard let me = account else { return }
        await perform {
            try await FriendsService.shared.removeFriend(otherUid: friend.id, myUid: me.id)
        }
    }

    // MARK: - Helpers

    private func perform(_ block: @escaping () async throws -> Void) async {
        errorMessage = nil
        infoMessage = nil
        isWorking = true
        do {
            try await block()
        } catch {
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }

    private func attachListeners(uid: String) {
        friendsListener = FriendsService.shared.observeFriends(uid: uid) { [weak self] in
            self?.friends = $0
        }
        incomingListener = FriendsService.shared.observeIncoming(uid: uid) { [weak self] in
            self?.incomingRequests = $0
        }
        outgoingListener = FriendsService.shared.observeOutgoing(uid: uid) { [weak self] in
            self?.outgoingRequests = $0
        }
    }

    private func tearDownListeners() {
        friendsListener?.remove(); friendsListener = nil
        incomingListener?.remove(); incomingListener = nil
        outgoingListener?.remove(); outgoingListener = nil
    }

    private func clearLists() {
        friends = []
        incomingRequests = []
        outgoingRequests = []
    }
}
