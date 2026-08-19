//
//  GoalsViewModel.swift
//  DeenApp
//
//  Source-of-truth für die Ziele des Nutzers. Bei angemeldetem Account ist
//  Firestore die Wahrheit (per-uid Snapshot-Listener); der lokale Cache in
//  UserDefaults ist nur für Offline-Starts und ist pro-uid gescoped. Damit
//  bleiben mehrere Accounts auf demselben Gerät sauber getrennt.
//

import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

@MainActor
final class GoalsViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var goals: [Goal] = []

    // MARK: - Internal

    private static let cachePrefix = "dailydee.goals_v1"
    private static let anonymousCacheSuffix = "local"
    private var accountSub: AnyCancellable?
    private var currentUid: String?
    private var liveListener: ListenerRegistration?

    /// Ziele mit lokalen Änderungen, die noch nicht in die Cloud geschrieben
    /// wurden (Debounce für hochfrequente Mutationen wie Seitenblättern).
    private var pendingCloudGoalIds: Set<String> = []
    private var cloudFlushTask: Task<Void, Never>?
    private static let cloudFlushDelay: Duration = .seconds(2)

    // MARK: - Init

    init() {
        // Initialer Snapshot aus dem Auth-Layer (kann sofort nil oder gesetzt sein).
        let initialUid = AuthService.shared.currentUid
        currentUid = initialUid
        loadFromCache(uid: initialUid)
        if let uid = initialUid {
            attachListener(uid: uid)
        }
        // Beobachte Auth-Wechsel, um Account-isolierte Ziele zu laden / cloud zu
        // synchronisieren.
        accountSub = AuthService.shared.currentAccountSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] account in
                self?.handleAccountChange(newUid: account?.id)
            }
    }

    deinit {
        liveListener?.remove()
    }

    // MARK: - CRUD

    func add(_ goal: Goal) {
        goals.append(goal)
        persistCache()
        publishToCloud(goal)
    }

    func update(_ goal: Goal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[idx] = goal
        persistCache()
        publishToCloud(goal)
    }

    func delete(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        persistCache()
        removeFromCloud(goalId: goal.id)
    }

    func setActive(_ goal: Goal, active: Bool) {
        var copy = goal
        copy.isActive = active
        update(copy)
    }

    func setVisibleToFriends(_ goal: Goal, visible: Bool) {
        var copy = goal
        copy.visibleToFriends = visible
        update(copy)
    }

    // MARK: - Progress mutators

    /// Wird bei jedem Mushaf-Seitenwechsel aufgerufen. Erhöht das Tageslog
    /// aller aktiven `.khatmByDate`- und `.dailyQuranPages`-Ziele.
    func recordPageRead() {
        let key = GoalDateKey.today
        var changed = false
        for i in goals.indices where goals[i].isActive {
            let t = goals[i].type
            guard t == .khatmByDate || t == .dailyQuranPages else { continue }
            goals[i].pagesPerDay[key, default: 0] += 1
            changed = true
            publishToCloudDebounced(goals[i])
        }
        if changed { persistCache() }
    }

    /// Schaltet ein Pflichtgebet für heute an/aus.
    func togglePrayer(_ prayer: FardPrayer, on goal: Goal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        let key = GoalDateKey.today
        var current = Set(goals[idx].prayersPerDay[key] ?? [])
        if current.contains(prayer.rawValue) {
            current.remove(prayer.rawValue)
        } else {
            current.insert(prayer.rawValue)
        }
        goals[idx].prayersPerDay[key] = Array(current).sorted()
        persistCache()
        publishToCloud(goals[idx])
    }

    /// Loggt das Sunnah-Gebet einmal für heute (Duplikate pro Tag werden gefiltert).
    func logSunnah(on goal: Goal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        let key = GoalDateKey.today
        if !goals[idx].sunnahDates.contains(key) {
            goals[idx].sunnahDates.append(key)
            persistCache()
            publishToCloud(goals[idx])
        }
    }

    /// Manuelle Korrektur des heutigen Seiten-Logs für ein Khatm- oder
    /// Tagesseiten-Ziel. `delta` kann negativ sein; das Ergebnis wird auf 0
    /// geclampt.
    func adjustPagesToday(on goal: Goal, by delta: Int) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        let t = goals[idx].type
        guard t == .khatmByDate || t == .dailyQuranPages else { return }
        let key = GoalDateKey.today
        let current = goals[idx].pagesPerDay[key] ?? 0
        let next = max(0, current + delta)
        goals[idx].pagesPerDay[key] = next
        persistCache()
        publishToCloud(goals[idx])
    }

    /// Schreibt das Khatma-Lesezeichen für alle aktiven Khatm-Ziele auf
    /// die aktuelle Mushaf-Seite.
    func updateKhatmaBookmark(page: Int) {
        var changed = false
        for i in goals.indices where goals[i].isActive && goals[i].type == .khatmByDate {
            guard goals[i].khatmBookmarkPage != page else { continue }
            goals[i].khatmBookmarkPage = page
            changed = true
            publishToCloudDebounced(goals[i])
        }
        if changed { persistCache() }
    }

    /// Entfernt den heutigen Sunnah-Eintrag wieder (Undo).
    func unlogSunnah(on goal: Goal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        let key = GoalDateKey.today
        goals[idx].sunnahDates.removeAll { $0 == key }
        persistCache()
        publishToCloud(goals[idx])
    }

    var activeGoals: [Goal] {
        goals.filter(\.isActive)
    }

    // MARK: - Account switching

    private func handleAccountChange(newUid: String?) {
        guard newUid != currentUid else { return }

        // Letzten Stand für den bisherigen Scope sichern, dann Listener trennen.
        persistCache()
        flushPendingCloudWrites()
        liveListener?.remove()
        liveListener = nil

        currentUid = newUid
        // Schnell aus dem (per-uid) Cache rendern; der Listener überschreibt
        // anschließend mit dem Cloud-Stand.
        loadFromCache(uid: newUid)

        if let uid = newUid {
            attachListener(uid: uid)
        }
    }

    private func attachListener(uid: String) {
        liveListener = GoalsService.shared.observeOwnGoals(uid: uid) { [weak self] cloudGoals in
            guard let self else { return }
            // Nur übernehmen, wenn der Auth-Status sich seit Listener-Anhängen
            // nicht geändert hat (Race nach schnellem Account-Wechsel).
            guard self.currentUid == uid else { return }
            // Ziele mit noch nicht geflushten lokalen Änderungen behalten —
            // sonst würde ein (älterer) Server-Snapshot sie zurückdrehen.
            self.goals = cloudGoals
                .map { cloud in
                    if self.pendingCloudGoalIds.contains(cloud.id),
                       let local = self.goals.first(where: { $0.id == cloud.id }) {
                        return local
                    }
                    return cloud
                }
                .sorted { $0.createdAt < $1.createdAt }
            self.persistCache()
        }
    }

    // MARK: - Cache (per uid)

    private static func cacheKey(for uid: String?) -> String {
        "\(cachePrefix).\(uid ?? anonymousCacheSuffix)"
    }

    private func loadFromCache(uid: String?) {
        let key = Self.cacheKey(for: uid)
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder.goalDecoder.decode([Goal].self, from: data) else {
            goals = []
            return
        }
        goals = decoded
    }

    private func persistCache() {
        let key = Self.cacheKey(for: currentUid)
        if let data = try? JSONEncoder.goalEncoder.encode(goals) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Cloud writes

    private func publishToCloud(_ goal: Goal) {
        guard let uid = currentUid else { return }
        pendingCloudGoalIds.remove(goal.id)
        Task { try? await GoalsService.shared.publish(goal: goal, uid: uid) }
    }

    /// Debounced-Variante für hochfrequente Mutationen (Seitenblättern,
    /// Khatma-Lesezeichen): sammelt Ziel-IDs und schreibt gebündelt nach
    /// `cloudFlushDelay` — statt einem Firestore-Write pro Swipe.
    private func publishToCloudDebounced(_ goal: Goal) {
        guard currentUid != nil else { return }
        pendingCloudGoalIds.insert(goal.id)
        cloudFlushTask?.cancel()
        cloudFlushTask = Task { [weak self] in
            try? await Task.sleep(for: Self.cloudFlushDelay)
            guard !Task.isCancelled else { return }
            self?.flushPendingCloudWrites()
        }
    }

    /// Schreibt alle ausstehenden Ziel-Änderungen sofort in die Cloud.
    private func flushPendingCloudWrites() {
        cloudFlushTask?.cancel()
        cloudFlushTask = nil
        guard let uid = currentUid, !pendingCloudGoalIds.isEmpty else {
            pendingCloudGoalIds.removeAll()
            return
        }
        let toFlush = goals.filter { pendingCloudGoalIds.contains($0.id) }
        pendingCloudGoalIds.removeAll()
        Task {
            for goal in toFlush {
                try? await GoalsService.shared.publish(goal: goal, uid: uid)
            }
        }
    }

    private func removeFromCloud(goalId: String) {
        pendingCloudGoalIds.remove(goalId)
        guard let uid = currentUid else { return }
        Task { try? await GoalsService.shared.unpublish(goalId: goalId, uid: uid) }
    }
}

// MARK: - JSON Coders

private extension JSONEncoder {
    static let goalEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

private extension JSONDecoder {
    static let goalDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
