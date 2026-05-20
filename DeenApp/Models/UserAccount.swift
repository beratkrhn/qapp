//
//  UserAccount.swift
//  DeenApp
//
//  Modelle für das Konto- & Freunde-System (Firebase Auth + Firestore).
//

import Foundation

/// Public-facing user profile. Lives in Firestore at `users/{uid}`.
struct UserAccount: Identifiable, Hashable, Codable {
    /// Firebase Auth uid.
    let id: String
    /// Public handle the user picked on signup. Display version (case preserved).
    let username: String
    /// Lowercased handle used for unique lookup. Always equals `username.lowercased()`.
    let usernameLower: String
    /// Email used for Firebase Auth login.
    let email: String
    /// Optional display name (defaults to username when missing).
    let displayName: String?
    let createdAt: Date

    var visibleName: String {
        if let dn = displayName, !dn.isEmpty { return dn }
        return username
    }
}

/// A user in the signed-in user's friend list. Subcollection `users/{uid}/friends/{friendUid}`.
struct FriendInfo: Identifiable, Hashable, Codable {
    /// The friend's uid.
    let id: String
    let username: String
    let displayName: String?
    let since: Date

    var visibleName: String {
        if let dn = displayName, !dn.isEmpty { return dn }
        return username
    }
}

/// An incoming or outgoing friend request.
struct FriendRequest: Identifiable, Hashable, Codable {
    enum Direction: String, Codable { case incoming, outgoing }

    /// The *other* user's uid (the requester for incoming, the recipient for outgoing).
    let id: String
    let username: String
    let displayName: String?
    let sentAt: Date
    let direction: Direction

    var visibleName: String {
        if let dn = displayName, !dn.isEmpty { return dn }
        return username
    }
}

/// Username validation. Public so views can surface live feedback.
enum UsernameRule {
    static let minLength = 3
    static let maxLength = 20
    /// Lowercase letters, digits, underscore, dot. Must start with a letter.
    static let pattern = #"^[a-z][a-z0-9_.]{2,19}$"#

    static func isValid(_ raw: String) -> Bool {
        let lower = raw.lowercased()
        return lower.range(of: pattern, options: .regularExpression) != nil
    }
}
