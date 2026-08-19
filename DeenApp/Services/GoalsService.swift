//
//  GoalsService.swift
//  DeenApp
//
//  Firestore-Spiegel für persönliche Ziele. Ziele eines angemeldeten Nutzers
//  werden vollständig in Firestore gespeichert (per uid getrennt) — das macht
//  sie Account-gebunden und geräteübergreifend verfügbar. Das Flag
//  `visibleToFriends` steuert nur, was Freunde sehen dürfen (Filter beim
//  Friend-Listener).
//
//  Datenmodell:
//  users/{uid}/goals/{goalId} → flaches Goal-Document.
//

import Foundation
import FirebaseFirestore

@MainActor
final class GoalsService {

    static let shared = GoalsService()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Mirror (own goals)

    /// Schreibt ein Ziel des angemeldeten Nutzers (Upsert).
    func publish(goal: Goal, uid: String) async throws {
        let ref = db.collection("users").document(uid).collection("goals").document(goal.id)
        try await ref.setData(Self.encode(goal: goal))
    }

    /// Entfernt ein Ziel komplett aus der Cloud.
    func unpublish(goalId: String, uid: String) async throws {
        try await db.collection("users").document(uid).collection("goals").document(goalId).delete()
    }

    // MARK: - Observe own goals

    /// Live-Listener für *alle* Ziele des angemeldeten Nutzers. Liefert auch
    /// nicht-sichtbare/inaktive Ziele zurück — die Filterung passiert im
    /// ViewModel/UI.
    func observeOwnGoals(uid: String, onChange: @escaping ([Goal]) -> Void) -> ListenerRegistration {
        db.collection("users").document(uid).collection("goals")
            .addSnapshotListener { snap, _ in
                let goals: [Goal] = snap?.documents.compactMap {
                    Self.decode(data: $0.data(), id: $0.documentID)
                } ?? []
                onChange(goals)
            }
    }

    // MARK: - Observe friend goals

    /// Live-Listener für die Ziele eines Freundes. Die Filter sind
    /// server-seitig (Firestore-Query + Rules), damit privat markierte Ziele
    /// nie ausgeliefert werden.
    func observeFriendGoals(friendUid: String, onChange: @escaping ([Goal]) -> Void) -> ListenerRegistration {
        db.collection("users").document(friendUid).collection("goals")
            .whereField("visibleToFriends", isEqualTo: true)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { snap, _ in
                let goals: [Goal] = snap?.documents.compactMap {
                    Self.decode(data: $0.data(), id: $0.documentID)
                } ?? []
                onChange(goals)
            }
    }

    // MARK: - Codec

    /// Manuelles Encoding nach `[String: Any]` damit Firestore-Timestamps
    /// genutzt werden können (saubere Suche/Indizes statt Strings).
    static func encode(goal: Goal) -> [String: Any] {
        var dict: [String: Any] = [
            "id":               goal.id,
            "type":             goal.type.rawValue,
            "createdAt":        Timestamp(date: goal.createdAt),
            "isActive":         goal.isActive,
            "visibleToFriends": goal.visibleToFriends,
            "pagesPerDay":      goal.pagesPerDay,
            "prayersPerDay":    goal.prayersPerDay,
            "sunnahDates":      goal.sunnahDates
        ]
        if let v = goal.khatmTargetDate    { dict["khatmTargetDate"] = Timestamp(date: v) }
        if let v = goal.dailyPagesTarget   { dict["dailyPagesTarget"] = v }
        if let v = goal.sunnahKind         { dict["sunnahKind"] = v.rawValue }
        if let v = goal.sunnahWeeklyTarget { dict["sunnahWeeklyTarget"] = v }
        if let v = goal.khatmBookmarkPage  { dict["khatmBookmarkPage"] = v }
        return dict
    }

    static func decode(data: [String: Any], id: String) -> Goal? {
        guard let typeRaw = data["type"] as? String,
              let type = GoalType(rawValue: typeRaw)
        else { return nil }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let isActive = data["isActive"] as? Bool ?? true
        let visibleToFriends = data["visibleToFriends"] as? Bool ?? false

        return Goal(
            id: id,
            type: type,
            createdAt: createdAt,
            isActive: isActive,
            visibleToFriends: visibleToFriends,
            khatmTargetDate: (data["khatmTargetDate"] as? Timestamp)?.dateValue(),
            dailyPagesTarget: data["dailyPagesTarget"] as? Int,
            sunnahKind: (data["sunnahKind"] as? String).flatMap(SunnahPrayerKind.init(rawValue:)),
            sunnahWeeklyTarget: data["sunnahWeeklyTarget"] as? Int,
            khatmBookmarkPage: data["khatmBookmarkPage"] as? Int,
            pagesPerDay: data["pagesPerDay"] as? [String: Int] ?? [:],
            prayersPerDay: data["prayersPerDay"] as? [String: [String]] ?? [:],
            sunnahDates: data["sunnahDates"] as? [String] ?? []
        )
    }
}
