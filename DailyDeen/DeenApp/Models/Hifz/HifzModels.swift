// DeenApp/Models/Hifz/HifzModels.swift
//
// State machine enums and pure value types for the Hifz (Memorization) feature.
// No persistence here — this file contains only transient, in-memory types.

import Foundation

// MARK: - State Machine

/// Top-level phases of the 3×3 memorisation method.
enum HifzPhase: Equatable {

    // Waiting for the user to pick a Surah / chunk.
    case idle

    // State 2a – Show verse, play audio, highlight words. readCount: 0…2
    case readAndListen(verseIndex: Int, readCount: Int)

    // State 2b – Hide text; user recalls from memory. recallCount: 0…2
    case activeRecall(verseIndex: Int, recallCount: Int)

    // State 3 – Show concatenated v1+v2+v3 (read-only review).
    case concatenation

    // State 4 – User must recall the full block 3 times. recallCount: 0…2
    case commitToMemory(recallCount: Int)

    // State 5 – Persisting SRSItem + DailyActivity to SwiftData.
    case saving

    // Terminal success state for a chunk.
    case complete

    // Terminal error state.
    case error(String)
}

// MARK: - Audio / Word-level data

/// A single Arabic word with its playback time-window in the audio track.
struct HifzWord: Identifiable, Equatable {
    let id: UUID
    let text: String        // Arabic word string
    let startTime: Double   // seconds from audio start
    let endTime: Double     // seconds from audio start

    init(text: String, startTime: Double, endTime: Double) {
        self.id        = UUID()
        self.text      = text
        self.startTime = startTime
        self.endTime   = endTime
    }
}

// MARK: - Verse & Chunk data

/// All data needed to display and audio-play one Ayah.
struct AyahData: Identifiable, Equatable {
    let id: Int                // Global ayah number (1-based across Quran)
    let verseKey: String       // e.g. "2:255"
    let surahNumber: Int
    let ayahNumber: Int
    let arabicText: String
    let words: [HifzWord]
    let audioURL: URL
}

/// Three consecutive Ayat that form a single memorisation block.
struct HifzChunk: Identifiable, Equatable {
    let id: UUID
    let surahNumber: Int
    let chunkIndex: Int        // 0-based chunk position within the Surah
    let ayat: [AyahData]       // Always 1–3 items (last chunk may be shorter)

    init(surahNumber: Int, chunkIndex: Int, ayat: [AyahData]) {
        self.id           = UUID()
        self.surahNumber  = surahNumber
        self.chunkIndex   = chunkIndex
        self.ayat         = ayat
    }
}

// MARK: - SRS Schedule Helpers

/// The canonical SRS interval ladder (days).
/// After each successful recall the scheduler advances one step.
enum SRSInterval: Int, CaseIterable {
    case day1   = 1
    case day3   = 3
    case day7   = 7
    case day14  = 14
    case day30  = 30
    case day90  = 90

    /// Returns the next interval, or stays at the last step (90 days).
    var next: SRSInterval {
        let all = SRSInterval.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else {
            return .day90
        }
        return all[idx + 1]
    }

    var daysValue: Int { rawValue }
}
