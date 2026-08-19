//
//  LearnTabView.swift
//  DeenApp
//
//  Hub view for the "Lernen" tab — lets the user choose between
//  Hifz Mode (3×3 memorisation) and Quran Words (SRS flashcards).
//

import SwiftUI

enum LearnMode: String, Identifiable, CaseIterable {
    case quranWords
    case continueAyah
    case hifzTracker

    var id: String { rawValue }
}

struct LearnTabView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedMode: LearnMode?

    var body: some View {
        Group {
            if let mode = selectedMode {
                switch mode {
                case .quranWords:
                    LearningDashboardView {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedMode = nil
                        }
                    }
                case .continueAyah:
                    ContinueAyahView {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedMode = nil
                        }
                    }
                case .hifzTracker:
                    HifzTrackerView {
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
                        title: "Quran Words",
                        subtitle: "Spaced-repetition vocabulary flashcards",
                        icon: "character.book.closed.fill",
                        accentColor: Theme.learnWords
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedMode = .quranWords
                        }
                    }

                    LearnModeCard(
                        title: "Continue the Ayah",
                        subtitle: "Recite the next ayah from memory",
                        icon: "text.book.closed.fill",
                        accentColor: Theme.learnContinue
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedMode = .continueAyah
                        }
                    }

                    LearnModeCard(
                        title: L10n.hifzLearnModeTitle(appState.appLanguage),
                        subtitle: L10n.hifzLearnModeSubtitle(appState.appLanguage),
                        icon: "brain.head.profile",
                        accentColor: Theme.learnHifz
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedMode = .hifzTracker
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
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
    }
}

#Preview {
    LearnTabView()
        .environment(SRSViewModel())
        .environmentObject(AppState())
}
