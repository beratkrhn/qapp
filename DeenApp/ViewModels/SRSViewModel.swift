//
//  SRSViewModel.swift
//  DeenApp
//
//  SM-2-basiertes Spaced-Repetition-System für Quran-Vokabeln.
//  Enthält Mock-Daten, die gegen echte Daten ausgetauscht werden können.
//

import Foundation
import Observation

private let kSRSCardsKey = "dailydee.srsCards"

@Observable
final class SRSViewModel {

    // MARK: - Observable State

    private(set) var allCards: [FlashcardCard]
    private(set) var sessionQueue: [FlashcardCard] = []
    private(set) var currentIndex: Int = 0
    private(set) var sessionFinished: Bool = false

    // MARK: - Init

    init() {
        if let data = UserDefaults.standard.data(forKey: kSRSCardsKey),
           let saved = try? JSONDecoder().decode([FlashcardCard].self, from: data) {
            // Merge saved SRS state back onto the canonical mock deck so that
            // new mock words added later are also picked up.
            let savedMap = Dictionary(uniqueKeysWithValues: saved.map { ($0.id, $0) })
            self.allCards = Self.mockCards.map { base in
                savedMap[base.id] ?? base
            }
        } else {
            self.allCards = Self.mockCards
        }
    }

    // MARK: - Computed Progress

    /// Weighted progress: sum(frequency of graduated) / sum(frequency of all) × 100
    var progressPercent: Double {
        let total = allCards.reduce(0) { $0 + $1.frequency }
        guard total > 0 else { return 0 }
        let done = allCards.filter { $0.status == .graduated }.reduce(0) { $0 + $1.frequency }
        return Double(done) / Double(total) * 100.0
    }

    var graduatedCount: Int { allCards.filter { $0.status == .graduated }.count }
    var newCount: Int       { allCards.filter { $0.status == .new }.count }
    var dueCount: Int       { allCards.filter { isDue($0) && $0.status != .new }.count }

    // MARK: - Session Management

    func startSession(type: LearningSessionType) {
        let due = allCards.filter { isDue($0) && $0.status != .new }
        let new = allCards.filter { $0.status == .new }

        let queue: [FlashcardCard]
        switch type {
        case .mixed:      queue = Array((due + new).prefix(20))
        case .newOnly:    queue = Array(new.prefix(20))
        case .reviewOnly: queue = Array(due.prefix(20))
        }

        sessionQueue  = queue.shuffled()
        currentIndex  = 0
        sessionFinished = sessionQueue.isEmpty
    }

    var currentCard: FlashcardCard? {
        guard !sessionQueue.isEmpty, currentIndex < sessionQueue.count else { return nil }
        return sessionQueue[currentIndex]
    }

    func rate(_ rating: SRSRating) {
        guard let card = currentCard,
              let masterIdx = allCards.firstIndex(where: { $0.id == card.id }) else { return }

        var updated = card
        applyAlgorithm(rating: rating, to: &updated)
        allCards[masterIdx] = updated

        persist()

        let next = currentIndex + 1
        if next >= sessionQueue.count {
            sessionFinished = true
        } else {
            currentIndex = next
        }
    }

    func resetSession() {
        sessionQueue  = []
        currentIndex  = 0
        sessionFinished = false
    }

    /// Resets every card to its initial `.new` state and clears persisted SRS data.
    func resetProgress() {
        allCards = Self.mockCards
        UserDefaults.standard.removeObject(forKey: kSRSCardsKey)
        resetSession()
    }

    // MARK: - SM-2 Core Algorithm

    private func applyAlgorithm(rating: SRSRating, to card: inout FlashcardCard) {
        let q = rating.quality

        if q < 3 {
            // Failed — reset streak, keep short re-review interval
            card.repetitions = 0
            card.interval    = (q == 0) ? 1 : 2
            card.status      = .learning
        } else {
            // Passed — standard SM-2 interval progression
            let newInterval: Int
            switch card.repetitions {
            case 0:  newInterval = 1
            case 1:  newInterval = 3
            default: newInterval = max(1, Int((Double(card.interval) * card.easeFactor).rounded()))
            }
            card.interval    = newInterval
            card.repetitions += 1

            // Graduate on Easy or after 3 consecutive correct answers
            card.status = (rating == .easy || card.repetitions >= 3) ? .graduated : .learning
        }

        // SM-2 ease-factor adjustment (clamped to min 1.3)
        let delta = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        card.easeFactor = max(1.3, card.easeFactor + delta)

        card.nextReviewDate = Calendar.current.date(
            byAdding: .day, value: max(1, card.interval), to: Date()
        ) ?? Date()
    }

    // MARK: - Helpers

    private func isDue(_ card: FlashcardCard) -> Bool {
        card.nextReviewDate <= Date()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(allCards) else { return }
        UserDefaults.standard.set(data, forKey: kSRSCardsKey)
    }

    // MARK: - Mock Data (18 häufige Quran-Vokabeln — werden durch echte Daten ersetzt)

    static let mockCards: [FlashcardCard] = [
        FlashcardCard(id: "q001", arabic: "ٱللَّه",      translation: "Allah (Gott)",              frequency: 2699),
        FlashcardCard(id: "q002", arabic: "رَبّ",        translation: "Herr, Erhalter",            frequency: 980),
        FlashcardCard(id: "q003", arabic: "قَالَ",       translation: "Er sagte",                  frequency: 1625),
        FlashcardCard(id: "q004", arabic: "إِنَّ",       translation: "Wahrlich, fürwahr",         frequency: 1710),
        FlashcardCard(id: "q005", arabic: "كَانَ",       translation: "Er war",                    frequency: 1360),
        FlashcardCard(id: "q006", arabic: "مَا",         translation: "Was / nicht",               frequency: 1504),
        FlashcardCard(id: "q007", arabic: "لَا",         translation: "Nein / nicht",              frequency: 1723),
        FlashcardCard(id: "q008", arabic: "مِن",         translation: "Von, aus",                  frequency: 3226),
        FlashcardCard(id: "q009", arabic: "فِى",         translation: "In, bei",                   frequency: 1696),
        FlashcardCard(id: "q010", arabic: "عَلَىٰ",      translation: "Auf, über",                 frequency: 1391),
        FlashcardCard(id: "q011", arabic: "إِلَىٰ",      translation: "Zu, bis",                   frequency: 742),
        FlashcardCard(id: "q012", arabic: "ٱلَّذِى",     translation: "Derjenige, der",            frequency: 983),
        FlashcardCard(id: "q013", arabic: "هُوَ",        translation: "Er (3. Pers. Sg.)",         frequency: 705),
        FlashcardCard(id: "q014", arabic: "نَفْس",       translation: "Seele, Selbst",             frequency: 295),
        FlashcardCard(id: "q015", arabic: "يَوْم",       translation: "Tag",                       frequency: 365),
        FlashcardCard(id: "q016", arabic: "آيَة",        translation: "Zeichen, Vers",             frequency: 382),
        FlashcardCard(id: "q017", arabic: "كِتَٰب",      translation: "Buch, Schrift",             frequency: 230),
        FlashcardCard(id: "q018", arabic: "عَمِلَ",      translation: "Er tat, er handelte",       frequency: 317),
    ]
}
