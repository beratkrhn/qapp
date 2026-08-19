//
//  HifzTrackerViewModel.swift
//  DeenApp
//
//  Source-of-Truth für die Hifz-Tracker-Einträge des Nutzers. Persistiert in
//  UserDefaults (rein lokal — kein Firestore-Sync) und plant beim Mutieren
//  die 3-Tage-Wiederholungserinnerungen über `HifzNotificationScheduler` neu.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class HifzTrackerViewModel: ObservableObject {

    @Published private(set) var entries: [HifzEntry] = []

    private static let storageKey = "dailydee.hifzEntries_v1"
    private let scheduler = HifzNotificationScheduler.shared
    private var ticker: AnyCancellable?

    /// Sprache wird beim ersten View-Anzeigen aus `AppState` injiziert, damit
    /// Notifications in der richtigen Sprache geplant werden.
    var language: AppLanguage = .german {
        didSet {
            guard oldValue != language else { return }
            scheduler.rescheduleAll(entries, language: language)
        }
    }

    /// Wird jede Minute aktualisiert, damit die "vor X Stunden / Tagen"-Anzeige
    /// nicht stehen bleibt.
    @Published private(set) var tick: Date = Date()

    init() {
        loadFromCache()
        ticker = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in self?.tick = now }
    }

    // MARK: - CRUD

    func add(_ entry: HifzEntry) {
        entries.append(entry)
        sortEntries()
        persistCache()
        Task {
            _ = await scheduler.requestPermissionIfNeeded()
            scheduler.rescheduleAll(entries, language: language)
        }
    }

    func delete(_ entry: HifzEntry) {
        entries.removeAll { $0.id == entry.id }
        persistCache()
        if entries.isEmpty {
            scheduler.cancelAll()
        } else {
            scheduler.rescheduleAll(entries, language: language)
        }
    }

    func markRevised(_ entry: HifzEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx].lastRevisedAt = Date()
        sortEntries()
        persistCache()
        scheduler.rescheduleAll(entries, language: language)
    }

    // MARK: - Sorting

    /// Überfällige zuerst, danach die mit dem ältesten `lastRevisedAt`.
    private func sortEntries() {
        entries.sort { lhs, rhs in
            lhs.lastRevisedAt < rhs.lastRevisedAt
        }
    }

    // MARK: - Persistence

    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder.hifzDecoder.decode([HifzEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded
        sortEntries()
    }

    private func persistCache() {
        guard let data = try? JSONEncoder.hifzEncoder.encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

private extension JSONEncoder {
    static let hifzEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

private extension JSONDecoder {
    static let hifzDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
