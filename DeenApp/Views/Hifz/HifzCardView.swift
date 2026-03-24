// DeenApp/Views/Hifz/HifzCardView.swift
//
// Glassmorphism card that renders a single Ayah with correct RTL Arabic text.
// Supports active-ayah highlighting and a blur-based hide/show toggle.

import SwiftUI

struct HifzCardView: View {

    let ayah: AyahData
    let isActive: Bool
    let isTextHidden: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            ayahNumberBadge
            arabicTextView
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(cardBackground)
    }

    // MARK: - Arabic Text (RTL, no truncation)

    private var arabicTextView: some View {
        Text(ayah.arabicText)
            .font(.system(size: 28))
            .multilineTextAlignment(.trailing)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .environment(\.layoutDirection, .rightToLeft)
            .foregroundStyle(Theme.textPrimary)
            .blur(radius: isTextHidden ? 12 : 0)
            .opacity(isTextHidden ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isTextHidden)
    }

    // MARK: - Verse Number

    private var ayahNumberBadge: some View {
        Text(ayah.ayahNumber.arabicNumerals)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isActive ? .white : Theme.accent)
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(isActive ? Theme.accent : Theme.accent.opacity(0.12))
            )
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isActive ? Theme.accent.opacity(0.5) : Theme.accent.opacity(0.1),
                        lineWidth: isActive ? 1.5 : 1
                    )
            )
            .shadow(
                color: isActive ? Theme.accent.opacity(0.15) : Theme.shadowColor,
                radius: isActive ? 12 : Theme.shadowRadius,
                x: 0,
                y: isActive ? 4 : Theme.shadowY
            )
    }
}

// MARK: - Arabic Numeral Helper

extension Int {
    var arabicNumerals: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        VStack(spacing: 16) {
            HifzCardView(
                ayah: .preview,
                isActive: true,
                isTextHidden: false
            )
            HifzCardView(
                ayah: .preview,
                isActive: false,
                isTextHidden: true
            )
        }
        .padding()
    }
}

private extension AyahData {
    static let preview = AyahData(
        id: 1,
        verseKey: "1:1",
        surahNumber: 1,
        ayahNumber: 1,
        arabicText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
        words: [],
        audioURL: URL(string: "https://example.com/audio.mp3")!
    )
}
