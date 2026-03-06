//
//  FlashcardSessionView.swift
//  DeenApp
//
//  SM-2-Lernsitzung: 3D-Kartenflip, SRS-Bewertungsknöpfe, Sitzungsabschluss-Bildschirm.
//

import SwiftUI

// MARK: - Session View

struct FlashcardSessionView: View {
    @Environment(SRSViewModel.self) private var srsViewModel
    @Environment(\.dismiss) private var dismiss

    let sessionType: LearningSessionType

    @State private var isFlipped: Bool = false
    @State private var flipDegrees: Double = 0
    @State private var cardSlideOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if srsViewModel.sessionFinished {
                sessionCompleteView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if let card = srsViewModel.currentCard {
                sessionContent(card: card)
                    .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    srsViewModel.resetSession()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(8)
                        .background(Circle().fill(Theme.cardBackground))
                }
            }
        }
        .onAppear {
            srsViewModel.startSession(type: sessionType)
        }
        .animation(.easeInOut(duration: 0.35), value: srsViewModel.sessionFinished)
    }

    // MARK: - Active Session

    @ViewBuilder
    private func sessionContent(card: FlashcardCard) -> some View {
        VStack(spacing: 0) {
            progressBar
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)

            Spacer(minLength: 0)

            // The flip card
            ZStack {
                CardFace(card: card, showBack: false)
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(flipDegrees), axis: (0, 1, 0))

                CardFace(card: card, showBack: true)
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(flipDegrees - 180), axis: (0, 1, 0))
            }
            .id(card.id)
            .offset(x: cardSlideOffset)
            .opacity(cardOpacity)
            .padding(.horizontal, 20)
            .onTapGesture {
                guard !isFlipped else { return }
                flipCard()
            }

            Spacer(minLength: 0)

            // Bottom area: hint or rating buttons
            // Extra bottom padding keeps buttons clear of the persistent tab bar.
            Group {
                if isFlipped {
                    ratingButtons
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    tapHint
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.25), value: isFlipped)
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let total   = srsViewModel.sessionQueue.count
        let current = min(srsViewModel.currentIndex, total)
        let fraction = total > 0 ? Double(current) / Double(total) : 0

        return VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.cardBackground)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.accent)
                        .frame(width: geo.size.width * fraction, height: 6)
                        .animation(.easeOut(duration: 0.4), value: fraction)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(current) / \(total)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text(sessionTypeLabel)
                    .font(.caption.weight(.medium))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    private var sessionTypeLabel: String {
        switch sessionType {
        case .mixed:      return "Lernen"
        case .newOnly:    return "Neue Wörter"
        case .reviewOnly: return "Wiederholen"
        }
    }

    // MARK: - Tap Hint

    private var tapHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.tap")
                .font(.caption)
            Text("Auf die Karte tippen, um die Antwort zu sehen")
                .font(.caption)
        }
        .foregroundColor(Theme.textSection.opacity(0.6))
        .padding(.bottom, 20)
    }

    // MARK: - Rating Buttons

    private var ratingButtons: some View {
        VStack(spacing: 10) {
            Text("Wie gut hast du dich erinnert?")
                .font(.caption.weight(.medium))
                .foregroundColor(Theme.textSecondary)
                .padding(.bottom, 2)

            HStack(spacing: 10) {
                ForEach(SRSRating.allCases, id: \.label) { rating in
                    RatingButton(rating: rating) {
                        applyRating(rating)
                    }
                }
            }
        }
    }

    // MARK: - Session Complete

    private var sessionCompleteView: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 70))
                .foregroundColor(Theme.accent)
                .shadow(color: Theme.accent.opacity(0.5), radius: 20, x: 0, y: 0)

            VStack(spacing: 8) {
                Text("Maşallah! 🌟")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(Theme.textPrimary)
                Text("Sitzung abgeschlossen")
                    .font(.headline)
                    .foregroundColor(Theme.textSecondary)
            }

            CardContainer {
                HStack(spacing: 0) {
                    completionStat(
                        value: "\(srsViewModel.graduatedCount)",
                        label: "Gelernt",
                        color: Theme.accent
                    )
                    Divider()
                        .frame(height: 44)
                        .background(Theme.textSecondary.opacity(0.2))
                    completionStat(
                        value: "\(Int(srsViewModel.progressPercent.rounded()))%",
                        label: "Verstanden",
                        color: Theme.accent
                    )
                    Divider()
                        .frame(height: 44)
                        .background(Theme.textSecondary.opacity(0.2))
                    completionStat(
                        value: "\(srsViewModel.newCount)",
                        label: "Noch neu",
                        color: Theme.textSecondary
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            Button {
                srsViewModel.resetSession()
                dismiss()
            } label: {
                Text("Fertig")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                            .fill(Theme.accent)
                    )
            }
            .shadow(color: Theme.accent.opacity(0.4), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private func completionStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Flip Logic

    private func flipCard() {
        withAnimation(.easeInOut(duration: 0.45)) {
            flipDegrees += 180
        }
        // Reveal back face at the midpoint of the rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            isFlipped = true
        }
    }

    // MARK: - Rating & Card Transition

    private func applyRating(_ rating: SRSRating) {
        // Slide current card out to the left
        withAnimation(.easeIn(duration: 0.2)) {
            cardSlideOffset = -UIScreen.main.bounds.width * 0.6
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            // Apply SRS logic (updates currentCard)
            srsViewModel.rate(rating)

            // Reset card state (no animation — instant for the incoming card)
            isFlipped = false
            flipDegrees = 0
            cardSlideOffset = UIScreen.main.bounds.width * 0.6  // start off-screen right

            // Slide new card in
            withAnimation(.easeOut(duration: 0.25)) {
                cardSlideOffset = 0
                cardOpacity = 1
            }
        }
    }
}

// MARK: - Card Face (Front / Back)

private struct CardFace: View {
    let card: FlashcardCard
    let showBack: Bool

    var body: some View {
        VStack(spacing: 20) {
            if showBack {
                backContent
            } else {
                frontContent
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
        )
        .frame(maxHeight: 300)
    }

    private var frontContent: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            Text(card.arabic)
                .font(.custom("Geeza Pro", size: 52))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)

            Spacer(minLength: 0)

            // Frequency badge
            HStack(spacing: 4) {
                Image(systemName: "text.book.closed")
                    .font(.caption2)
                Text("Kommt \(card.frequency)× im Quran vor")
                    .font(.caption2.weight(.medium))
            }
            .foregroundColor(Theme.textSection.opacity(0.55))
        }
    }

    private var backContent: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            // Arabic echoed smaller at top
            Text(card.arabic)
                .font(.custom("Geeza Pro", size: 28))
                .foregroundColor(Theme.accent.opacity(0.7))

            Divider()
                .background(Theme.textSecondary.opacity(0.25))
                .padding(.horizontal, 20)

            Text(card.translation)
                .font(.title3.weight(.semibold))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Image(systemName: "text.book.closed")
                    .font(.caption2)
                Text("Kommt \(card.frequency)× im Quran vor")
                    .font(.caption2.weight(.medium))
            }
            .foregroundColor(Theme.textSection.opacity(0.55))
        }
    }
}

// MARK: - Rating Button

private struct RatingButton: View {
    let rating: SRSRating
    let action: () -> Void

    private var buttonColor: Color {
        switch rating {
        case .again: return Color(hex: "EF5350")    // red
        case .hard:  return Color(hex: "FF9800")    // orange
        case .good:  return Color(hex: "66BB6A")    // green
        case .easy:  return Color(hex: "42A5F5")    // blue
        }
    }

    var body: some View {
        Button(action: action) {
            Text(rating.label)
                .font(.caption.weight(.bold))
                .foregroundColor(buttonColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(buttonColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(buttonColor.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FlashcardSessionView(sessionType: .mixed)
            .environment(SRSViewModel())
    }
}
