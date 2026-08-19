//
//  AuthService.swift
//  DeenApp
//
//  Dünner Wrapper um Firebase Auth + Firestore-Userdokument.
//  Stateless aus Sicht der App — der ViewModel ruft Methoden auf und
//  beobachtet den `currentAccount`-Publisher.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

enum AuthError: LocalizedError {
    case invalidUsername
    case usernameTaken
    case weakPassword
    case invalidEmail
    case wrongCredentials
    case notSignedIn
    case recentLoginRequired
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .invalidUsername:   return "Benutzername muss 3–20 Zeichen lang sein (a–z, 0–9, _ oder .) und mit einem Buchstaben beginnen."
        case .usernameTaken:     return "Dieser Benutzername ist bereits vergeben."
        case .weakPassword:      return "Das Passwort muss mindestens 6 Zeichen lang sein."
        case .invalidEmail:      return "Diese E-Mail-Adresse ist ungültig."
        case .wrongCredentials:  return "E-Mail oder Passwort ist falsch."
        case .notSignedIn:       return "Du bist nicht angemeldet."
        case .recentLoginRequired: return "Aus Sicherheitsgründen musst du dich neu anmelden und es danach erneut versuchen."
        case .underlying(let m): return m
        }
    }
}

@MainActor
final class AuthService {
    static let shared = AuthService()

    private let db = Firestore.firestore()
    private var authHandle: AuthStateDidChangeListenerHandle?

    /// Emits the current Firestore-backed account whenever auth state changes.
    /// `nil` means "no user signed in" (guest mode).
    let currentAccountSubject = CurrentValueSubject<UserAccount?, Never>(nil)

