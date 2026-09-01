//
//  NudgeService.swift
//  DeenApp
//
//  Schreibt einen "Anstupser" in den Posteingang eines Freundes. Die
//  eigentliche Zustellung (Friendship-Validierung, Tageslimit, FCM-Versand)
//  erledigt die Cloud Function `sendNudge` auf der Backend-Seite.
//
//  Die Function schreibt ihr Ergebnis als `status`/`reason` zurück in dasselbe
//  Dokument. Der Client wartet kurz darauf — sonst würde er "gesendet" melden,
//  obwohl der Anstupser serverseitig verworfen wurde (z. B. weil der Empfänger
//  gar kein Gerät für Pushes registriert hat).
//

import Foundation
import FirebaseFirestore

/// Ergebnis der serverseitigen Zustellung eines Anstupsers.
enum NudgeDelivery: Equatable {
    /// Mindestens ein Gerät des Empfängers hat die Push erhalten.
    case delivered
    /// Die Cloud Function hat innerhalb des Zeitfensters nicht geantwortet
    /// (Kaltstart o. Ä.) — das Dokument liegt aber in Firestore.
    case pending
    /// Die Cloud Function hat den Anstupser verworfen.
    case rejected(NudgeRejection)
}

/// Ablehnungsgründe, wie sie die Cloud Function in `reason` hinterlegt.
enum NudgeRejection: String {
    case notFriend          = "not_friend"
    case invalidSender      = "invalid_sender"
    case recipientDisabled  = "recipient_disabled"
    case noTokens           = "no_tokens"
    case dailyCapReached    = "daily_cap_reached"
    case deliveryFailed     = "no_token_succeeded"
    case unknown            = "unknown"
}

@MainActor
final class NudgeService {

    static let shared = NudgeService()
    private let db = Firestore.firestore()
    private init() {}

    /// Wartepausen (Sekunden) beim Nachlesen des Zustell-Status. Summe ≈ 6 s —
    /// lang genug für einen Function-Kaltstart, kurz genug fürs UI.
    private static let statusPollDelays: [Double] = [0.6, 0.8, 1.0, 1.2, 1.2, 1.2]

    /// Erzeugt einen neuen Nudge-Dokument im Posteingang des Empfängers und
    /// meldet zurück, was die Cloud Function damit gemacht hat.
    /// - Parameters:
    ///   - recipientUid: uid des Empfängers
    ///   - sender:       eingeloggter Account des Senders
    ///   - title:        Push-Titel (z. B. App-Name)
    ///   - body:         eigentliche Nachricht
    ///   - goalType:     optional, hilft beim Routing im Empfänger-Client
    /// - Throws: nur, wenn das Dokument gar nicht geschrieben werden konnte
    ///   (kein Netz, Rules-Verstoß).
    @discardableResult
    func send(
        toRecipientUid recipientUid: String,
        sender: UserAccount,
        title: String,
        body: String,
        goalType: GoalType?
    ) async throws -> NudgeDelivery {
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

        return await awaitDelivery(of: ref)
    }

    // MARK: - Zustell-Status

    private func awaitDelivery(of ref: DocumentReference) async -> NudgeDelivery {
        for delay in Self.statusPollDelays {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            // Bewusst vom Server lesen: die lokale Kopie stammt aus dem
            // eigenen Write und hat noch kein `status`.
            guard let data = try? await ref.getDocument(source: .server).data(),
                  let status = data["status"] as? String else { continue }
            if status == "delivered" { return .delivered }
            let reason = data["reason"] as? String ?? ""
            return .rejected(NudgeRejection(rawValue: reason) ?? .unknown)
        }
        return .pending
    }
}


// MARK: - Anzeigetext
//
// Die Übersetzung des Zustell-Ergebnisses liegt beim Enum, damit beide
// Sende-Sheets (Ziel-Anstupser und freie Erinnerung) dieselbe Formulierung
// benutzen.

extension NudgeDelivery {
    /// Meldung für den Absender. `isError` steuert die Einfärbung im UI.
    func message(language: AppLanguage, recipientName: String) -> (text: String, isError: Bool) {
        switch self {
        case .delivered, .pending:
            return (L10n.nudgeSent(language), false)
        case .rejected(let reason):
            switch reason {
            case .noTokens, .deliveryFailed:
                return (L10n.nudgeFailedNoDevice(language, name: recipientName), true)
            case .recipientDisabled:
                return (L10n.nudgeFailedDisabled(language, name: recipientName), true)
            case .dailyCapReached:
                return (L10n.nudgeFailedCapReached(language,
                                                   name: recipientName,
                                                   max: AppState.maxNudgesPerDay), true)
            case .notFriend, .invalidSender:
                return (L10n.nudgeFailedNotFriend(language, name: recipientName), true)
            case .unknown:
                return (L10n.nudgeFailed(language), true)
            }
        }
    }
}
