//
//  NotificationPreferencesService.swift
//  DeenApp
//
//  Spiegelt die Empfangs-Einstellungen für "Anstupser" (Nudges) nach
//  Firestore: `users/{uid}/notificationPreferences/main`. Die Cloud Function
//  liest dort nur noch, OB der Empfänger Push-Nachrichten zulässt — wie viele
//  pro Tag ankommen, steht fest in `MAX_NUDGES_PER_DAY` (Cloud Function) und
//  ist weder vom Sender noch vom Empfänger änderbar.
//

import Foundation
import FirebaseFirestore

@MainActor
final class NotificationPreferencesService {

    static let shared = NotificationPreferencesService()
    private let db = Firestore.firestore()
    private init() {}

    func publish(receive: Bool, uid: String) {
        let ref = db.collection("users").document(uid)
            .collection("notificationPreferences").document("main")
        ref.setData([
            "receiveNudges": receive,
            // Legacy-Feld aus der Zeit des einstellbaren Limits entfernen —
            // die Rules lehnen Dokumente mit diesem Feld inzwischen ab.
            "maxNudgesPerDay": FieldValue.delete(),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
}