    private init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let user {
                    let account = try? await self.loadAccount(uid: user.uid)
                    self.currentAccountSubject.send(account)
                } else {
                    self.currentAccountSubject.send(nil)
                }
            }
        }
    }

    deinit {
        if let authHandle { Auth.auth().removeStateDidChangeListener(authHandle) }
    }

    // MARK: - Public API

    var currentUid: String? { Auth.auth().currentUser?.uid }

    var isSignedIn: Bool { Auth.auth().currentUser != nil }

    func signUp(email: String, password: String, username: String, displayName: String?) async throws -> UserAccount {
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        let lower = trimmedUsername.lowercased()
        guard UsernameRule.isValid(trimmedUsername) else { throw AuthError.invalidUsername }
        guard password.count >= 6 else { throw AuthError.weakPassword }

        try await ensureUsernameFree(lower: lower)

        let result: AuthDataResult
        do {
            result = try await Auth.auth().createUser(withEmail: email, password: password)
        } catch let err as NSError {
            throw mapAuthError(err)
        }
        let uid = result.user.uid

        let account = UserAccount(
            id: uid,
            username: trimmedUsername,
            usernameLower: lower,
            email: email,
            displayName: displayName?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            createdAt: Date()
        )

        try await claimUsernameAndWriteProfile(account: account)
        currentAccountSubject.send(account)
        return account
    }

    func signIn(email: String, password: String) async throws -> UserAccount {
        let result: AuthDataResult
        do {
            result = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch let err as NSError {
            throw mapAuthError(err)
        }
        let account = try await loadAccount(uid: result.user.uid)
        currentAccountSubject.send(account)
        return account
    }

    func signOut() throws {
        try Auth.auth().signOut()
        currentAccountSubject.send(nil)
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch let err as NSError {
            throw mapAuthError(err)
        }
    }

    /// Spiegelt die App-Sprache ins Profil (`users/{uid}.language`) — die
    /// Cloud Function lokalisiert damit die System-Pushes (Anfrage/Annahme).
    func publishLanguage(_ language: AppLanguage) {
        guard let uid = currentUid else { return }
        db.collection("users").document(uid).setData(
            ["language": Self.localeCode(for: language)], merge: true)
    }

    /// Löscht das Konto vollständig: erst alle Firestore-Spuren (Freund-
    /// schaften inkl. Gegenseite, Anfragen, eigene Subcollections, Username),
    /// dann den Auth-Nutzer. Reihenfolge ist wichtig — nach dem Auth-Delete
    /// verweigern die Security-Rules jeden weiteren Zugriff.
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { throw AuthError.notSignedIn }

        // Firebase verlangt für `user.delete()` einen frischen Login (~5 min).
        // Vorab prüfen, damit nicht erst die Firestore-Daten gelöscht werden
        // und der Auth-Delete anschließend scheitert (halb gelöschtes Konto).
        if let lastSignIn = user.metadata.lastSignInDate,
           Date().timeIntervalSince(lastSignIn) > 4 * 60 {
            throw AuthError.recentLoginRequired
        }

        let uid = user.uid
        let account = try? await loadAccount(uid: uid)
        let userRef = db.collection("users").document(uid)

        // Beziehungen zu anderen Nutzern kappen (deren Dokumente zuerst).
        let friends = try await userRef.collection("friends").getDocuments()
        for doc in friends.documents {
            try? await db.collection("users").document(doc.documentID)
                .collection("friends").document(uid).delete()
        }
        let incoming = try await userRef.collection("incomingRequests").getDocuments()
        for doc in incoming.documents {
            try? await db.collection("users").document(doc.documentID)
                .collection("outgoingRequests").document(uid).delete()
        }
        let outgoing = try await userRef.collection("outgoingRequests").getDocuments()
        for doc in outgoing.documents {
            try? await db.collection("users").document(doc.documentID)
                .collection("incomingRequests").document(uid).delete()
        }

        // Eigene Subcollections leeren — Firestore löscht sie nicht mit dem
        // Elterndokument.
        let subcollections = [
            "friends", "incomingRequests", "outgoingRequests",
            "goals", "nudges", "fcmTokens",
            "notificationPreferences", "dailyNudgeCounts"
        ]
        for name in subcollections {
            let docs = try await userRef.collection(name).getDocuments()
            for doc in docs.documents {
                try? await doc.reference.delete()
            }
        }

        if let account {
            try? await db.collection("usernames").document(account.usernameLower).delete()
        }
        try await userRef.delete()

        do {
            try await user.delete()
        } catch let err as NSError {
            if err.domain == AuthErrorDomain,
               AuthErrorCode(rawValue: err.code) == .requiresRecentLogin {
                throw AuthError.recentLoginRequired
            }
            throw mapAuthError(err)
        }
        currentAccountSubject.send(nil)
    }

    // MARK: - Internals

    private func ensureUsernameFree(lower: String) async throws {
        let snapshot = try await db.collection("usernames").document(lower).getDocument()
        if snapshot.exists { throw AuthError.usernameTaken }
    }

    private func claimUsernameAndWriteProfile(account: UserAccount) async throws {
        let usernamesRef = db.collection("usernames").document(account.usernameLower)
        let usersRef = db.collection("users").document(account.id)

        let batch = db.batch()
        batch.setData(["uid": account.id], forDocument: usernamesRef)
        batch.setData([
            "username": account.username,
            "usernameLower": account.usernameLower,
            "email": account.email,
            "displayName": account.displayName as Any,
            "createdAt": Timestamp(date: account.createdAt)
        ], forDocument: usersRef)
        try await batch.commit()
    }

    func loadAccount(uid: String) async throws -> UserAccount {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard let data = doc.data() else { throw AuthError.notSignedIn }
        let username = data["username"] as? String ?? ""
        let lower = data["usernameLower"] as? String ?? username.lowercased()
        let email = data["email"] as? String ?? ""
        let displayName = data["displayName"] as? String
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        return UserAccount(
            id: uid,
            username: username,
            usernameLower: lower,
            email: email,
            displayName: displayName,
            createdAt: createdAt
        )
    }

    private static func localeCode(for language: AppLanguage) -> String {
        switch language {
        case .english:                              return "en"
        case .turkish:                              return "tr"
        case .german, .germanArabic, .germanTurkish: return "de"
        }
    }

    private func mapAuthError(_ err: NSError) -> AuthError {
        guard err.domain == AuthErrorDomain else { return .underlying(err.localizedDescription) }
        switch AuthErrorCode(rawValue: err.code) {
        case .weakPassword:                 return .weakPassword
        case .invalidEmail:                 return .invalidEmail
        case .emailAlreadyInUse:            return .underlying("Diese E-Mail-Adresse ist bereits registriert.")
        case .wrongPassword,
             .userNotFound,
             .invalidCredential:            return .wrongCredentials
        default:                            return .underlying(err.localizedDescription)
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
