// DeenApp/Models/Hifz/HifzProgress.swift
//
// SwiftData model tracking the user's current position within a Surah.
// Only one record per Surah is expected; the app upserts on each session end.

import Foundation
import SwiftData

@Model
final class HifzProgress {

    // MARK: - Identity

    var id: UUID
    var surahNumber: Int

    // MARK: - Position

    /// The chunk index the user should work on next (0-based).
    var currentChunkIndex: Int

    /// Total number of chunks in this Surah (set once on first load).
    var totalChunks: Int

    // MARK: - Metadata

    var startedAt: Date
    var lastUpdatedAt: Date

    // MARK: - Init

    init(surahNumber: Int, totalChunks: Int) {
        self.id                = UUID()
        self.surahNumber       = surahNumber
        self.currentChunkIndex = 0
        self.totalChunks       = totalChunks
        self.startedAt         = .now
        self.lastUpdatedAt     = .now
    }

    // MARK: - Helpers

    /// Advances to the next chunk. Clamps at totalChunks.
    func advanceChunk() {
        if currentChunkIndex < totalChunks - 1 {
            currentChunkIndex += 1
        }
        lastUpdatedAt = .now
    }

    var isComplete: Bool {
        currentChunkIndex >= totalChunks - 1
    }

    /// Fraction 0.0…1.0 for progress indicators.
    var progressFraction: Double {
        guard totalChunks > 0 else { return 0 }
        return Double(currentChunkIndex) / Double(totalChunks)
    }
}
