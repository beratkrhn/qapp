//
//  PushTokenService.swift
//  DeenApp
//
//  Brückenklasse zwischen UNUserNotificationCenter / APNs / Firebase Messaging
//  und dem Firestore-Speicher der FCM-Tokens.
//
//  Datenmodell:
//    users/{uid}/fcmTokens/{tokenId} →   (tokenId = Token mit "/"→"_")
//      { token: String, platform: "ios", updatedAt: Timestamp }
//
//  Ein Eintrag entspricht einer Geräte-Installation. Tokens werden aktualisiert,
//  wenn sich der Auth-Nutzer ändert oder Firebase ein neues Token ausstellt.
//

import Foundation
import Combine
import UIKit
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore

@MainActor
final class PushTokenService: NSObject {

    static let shared = PushTokenService()

    private let db = Firestore.firestore()
    private var accountSub: AnyCancellable?
    private var lastSavedUid: String?
    private var cachedFCMToken: String?

    private override init() { super.init() }

    /// Initialisiert Messaging-Delegation und beobachtet Auth-Wechsel.
    /// Muss einmal pro App-Start aus `application(_:didFinishLaunching…)` /
    /// dem Adapter aufgerufen werden.
    func bootstrap() {
        Messaging.messaging().delegate = self
        accountSub = AuthService.shared.currentAccountSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] account in
                self?.persistTokenIfPossible(uid: account?.id)
                // Meldet sich ein Nutzer in laufender Session an, Push-
                // Berechtigung direkt anfragen (nicht erst beim nächsten
                // Kaltstart).
                if account != nil {
                    self?.requestAuthorizationIfNeeded()
                }
            }
    }

    /// Fragt — falls noch nicht geschehen — die Push-Berechtigung an und
    /// registriert das Gerät bei APNs.
    func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    if granted {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }

    /// Wird vom AppDelegate-Adapter weitergereicht.
    func setAPNsToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    /// Entfernt das FCM-Token dieses Geräts aus dem aktuell angemeldeten
    /// Account. Muss VOR dem Auth-Sign-out laufen — danach verweigern die
    /// Firestore-Rules den Zugriff und Pushes des alten Accounts würden
    /// dieses Gerät weiter erreichen.
    func removeTokenForCurrentUser() async {
        guard let uid = AuthService.shared.currentUid,
              let token = cachedFCMToken else { return }
        let ref = db.collection("users").document(uid)
            .collection("fcmTokens").document(Self.documentId(for: token))
        try? await ref.delete()
    }

    // MARK: - Firestore mirror

    private func persistTokenIfPossible(uid: String?) {
        lastSavedUid = uid
        guard let uid, let token = cachedFCMToken else { return }
        write(token: token, uid: uid)
    }

    private func write(token: String, uid: String) {
        let docId = Self.documentId(for: token)
        let ref = db.collection("users").document(uid)
            .collection("fcmTokens").document(docId)
        ref.setData([
            "token": token,
            "platform": "ios",
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    private static func documentId(for token: String) -> String {
        // Firestore-IDs dürfen keine "/" enthalten, sonst funktionieren
        // Subpfade nicht; ein Token ist Base64-URL und sicher.
        token.replacingOccurrences(of: "/", with: "_")
    }
}

// MARK: - MessagingDelegate

extension PushTokenService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        Task { @MainActor in
            self.cachedFCMToken = token
            if let uid = self.lastSavedUid ?? AuthService.shared.currentUid {
                self.write(token: token, uid: uid)
            }
        }
    }
}
