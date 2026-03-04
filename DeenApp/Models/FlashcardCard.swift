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

enum SRSRating: CaseIterable {
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
    let translation: String     // German meaning
    let frequency: Int          // Occurrences in the Quran

    // MARK: SRS state (mutable — persisted via UserDefaults in SRSViewModel)
    var status: CardStatus  = .new
    var interval: Int       = 0     // Days until next review
    var easeFactor: Double  = 2.5   // SM-2 EF (min 1.3)
    var repetitions: Int    = 0     // Consecutive correct answers
    var nextReviewDate: Date = .distantPast

    init(id: String, arabic: String, translation: String, frequency: Int) {
        self.id = id
        self.arabic = arabic
        self.translation = translation
        self.frequency = frequency
    }
}

// MARK: - Session Filter

enum LearningSessionType: Hashable {
    case mixed      // Due reviews + new cards
    case newOnly    // Only .new cards
    case reviewOnly // Only due .learning / .graduated cards
}
