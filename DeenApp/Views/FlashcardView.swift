//
//  FlashcardView.swift
//  DeenApp
//
//  Anki-ähnliche Karteikarten: häufigste Quran-Wörter (80%-Wortschatz).
//

import SwiftUI
import Combine

struct FlashcardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var deckStore = QuranWordsStore()
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var showAnswer: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if deckStore.words.isEmpty && !deckStore.isLoading {
                    ContentUnavailableView(
                        "Keine Karteikarten",
                        systemImage: "rectangle.stack.badge.plus",
                        description: Text("Wortliste konnte nicht geladen werden.")
                    )
                    .foregroundColor(Theme.textSecondary)
                } else if deckStore.words.isEmpty {
                    ProgressView()
                        .tint(Theme.accent)
                } else {
                    VStack(spacing: 24) {
                        progressText
                        cardView
                        buttons
                    }
                    .padding(24)
                }
            }
            .navigationTitle(L10n.tabLernen(appState.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var progressText: some View {
        Text("\(min(currentIndex + 1, deckStore.words.count)) / \(deckStore.words.count)")
            .font(.subheadline)
            .foregroundColor(Theme.textSecondary)
    }

    private var cardView: some View {
        let word = deckStore.words[currentIndex]
        return Button(action: { withAnimation(.easeInOut(duration: 0.25)) { showAnswer.toggle() } }) {
            VStack(spacing: 20) {
                Text(word.arabic)
                    .font(.custom("Geeza Pro", size: 32))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                if showAnswer {
                    VStack(spacing: 8) {
                        Text(word.meaningDE)
                            .font(.title3.weight(.medium))
                            .foregroundColor(Theme.accent)
                        Text(word.meaningEN)
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                } else {
                    Text("Tippen für Bedeutung")
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

    private var buttons: some View {
        HStack(spacing: 20) {
            Button(action: previous) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(currentIndex > 0 ? Theme.accent : Theme.textSection)
                    .frame(width: 44, height: 44)
            }
            .disabled(currentIndex == 0)

            Spacer()

            Button(action: next) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(currentIndex < deckStore.words.count - 1 ? Theme.accent : Theme.textSection)
                    .frame(width: 44, height: 44)
            }
            .disabled(currentIndex >= deckStore.words.count - 1)
        }
    }

    private func previous() {
        withAnimation {
            currentIndex = max(0, currentIndex - 1)
            showAnswer = false
        }
    }

    private func next() {
        withAnimation {
            currentIndex = min(deckStore.words.count - 1, currentIndex + 1)
            showAnswer = false
        }
    }
}

// MARK: - Wort-Deck laden

@MainActor
final class QuranWordsStore: ObservableObject {
    @Published private(set) var words: [QuranWord] = []
    @Published private(set) var isLoading = false

    init() {
        loadFromBundle()
    }

    func loadFromBundle() {
        isLoading = true
        defer { isLoading = false }
        guard let url = Bundle.main.url(forResource: "quran_words", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let deck = try? JSONDecoder().decode(QuranWordsDeck.self, from: data) else {
            words = []
            return
        }
        words = deck.words
    }
}

#Preview {
    FlashcardView()
        .environmentObject(AppState())
}
