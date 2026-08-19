//
//  BottomInfoCardsView.swift
//  DeenApp
//

import SwiftUI

struct BottomInfoCardsView: View {
    @EnvironmentObject var appState: AppState
    var language: AppLanguage = .german

    var body: some View {
        HStack(spacing: 14) {
            Button(action: { appState.selectedTab = .quran }) {
                SmallInfoCard(
                    icon: "book.fill",
                    iconColor: Theme.textPrimary,
                    title: L10n.tabQuran(language),
                    subtitle: L10n.quranContinue(language)
                )
            }
            .buttonStyle(.plain)
            Button(action: { appState.selectedTab = .lernen }) {
                SmallInfoCard(
                    icon: "brain",
                    iconColor: Theme.iconBrain,
                    title: L10n.tabLernen(language),
                    subtitle: L10n.flashcards(language)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

struct SmallInfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    BottomInfoCardsView(language: .german)
        .environmentObject(AppState())
        .padding()
        .background(Theme.background)
}
