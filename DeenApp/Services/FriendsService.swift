//
//  FriendsService.swift
//  DeenApp
//
//  Firestore-Wrapper für die Freunde-Funktion:
//  • Nutzer per Benutzername finden
//  • Freundschaftsanfragen senden / annehmen / ablehnen / zurückziehen
//  • Freunde live beobachten
//
//  Datenmodell:
//  usernames/{usernameLower} → { uid }
//  users/{uid} → { username, usernameLower, email, displayName, createdAt }
//  users/{uid}/friends/{friendUid} → { username, displayName, since }
//  users/{uid}/incomingRequests/{fromUid} → { username, displayName, sentAt }
//  users/{uid}/outgoingRequests/{toUid}   → { username, displayName, sentAt }
//

import Foundation
import FirebaseFirestore

enum FriendsError: LocalizedError {
    case notSignedIn
    case userNotFound
    case cannotAddSelf
    case alreadyFriends
    case requestAlreadySent
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:        return "Du musst angemeldet sein, um Freunde hinzuzufügen."
        case .userNotFound:       return "Es wurde kein Nutzer mit diesem Benutzernamen gefunden."
        case .cannotAddSelf:      return "Du kannst dich nicht selbst als Freund hinzufügen."
        case .alreadyFriends:     return "Ihr seid bereits Freunde."
        case .requestAlreadySent: return "Du hast bereits eine Anfrage geschickt."
        case .underlying(let m):  return m
        }
    }
}

@MainActor
final class FriendsService {
    static let shared = FriendsService()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Lookup

    func findUser(byUsername raw: String) async throws -> UserAccount? {
        let lower = raw.trimmingCharacters(in: .whitespaces).lowercased()
        guard !lower.isEmpty else { return nil }
        let snap = try await db.collection("usernames").document(lower).getDocument()
        guard let data = snap.data(), let uid = data["uid"] as? String else { return nil }
        return try await AuthService.shared.loadAccount(uid: uid)
    }

    // MARK: - Requests

    func sendRequest(to other: UserAccount, from me: UserAccount) async throws {
        guard other.id != me.id else { throw FriendsError.cannotAddSelf }

        // Already friends?
        let friendsDoc = try await db.collection("users").document(me.id)
            .collection("friends").document(other.id).getDocument()
        if friendsDoc.exists { throw FriendsError.alreadyFriends }

        // Already requested?
        let outDoc = try await db.collection("users").document(me.id)
            .collection("outgoingRequests").document(other.id).getDocument()
        if outDoc.exists { throw FriendsError.requestAlreadySent }

        let now = Timestamp(date: Date())
        let batch = db.batch()

        let outgoingRef = db.collection("users").document(me.id)
            .collection("outgoingRequests").document(other.id)
        batch.setData([
            "username": other.username,
            "displayName": other.displayName as Any,
            "sentAt": now
        ], forDocument: outgoingRef)

        let incomingRef = db.collection("users").document(other.id)
            .collection("incomingRequests").document(me.id)
        batch.setData([
            "username": me.username,
            "displayName": me.displayName as Any,
            "sentAt": now
        ], forDocument: incomingRef)

        try await batch.commit()
    }

    func cancelOutgoingRequest(toUid: String, myUid: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(db.collection("users").document(myUid)
            .collection("outgoingRequests").document(toUid))
        batch.deleteDocument(db.collection("users").document(toUid)
            .collection("incomingRequests").document(myUid))
        try await batch.commit()
    }

    func rejectIncomingRequest(fromUid: String, myUid: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(db.collection("users").document(myUid)
            .collection("incomingRequests").document(fromUid))
        batch.deleteDocument(db.collection("users").document(fromUid)
            .collection("outgoingRequests").document(myUid))
        try await batch.commit()
    }

    func acceptIncomingRequest(from other: UserAccount, me: UserAccount) async throws {
        let now = Timestamp(date: Date())
        let batch = db.batch()

        // `requesterUid` markiert, wer die Anfrage ursprünglich gestellt hat —
        // die Cloud Function schickt nur dem Anfragesteller die Annahme-Push.
        let myFriendRef = db.collection("users").document(me.id)
            .collection("friends").document(other.id)
        batch.setData([
            "username": other.username,
            "displayName": other.displayName as Any,
            "since": now,
            "requesterUid": other.id
        ], forDocument: myFriendRef)

        let theirFriendRef = db.collection("users").document(other.id)
            .collection("friends").document(me.id)
        batch.setData([
            "username": me.username,
            "displayName": me.displayName as Any,
            "since": now,
            "requesterUid": other.id
        ], forDocument: theirFriendRef)

        batch.deleteDocument(db.collection("users").document(me.id)
            .collection("incomingRequests").document(other.id))
        batch.deleteDocument(db.collection("users").document(other.id)
            .collection("outgoingRequests").document(me.id))

        try await batch.commit()
    }

    func removeFriend(otherUid: String, myUid: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(db.collection("users").document(myUid)
            .collection("friends").document(otherUid))
        batch.deleteDocument(db.collection("users").document(otherUid)
            .collection("friends").document(myUid))
        try await batch.commit()
    }

    // MARK: - Observers

    func observeFriends(uid: String, onChange: @escaping ([FriendInfo]) -> Void) -> ListenerRegistration {
        db.collection("users").document(uid).collection("friends")
            .order(by: "since", descending: true)
            .addSnapshotListener { snap, _ in
                let list: [FriendInfo] = snap?.documents.map { doc in
                    let d = doc.data()
                    return FriendInfo(
                        id: doc.documentID,
                        username: d["username"] as? String ?? "",
                        displayName: d["displayName"] as? String,
                        since: (d["since"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []
                onChange(list)
            }
    }

    func observeIncoming(uid: String, onChange: @escaping ([FriendRequest]) -> Void) -> ListenerRegistration {
        observeRequests(uid: uid, collection: "incomingRequests", direction: .incoming, onChange: onChange)
    }

    func observeOutgoing(uid: String, onChange: @escaping ([FriendRequest]) -> Void) -> ListenerRegistration {
        observeRequests(uid: uid, collection: "outgoingRequests", direction: .outgoing, onChange: onChange)
    }

    private func observeRequests(
        uid: String,
        collection: String,
        direction: FriendRequest.Direction,
        onChange: @escaping ([FriendRequest]) -> Void
    ) -> ListenerRegistration {
        db.collection("users").document(uid).collection(collection)
            .order(by: "sentAt", descending: true)
            .addSnapshotListener { snap, _ in
                let list: [FriendRequest] = snap?.documents.map { doc in
                    let d = doc.data()
                    return FriendRequest(
                        id: doc.documentID,
                        username: d["username"] as? String ?? "",
                        displayName: d["displayName"] as? String,
                        sentAt: (d["sentAt"] as? Timestamp)?.dateValue() ?? Date(),
                        direction: direction
                    )
                } ?? []
                onChange(list)
            }
    }
}
