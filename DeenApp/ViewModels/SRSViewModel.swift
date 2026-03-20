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
            let realCards = Self.loadVocabularyFromJSON()
            
            if let data = UserDefaults.standard.data(forKey: kSRSCardsKey),
               let saved = try? JSONDecoder().decode([FlashcardCard].self, from: data) {
                
                // Merge gespeicherte Lern-Fortschritte mit den ECHTEN JSON-Daten
                let savedMap = Dictionary(uniqueKeysWithValues: saved.map { ($0.id, $0) })
                self.allCards = realCards.map { base in
                    savedMap[base.id] ?? base
                }
            } else {
                self.allCards = realCards
            }
        }
    
    private static func loadVocabularyFromJSON() -> [FlashcardCard] {
            guard let url = qwordsBundleURL() else {
                print("QWords: Datei nicht im Bundle (forResource: QWords, json).")
                return []
            }
            do {
                let data = try Data(contentsOf: url)
                let quranWords = try JSONDecoder().decode([QuranWord].self, from: data)
                return quranWords.map { word in
                    FlashcardCard(
                        id: "q_\(word.id)",
                        arabic: word.arabic,
                        meaningEN: word.meaningEN,
                        frequency: word.frequency
                    )
                }
            } catch {
                print("QWords: Laden/Dekodieren fehlgeschlagen: \(error)")
                return []
            }
        }

    private static func qwordsBundleURL() -> URL? {
        Bundle.main.qwordsJSONURL()
    }

    // MARK: - Computed Progress

    var graduatedCount: Int { allCards.filter { $0.status == .graduated }.count }

    /// Alle Karten mit Status **graduated** (für Exporte, Statistik).
    var graduatedCards: [FlashcardCard] {
        allCards.filter { $0.status == .graduated }
    }

    /// Summe der `frequency`-Werte aller **graduated** Karten.
    var graduatedFrequencySum: Int {
        allCards.filter { $0.status == .graduated }.reduce(0) { $0 + $1.frequency }
    }

    var deckCardCount: Int { allCards.count }

    /// Summe der Vorkommen aller **gelernten** Karten vs. geschätzte Quran-Gesamtwortzahl (~77.800).
    var quranProgressPercent: Double {
        (Double(graduatedFrequencySum) / Double(QuranVocabularyProgress.approximateQuranWordCount)) * 100.0
    }

    /// Summe der `frequency`-Werte des geladenen Decks (z. B. QWords ≈ 64.282).
    var deckTotalFrequency: Int {
        allCards.reduce(0) { $0 + $1.frequency }
    }

    /// Deck-Fortschritt nach **Vorkommen**: gelernte Vorkommen / Summe aller Deck-Vorkommen (0…100).
    var deckProgressPercentByFrequency: Double {
        let total = deckTotalFrequency
        guard total > 0 else { return 0 }
        return Double(graduatedFrequencySum) / Double(total) * 100.0
    }

    /// Deck-Fortschritt nach **Kartenanzahl**: gelernte Karten / Deck-Größe (0…100).
    var deckProgressPercentByCards: Double {
        guard !allCards.isEmpty else { return 0 }
        return Double(graduatedCount) / Double(allCards.count) * 100.0
    }

    var newCount: Int       { allCards.filter { $0.status == .new }.count }
    var dueCount: Int       { allCards.filter { isDue($0) && $0.status != .new }.count }
    var reviewableLearnedCount: Int { graduatedCards.count }

    // MARK: - Session Management

    func startSession(type: LearningSessionType) {
        let due = allCards.filter { isDue($0) && $0.status != .new }
        let new = allCards.filter { $0.status == .new }

        let queue: [FlashcardCard]
        switch type {
        case .mixed:      queue = Array((due + new).prefix(20))
        case .newOnly:    queue = Array(new.prefix(20))
        case .reviewOnly: queue = graduatedCards
        }

        sessionQueue  = queue.shuffled()
        currentIndex  = 0
        sessionFinished = sessionQueue.isEmpty
    }

    var currentCard: FlashcardCard? {
        guard !sessionQueue.isEmpty, currentIndex < sessionQueue.count else { return nil }
        return sessionQueue[currentIndex]
    }

    /// Vorschau: Datum der nächsten Wiederholung, **ohne** die Karte zu speichern (gleiche Logik wie `applyAlgorithm`).
    func previewNextReviewDate(for card: FlashcardCard, rating: SRSRating) -> Date {
        var copy = card
        applyAlgorithm(rating: rating, to: &copy)
        return copy.nextReviewDate
    }

    /// Vorschau: Intervall in Tagen nach Bewertung (SM-2).
    func previewIntervalDays(for card: FlashcardCard, rating: SRSRating) -> Int {
        var copy = card
        applyAlgorithm(rating: rating, to: &copy)
        return copy.interval
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
        allCards = Self.loadVocabularyFromJSON()
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
}
