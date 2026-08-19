//
//  SRSViewModel.swift
//  DeenApp
//
//  Anki-faithful SRS (SM-2 variant with learning/relearning steps).
//

import Foundation
import Observation
import os

private let logger = Logger(subsystem: "d.DailyDee", category: "SRS")

private let kSRSCardsKey = "dailydee.srsCards"

// MARK: - Anki defaults (matches Anki's stock deck options)

private enum AnkiConfig {
    static let learningStepsMinutes: [Int]   = [1, 10]
    static let relearningStepsMinutes: [Int] = [10]
    static let graduatingIntervalDays: Int   = 1
    static let easyIntervalDays: Int         = 4
    static let initialEase: Double           = 2.5
    static let minEase: Double               = 1.3
    static let easyBonus: Double             = 1.3
    static let hardIntervalMultiplier: Double = 1.2
    static let intervalModifier: Double      = 1.0
    static let newIntervalAfterLapse: Double = 0.0
    static let maxIntervalDays: Int          = 36500
}

struct SRSPreview {
    let dueDate: Date
    let label: String
}

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
                logger.error("QWords: Datei nicht im Bundle (forResource: QWords, json).")
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
                logger.error("QWords: Laden/Dekodieren fehlgeschlagen: \(String(describing: error))")
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

    /// Preview the next due date for a rating without persisting.
    func previewNextReviewDate(for card: FlashcardCard, rating: SRSRating) -> Date {
        var copy = card
        applyAlgorithm(rating: rating, to: &copy)
        return copy.nextReviewDate
    }

    /// Preview an Anki-style interval label (e.g. "1m", "10m", "1d", "6d", "1.4mo").
    func previewLabel(for card: FlashcardCard, rating: SRSRating) -> String {
        let now = Date()
        let due = previewNextReviewDate(for: card, rating: rating)
        return Self.intervalLabel(from: now, to: due)
    }

    static func intervalLabel(from start: Date, to end: Date) -> String {
        let seconds = max(0, end.timeIntervalSince(start))
        let minutes = Int((seconds / 60.0).rounded())
        if minutes < 60 {
            return "\(max(1, minutes))m"
        }
        let days = Int((seconds / 86_400.0).rounded())
        if days < 1 {
            let hours = Int((seconds / 3600.0).rounded())
            return "\(hours)h"
        }
        if days < 30 {
            return "\(days)d"
        }
        if days < 365 {
            let months = Double(days) / 30.0
            return String(format: "%.1fmo", months)
        }
        let years = Double(days) / 365.0
        return String(format: "%.1fy", years)
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

    func goToPreviousCard() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        sessionFinished = false
    }

    var canGoBack: Bool { currentIndex > 0 }

    /// Resets every card to its initial `.new` state and clears persisted SRS data.
    func resetProgress() {
        allCards = Self.loadVocabularyFromJSON()
        UserDefaults.standard.removeObject(forKey: kSRSCardsKey)
        resetSession()
    }

    // MARK: - Anki Algorithm

    /// Anki SM-2 variant: learning steps for new cards, ease-modified review intervals
    /// for graduated cards, relearning steps after a lapse. Mutates the card in place.
    private func applyAlgorithm(rating: SRSRating, to card: inout FlashcardCard) {
        let now = Date()

        switch card.status {
        case .new, .learning:
            applyLearning(rating: rating, to: &card, now: now)
        case .relearning:
            applyRelearning(rating: rating, to: &card, now: now)
        case .graduated:
            applyReview(rating: rating, to: &card, now: now)
        }
    }

    private func applyLearning(rating: SRSRating, to card: inout FlashcardCard, now: Date) {
        let steps = AnkiConfig.learningStepsMinutes
        let currentStep = max(0, min(card.learningStep, steps.count - 1))

        switch rating {
        case .again:
            card.learningStep = 0
            card.status = .learning
            scheduleMinutes(steps[0], on: &card, now: now)

        case .hard:
            card.learningStep = currentStep
            card.status = .learning
            scheduleMinutes(steps[currentStep], on: &card, now: now)

        case .good:
            let nextStep = currentStep + 1
            if nextStep >= steps.count {
                graduate(to: &card, intervalDays: AnkiConfig.graduatingIntervalDays, now: now)
            } else {
                card.learningStep = nextStep
                card.status = .learning
                scheduleMinutes(steps[nextStep], on: &card, now: now)
            }

        case .easy:
            graduate(to: &card, intervalDays: AnkiConfig.easyIntervalDays, now: now)
        }
    }

    private func applyRelearning(rating: SRSRating, to card: inout FlashcardCard, now: Date) {
        let steps = AnkiConfig.relearningStepsMinutes
        let currentStep = max(0, min(card.learningStep, steps.count - 1))

        switch rating {
        case .again:
            card.learningStep = 0
            card.status = .relearning
            scheduleMinutes(steps[0], on: &card, now: now)

        case .hard:
            card.learningStep = currentStep
            card.status = .relearning
            scheduleMinutes(steps[currentStep], on: &card, now: now)

        case .good:
            let nextStep = currentStep + 1
            if nextStep >= steps.count {
                let resumeInterval = max(1, card.interval)
                graduate(to: &card, intervalDays: resumeInterval, now: now)
            } else {
                card.learningStep = nextStep
                card.status = .relearning
                scheduleMinutes(steps[nextStep], on: &card, now: now)
            }

        case .easy:
            let resumeInterval = max(1, card.interval) + 1
            graduate(to: &card, intervalDays: resumeInterval, now: now)
        }
    }

    private func applyReview(rating: SRSRating, to card: inout FlashcardCard, now: Date) {
        let prevInterval = max(1, card.interval)
        var ef = card.easeFactor

        switch rating {
        case .again:
            ef = max(AnkiConfig.minEase, ef - 0.20)
            let postLapseInterval = max(1, Int((Double(prevInterval) * AnkiConfig.newIntervalAfterLapse).rounded()))
            card.easeFactor = ef
            card.interval = min(postLapseInterval, AnkiConfig.maxIntervalDays)
            card.status = .relearning
            card.learningStep = 0
            scheduleMinutes(AnkiConfig.relearningStepsMinutes[0], on: &card, now: now)

        case .hard:
            ef = max(AnkiConfig.minEase, ef - 0.15)
            let raw = Double(prevInterval) * AnkiConfig.hardIntervalMultiplier * AnkiConfig.intervalModifier
            let next = max(prevInterval + 1, Int(raw.rounded()))
            card.easeFactor = ef
            card.interval = min(next, AnkiConfig.maxIntervalDays)
            card.status = .graduated
            card.repetitions += 1
            scheduleDays(card.interval, on: &card, now: now)

        case .good:
            let raw = Double(prevInterval) * ef * AnkiConfig.intervalModifier
            let next = max(prevInterval + 1, Int(raw.rounded()))
            card.interval = min(next, AnkiConfig.maxIntervalDays)
            card.status = .graduated
            card.repetitions += 1
            scheduleDays(card.interval, on: &card, now: now)

        case .easy:
            ef = ef + 0.15
            let raw = Double(prevInterval) * ef * AnkiConfig.easyBonus * AnkiConfig.intervalModifier
            // Easy must beat Good's interval by at least one day (Anki guarantee).
            let goodFloor = max(prevInterval + 1, Int((Double(prevInterval) * card.easeFactor * AnkiConfig.intervalModifier).rounded()))
            let next = max(goodFloor + 1, Int(raw.rounded()))
            card.easeFactor = ef
            card.interval = min(next, AnkiConfig.maxIntervalDays)
            card.status = .graduated
            card.repetitions += 1
            scheduleDays(card.interval, on: &card, now: now)
        }
    }

    private func graduate(to card: inout FlashcardCard, intervalDays: Int, now: Date) {
        card.status = .graduated
        card.learningStep = 0
        card.repetitions += 1
        card.interval = min(max(1, intervalDays), AnkiConfig.maxIntervalDays)
        scheduleDays(card.interval, on: &card, now: now)
    }

    private func scheduleMinutes(_ minutes: Int, on card: inout FlashcardCard, now: Date) {
        card.nextReviewDate = Calendar.current.date(byAdding: .minute, value: max(1, minutes), to: now) ?? now
    }

    private func scheduleDays(_ days: Int, on card: inout FlashcardCard, now: Date) {
        card.nextReviewDate = Calendar.current.date(byAdding: .day, value: max(1, days), to: now) ?? now
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
