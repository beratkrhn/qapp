// DeenApp/Models/Hifz/DailyActivity.swift
//
// SwiftData model representing one calendar day's Hifz activity.
// Used to power the GitHub-style contribution heatmap.

import Foundation
import SwiftData

@Model
final class DailyActivity {

    // MARK: - Identity

    var id: UUID

    /// Normalised to midnight (00:00:00) of the local calendar day.
    var date: Date

    // MARK: - Activity Counts

    /// How many complete 3×3 loops (full chunks) the user finished today.
    var loopsCompleted: Int

    /// Total Ayat memorised today (loopsCompleted × ayat-per-chunk).
    var ayatMemorized: Int

    // MARK: - Init

    init(date: Date, loopsCompleted: Int = 0, ayatMemorized: Int = 0) {
        self.id             = UUID()
        self.date           = DailyActivity.normalise(date)
        self.loopsCompleted = loopsCompleted
        self.ayatMemorized  = ayatMemorized
    }

    // MARK: - Helpers

    /// Normalises a Date to the start of its calendar day (local timezone).
    static func normalise(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    /// Intensity bucket for the heatmap (0 = no activity, 4 = highest).
    var heatmapIntensity: Int {
        switch loopsCompleted {
        case 0:        return 0
        case 1:        return 1
        case 2...3:    return 2
        case 4...6:    return 3
        default:       return 4
        }
    }
}
