//
//  NotificationPreferencesService.swift
//  DeenApp
//
//  Spiegelt die Empfangs-Einstellungen für "Anstupser" (Nudges) nach
//  Firestore: `users/{uid}/notificationPreferences/main`. Die Cloud Function
//  liest dort, ob der Empfänger Push-Nachrichten zulässt und wie viele pro
//  Tag.
//

import Foundation
import FirebaseFirestore

@MainActor
final class NotificationPreferencesService {

    static let shared = NotificationPreferencesService()
    private let db = Firestore.firestore()
    private init() {}

    func publish(receive: Bool, maxPerDay: Int, uid: String) {
        let ref = db.collection("users").document(uid)
            .collection("notificationPreferences").document("main")
        ref.setData([
            "receiveNudges": receive,
            "maxNudgesPerDay": maxPerDay,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
}
