// DeenApp/Views/Components/ContributionHeatmapView.swift
//
// GitHub-style contribution heatmap driven by DailyActivity records.
// Fully reusable — pass any [DailyActivity] array to render.

import SwiftUI

// MARK: - Public View

struct ContributionHeatmapView: View {

    /// Activities for the trailing `weekCount` weeks (supply all; view filters internally).
    let activities: [DailyActivity]

    /// How many complete weeks to display (default 18 ≈ ~4 months).
    var weekCount: Int = 18

    /// Label shown above the grid.
    var title: String = "Hifz Activity"

    // MARK: - Private

    private let cellSize: CGFloat    = 12
    private let cellSpacing: CGFloat = 3
    private let columns: Int         = 7   // days per week (Sun…Sat)

    private var grid: [[Date?]] {
        buildGrid()
    }

    private var activityMap: [Date: DailyActivity] {
        Dictionary(activities.map { ($0.date, $0) }, uniquingKeysWith: { $1 })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title + legend row
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                legendRow
            }

            // Day-of-week labels + grid
            HStack(alignment: .top, spacing: cellSpacing) {
                dayLabels
                weekColumnsGrid
            }
        }
        .padding(Theme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
        )
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }

    // MARK: - Sub-views

    private var dayLabels: some View {
        VStack(alignment: .trailing, spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { dow in
                Text(shortDayLabel(dow))
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 14, height: cellSize)
            }
        }
    }

    private var weekColumnsGrid: some View {
        HStack(alignment: .top, spacing: cellSpacing) {
            ForEach(0..<grid.count, id: \.self) { col in
                VStack(spacing: cellSpacing) {
                    ForEach(0..<columns, id: \.self) { row in
                        cellView(for: grid[col][row])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(for date: Date?) -> some View {
        if let date {
            let intensity = activityMap[date]?.heatmapIntensity ?? 0
            RoundedRectangle(cornerRadius: 2)
                .fill(cellColor(intensity: intensity))
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5)
                )
        } else {
            Color.clear
                .frame(width: cellSize, height: cellSize)
        }
    }

    private var legendRow: some View {
        HStack(spacing: 3) {
            Text("Less")
                .font(.system(size: 8))
                .foregroundStyle(Theme.textSecondary)

            ForEach(0...4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(cellColor(intensity: i))
                    .frame(width: cellSize, height: cellSize)
            }

            Text("More")
                .font(.system(size: 8))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Helpers

    /// Returns a column-major 2D grid of calendar Dates (nil = padding cell).
    /// Each column = one ISO week (Sun–Sat), newest week at the right edge.
    private func buildGrid() -> [[Date?]] {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: .now)

        // Anchor to the Sunday of today's week so grid aligns cleanly
        let weekday      = calendar.component(.weekday, from: today) // 1=Sun … 7=Sat
        let daysSinceSun = weekday - 1
        guard let thisSunday = calendar.date(byAdding: .day, value: -daysSinceSun, to: today) else {
            return []
        }

        var columns: [[Date?]] = []
        for w in stride(from: weekCount - 1, through: 0, by: -1) {
            guard let colStart = calendar.date(byAdding: .weekOfYear, value: -w, to: thisSunday) else {
                continue
            }
            let days: [Date?] = (0..<7).map { d -> Date? in
                guard let date = calendar.date(byAdding: .day, value: d, to: colStart) else { return nil }
                return date > today ? nil : date
            }
            columns.append(days)
        }
        return columns
    }

    private func cellColor(intensity: Int) -> Color {
        switch intensity {
        case 0:  return Color(hex: "1E2E2A")           // empty cell (slightly lighter than bg)
        case 1:  return Theme.accent.opacity(0.25)
        case 2:  return Theme.accent.opacity(0.50)
        case 3:  return Theme.accent.opacity(0.75)
        default: return Theme.accent                    // full intensity
        }
    }

    private func shortDayLabel(_ dow: Int) -> String {
        // dow 0 = Sunday
        switch dow {
        case 1: return "M"
        case 3: return "W"
        case 5: return "F"
        default: return ""
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        ContributionHeatmapView(
            activities: PreviewData.sampleActivities,
            title: "Hifz Activity"
        )
        .padding()
    }
}

// MARK: - Preview Helpers (compile-time only)

private enum PreviewData {
    static var sampleActivities: [DailyActivity] {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: .now)
        return (0..<90).compactMap { offset -> DailyActivity? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let loops = Int.random(in: 0...5)
            guard loops > 0 else { return nil }
            return DailyActivity(date: date, loopsCompleted: loops, ayatMemorized: loops * 3)
        }
    }
}
