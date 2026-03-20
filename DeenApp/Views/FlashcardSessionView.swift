//
//  FlashcardSessionView.swift
//  DeenApp
//
//  SM-2-Lernsession: zeigt arabischen Text und englische Bedeutung (meaningEN).
//

import SwiftUI

struct FlashcardSessionView: View {
    let sessionType: LearningSessionType

    @Environment(SRSViewModel.self) private var viewModel
    @State private var showAnswer = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if viewModel.sessionFinished {
                sessionCompleteView
            } else if let card = viewModel.currentCard {
                VStack(spacing: 24) {
                    progressHeader
                    cardContent(card: card)
                    ratingBar
                }
                .padding(24)
            } else {
                ContentUnavailableView(
                    "Keine Karten",
                    systemImage: "rectangle.stack",
                    description: Text("Für diese Session sind keine Karten verfügbar.")
                )
                .foregroundColor(Theme.textSecondary)
            }
        }
        .task(id: sessionType) {
            viewModel.resetSession()
            viewModel.startSession(type: sessionType)
            showAnswer = false
        }
    }

    private var progressHeader: some View {
        let total = max(viewModel.sessionQueue.count, 1)
        let pos = min(viewModel.currentIndex + 1, total)
        return Text("\(pos) / \(total)")
            .font(.subheadline)
            .foregroundColor(Theme.textSecondary)
    }

    private func cardContent(card: FlashcardCard) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { showAnswer.toggle() }
        } label: {
            VStack(spacing: 20) {
                Text(card.arabic)
                    .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 40, relativeTo: .largeTitle))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                if showAnswer {
                    VStack(spacing: 8) {
                        Text(card.meaningEN)
                            .font(.title3.weight(.medium))
                            .foregroundColor(Theme.accent)
                            .multilineTextAlignment(.center)

                        Text("\(card.frequency)× in Quran")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)

                        Text("Anteil an allen Vorkommen: ca. \(formatPercent(QuranVocabularyProgress.wordOccurrenceSharePercent(frequency: card.frequency))) %")
                            .font(.caption)
                            .foregroundColor(Theme.textSection)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Text("Tippen für Details")
                        .font(.caption)
                        .foregroundColor(Theme.textSection)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.cardBackground)
                    .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
            )
        }
        .buttonStyle(.plain)
    }

    private var ratingBar: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(SRSRating.allCases, id: \.self) { rating in
                Button {
                    viewModel.rate(rating)
                    showAnswer = false
                } label: {
                    VStack(spacing: 6) {
                        Text(rating.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(ankiIntervalLabel(for: rating))
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 84)
                    .background(Theme.accent.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func ankiIntervalLabel(for rating: SRSRating) -> String {
        switch rating {
        case .again: return "<1min"
        case .hard:  return "<10min"
        case .good:  return "1d"
        case .easy:  return "3d"
        }
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.accent)
            Text("Session beendet")
                .font(.title2.weight(.semibold))
                .foregroundColor(Theme.textPrimary)
            Button("Nochmal") {
                viewModel.resetSession()
                viewModel.startSession(type: sessionType)
            }
            .foregroundColor(Theme.accent)
        }
    }

    private func formatPercent(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

#Preview {
    FlashcardSessionView(sessionType: .mixed)
        .environment(SRSViewModel())
}
