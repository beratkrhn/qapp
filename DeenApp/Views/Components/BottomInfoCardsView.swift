//
//  BottomInfoCardsView.swift
//  DeenApp
//

import SwiftUI

struct BottomInfoCardsView: View {
    var body: some View {
        HStack(spacing: 14) {
            SmallInfoCard(
                icon: "book.fill",
                iconColor: Theme.textPrimary,
                title: "Kur'an",
                subtitle: "Weiterlesen"
            )
            SmallInfoCard(
                icon: "brain",
                iconColor: Theme.iconBrain,
                title: "Vokabeln",
                subtitle: "Karteikarten"
            )
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
                    .font(.title3)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    BottomInfoCardsView()
        .padding()
        .background(Theme.background)
}
