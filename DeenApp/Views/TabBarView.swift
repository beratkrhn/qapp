//
//  TabBarView.swift
//  DeenApp
//

import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.rawValue) { tab in
                TabBarItemView(
                    tab: tab,
<<<<<<< HEAD
                    isSelected: appState.selectedTab == tab,
                    language: appState.appLanguage
=======
                    isSelected: appState.selectedTab == tab
>>>>>>> origin/claude/adoring-banach
                ) {
                    appState.selectedTab = tab
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: -4)
        )
        .padding(.horizontal, 16)
    }
}

struct TabBarItemView: View {
    let tab: MainTab
    let isSelected: Bool
<<<<<<< HEAD
    let language: AppLanguage
=======
>>>>>>> origin/claude/adoring-banach
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.accent)
                            .frame(width: 44, height: 32)
                    }
                    Image(systemName: tab.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? Theme.background : Theme.textSecondary)
                }
                .frame(height: 32)

<<<<<<< HEAD
                Text(tab.title(lang: language))
=======
                Text(tab.title)
>>>>>>> origin/claude/adoring-banach
                    .font(.caption2)
                    .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TabBarView()
        .environmentObject(AppState())
        .background(Theme.background)
}
