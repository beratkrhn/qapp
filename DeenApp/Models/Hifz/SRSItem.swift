// DeenApp/Models/Hifz/SRSItem.swift
//
// SwiftData model representing a memorised chunk scheduled for spaced-repetition review.

import Foundation
import SwiftData

@Model
final class SRSItem {

    // MARK: - Identity

    var id: UUID
    var surahNumber: Int
    var chunkIndex: Int         // Matches HifzChunk.chunkIndex

    // MARK: - SRS Schedule (simplified SM-2)

    /// The next date the user should review this chunk.
    var nextReviewDate: Date

    /// Current interval step stored as raw Int (maps to SRSInterval.rawValue).
    var intervalDays: Int

    /// Number of consecutive successful recalls (used to advance the ladder).
    var repetitions: Int

    // MARK: - Metadata

    var createdAt: Date
    var lastReviewedAt: Date?

    // MARK: - Init

    init(
        surahNumber: Int,
        chunkIndex: Int
    ) {
        self.id              = UUID()
        self.surahNumber     = surahNumber
        self.chunkIndex      = chunkIndex
        self.intervalDays    = SRSInterval.day1.daysValue
        self.nextReviewDate  = Calendar.current.date(
            byAdding: .day,
            value: SRSInterval.day1.daysValue,
            to: .now
        ) ?? .now
        self.repetitions     = 0
        self.createdAt       = .now
        self.lastReviewedAt  = nil
    }

    // MARK: - Scheduling

    /// Call after a successful recall session to advance to the next interval.
    func markReviewed() {
        repetitions       += 1
        lastReviewedAt     = .now

        // Advance the SRS ladder.
        let current        = SRSInterval(rawValue: intervalDays) ?? .day1
        let next           = current.next
        intervalDays       = next.daysValue
        nextReviewDate     = Calendar.current.date(
            byAdding: .day,
            value: next.daysValue,
            to: .now
        ) ?? .now
    }

    /// Call when the user fails recall — reset the interval to day 1.
    func markFailed() {
        intervalDays    = SRSInterval.day1.daysValue
        nextReviewDate  = Calendar.current.date(
            byAdding: .day,
            value: SRSInterval.day1.daysValue,
            to: .now
        ) ?? .now
    }

    /// True when the review date has passed and the chunk is due.
    var isDue: Bool {
        nextReviewDate <= .now
    }
}
