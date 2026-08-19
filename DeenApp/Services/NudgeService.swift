//
//  NudgeService.swift
//  DeenApp
//
//  Schreibt einen "Anstupser" in den Posteingang eines Freundes. Die
//  eigentliche Zustellung (Friendship-Validierung, Tageslimit, FCM-Versand)
//  erledigt die Cloud Function `sendNudge` auf der Backend-Seite.
//

import Foundation
import FirebaseFirestore

@MainActor
final class NudgeService {

    static let shared = NudgeService()
    private let db = Firestore.firestore()
    private init() {}

    /// Erzeugt einen neuen Nudge-Dokument im Posteingang des Empfängers.
    /// - Parameters:
    ///   - recipientUid: uid des Empfängers
    ///   - sender:       eingeloggter Account des Senders
    ///   - title:        Push-Titel (z. B. App-Name)
    ///   - body:         eigentliche Nachricht
    ///   - goalType:     optional, hilft beim Routing im Empfänger-Client
    func send(
        toRecipientUid recipientUid: String,
        sender: UserAccount,
        title: String,
        body: String,
        goalType: GoalType?
    ) async throws {
        var payload: [String: Any] = [
            "senderUid": sender.id,
            "senderUsername": sender.username,
            "title": title,
            "body": body,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let goalType { payload["goalType"] = goalType.rawValue }

        let ref = db.collection("users").document(recipientUid)
            .collection("nudges").document()
        try await ref.setData(payload)
    }
}
