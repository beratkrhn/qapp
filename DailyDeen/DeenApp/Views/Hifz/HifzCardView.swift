// DeenApp/Views/Hifz/HifzCardView.swift
//
// Premium card that renders Arabic text with word-by-word highlighting.
// Transitions smoothly between "visible" (read) and "blurred" (recall) states.

import SwiftUI

struct HifzCardView: View {

    let words: [HifzWord]
    let activeWordID: UUID?
    let isBlurred: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            arabicTextFlow
                .blur(radius: isBlurred ? 10 : 0)
                .animation(.easeInOut(duration: 0.35), value: isBlurred)
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .strokeBorder(Theme.accent.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }

    // MARK: - Arabic Word Flow

    /// Lays out words right-to-left with per-word highlight.
    private var arabicTextFlow: some View {
        // SwiftUI has no native RTL wrapping FlowLayout, so we use
        // a simple approach: reverse the word order and let .leading
        // wrap + environment layoutDirection handle RTL visually.
        let reversed = words.reversed()

        return VStack(spacing: 8) {
            FlowLayout(spacing: 6) {
                ForEach(Array(reversed)) { word in
                    wordChip(word)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    @ViewBuilder
    private func wordChip(_ word: HifzWord) -> some View {
        let isActive = word.id == activeWordID

        Text(word.text)
            .font(.system(size: 28, weight: .regular, design: .default))
            .foregroundStyle(isActive ? Theme.accent : Theme.textPrimary.opacity(0.8))
            .scaleEffect(isActive ? 1.12 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
    }
}

// MARK: - Minimal FlowLayout

/// A simple left-to-right wrapping layout (direction flipped per environment above).
private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                totalHeight = y
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        HifzCardView(
            words: sampleWords,
            activeWordID: sampleWords[1].id,
            isBlurred: false
        )
        .padding()
    }
}

private let sampleWords: [HifzWord] = [
    HifzWord(text: "بِسْمِ",   startTime: 0,   endTime: 0.8),
    HifzWord(text: "اللَّهِ",  startTime: 0.8, endTime: 1.5),
    HifzWord(text: "الرَّحْمَٰنِ", startTime: 1.5, endTime: 2.4),
    HifzWord(text: "الرَّحِيمِ", startTime: 2.4, endTime: 3.2),
]
