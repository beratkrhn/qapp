//
//  LearnTabView.swift
//  DeenApp
//
//  Hub view for the "Lernen" tab — lets the user choose between
//  Hifz Mode (3×3 memorisation) and Quran Words (SRS flashcards).
//

import SwiftUI

enum LearnMode: String, Identifiable, CaseIterable {
    case surahReveal
    case quranWords

    var id: String { rawValue }
}

struct LearnTabView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedMode: LearnMode?

    var body: some View {
        Group {
            if let mode = selectedMode {
                switch mode {
                case .surahReveal:
                    SurahRevealView {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedMode = nil
                        }
                    }
                case .quranWords:
                    LearningDashboardView {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedMode = nil
                        }
                    }
                }
            } else {
                modePickerView
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedMode)
    }

    // MARK: - Mode Picker

    private var modePickerView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.tabLernen(appState.appLanguage))
                        .font(.largeTitle.bold())
                        .foregroundStyle(Theme.textPrimary)
                    Text("Choose your learning path")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)

                VStack(spacing: 16) {
                    LearnModeCard(
                        title: "Surah Reveal",
                        subtitle: "Reveal Ayat one by one to memorise",
                        icon: "eye.slash.fill",
                        accentColor: Theme.accent,
                        comingSoon: true
                    ) {
                        // disabled — coming soon
                    }

                    LearnModeCard(
                        title: "Quran Words",
                        subtitle: "Spaced-repetition vocabulary flashcards",
                        icon: "character.book.closed.fill",
                        accentColor: Color(hex: "FF9800")
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedMode = .quranWords
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 140)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

// MARK: - Mode Card

private struct LearnModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    var comingSoon: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accentColor.opacity(comingSoon ? 0.07 : 0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(accentColor.opacity(comingSoon ? 0.4 : 1.0))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary.opacity(comingSoon ? 0.4 : 1.0))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary.opacity(comingSoon ? 0.4 : 1.0))
                        .lineLimit(2)
                    if comingSoon {
                        Text("Bald verfügbar")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(Theme.textSecondary.opacity(0.15))
                            )
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary.opacity(0.25))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .fill(Theme.cardBackground)
                    .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
            )
        }
        .buttonStyle(.plain)
        .disabled(comingSoon)
    }
}

#Preview {
    LearnTabView()
        .environment(SRSViewModel())
        .environmentObject(AppState())
}
