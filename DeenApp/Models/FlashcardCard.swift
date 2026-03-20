//
//  FlashcardCard.swift
//  DeenApp
//
//  SRS-Karteikarte (SM-2-Algorithmus). Jedes Wort trägt seinen eigenen Lernzustand.
//

import Foundation

// MARK: - Learning Status

enum CardStatus: String, Codable, CaseIterable {
    case new       = "new"
    case learning  = "learning"
    case graduated = "graduated"
}

// MARK: - SRS Rating (4-Button SM-2)

enum SRSRating: CaseIterable, Hashable {
    case again  // Schwer   — q = 0
    case hard   // Schlecht — q = 2
    case good   // Gut      — q = 3
    case easy   // Leicht   — q = 5

    var quality: Int {
        switch self {
        case .again: return 0
        case .hard:  return 2
        case .good:  return 3
        case .easy:  return 5
        }
    }

    var label: String {
        switch self {
        case .again: return "Schwer"
        case .hard:  return "Schlecht"
        case .good:  return "Gut"
        case .easy:  return "Leicht"
        }
    }
}

// MARK: - Flashcard Model

struct FlashcardCard: Identifiable, Codable {
    let id: String
    let arabic: String
    let meaningEN: String
    let frequency: Int          // Occurrences in the Quran

    // MARK: SRS state (mutable — persisted via UserDefaults in SRSViewModel)
    var status: CardStatus  = .new
    var interval: Int       = 0     // Days until next review
    var easeFactor: Double  = 2.5   // SM-2 EF (min 1.3)
    var repetitions: Int    = 0     // Consecutive correct answers
    var nextReviewDate: Date = .distantPast

    private enum CodingKeys: String, CodingKey {
        case id, arabic, meaningEN, frequency
        case status, interval, easeFactor, repetitions, nextReviewDate
        case legacyTranslation = "translation"
    }

    init(id: String, arabic: String, meaningEN: String, frequency: Int) {
        self.id = id
        self.arabic = arabic
        self.meaningEN = meaningEN
        self.frequency = frequency
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        arabic = try c.decode(String.self, forKey: .arabic)
        frequency = try c.decode(Int.self, forKey: .frequency)
        if let m = try? c.decode(String.self, forKey: .meaningEN) {
            meaningEN = m
        } else if let legacy = try? c.decode(String.self, forKey: .legacyTranslation) {
            meaningEN = legacy
        } else {
            meaningEN = ""
        }
        status = try c.decodeIfPresent(CardStatus.self, forKey: .status) ?? .new
        interval = try c.decodeIfPresent(Int.self, forKey: .interval) ?? 0
        easeFactor = try c.decodeIfPresent(Double.self, forKey: .easeFactor) ?? 2.5
        repetitions = try c.decodeIfPresent(Int.self, forKey: .repetitions) ?? 0
        nextReviewDate = try c.decodeIfPresent(Date.self, forKey: .nextReviewDate) ?? .distantPast
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(arabic, forKey: .arabic)
        try c.encode(meaningEN, forKey: .meaningEN)
        try c.encode(frequency, forKey: .frequency)
        try c.encode(status, forKey: .status)
        try c.encode(interval, forKey: .interval)
        try c.encode(easeFactor, forKey: .easeFactor)
        try c.encode(repetitions, forKey: .repetitions)
        try c.encode(nextReviewDate, forKey: .nextReviewDate)
    }
}

// MARK: - Session Filter

enum LearningSessionType: Hashable {
    case mixed      // Due reviews + new cards
    case newOnly    // Only .new cards
    case reviewOnly // Only due .learning / .graduated cards
}
