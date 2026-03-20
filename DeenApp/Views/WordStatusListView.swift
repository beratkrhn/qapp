//
//  WordStatusListView.swift
//  DeenApp
//
//  Vollbild-Liste aller QWords inkl. Übersetzung und Lernstatus.
//

import SwiftUI

struct WordStatusListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SRSViewModel.self) private var srsViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(srsViewModel.allCards) { card in
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.arabic)
                                .font(.custom("KFGQPC Uthmanic Script HAFS Regular", size: 26, relativeTo: .title3))
                                .foregroundColor(Theme.textPrimary)

                            Text(card.meaningEN)
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 12)

                        Text(card.status == .graduated ? "Gelernt" : "Nicht gelernt")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(card.status == .graduated ? .black : Theme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(card.status == .graduated ? Theme.accent : Theme.cardBackground)
                            )
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Theme.background)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Wörter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }
}

#Preview {
    WordStatusListView()
        .environment(SRSViewModel())
}
