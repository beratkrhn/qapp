//
//  AccountHomeView.swift
//  DeenApp
//
//  Einstiegspunkt von der SettingsView: zeigt entweder die Anmelde-/
//  Registrierungs-Maske oder — bei angemeldetem Nutzer — die Freundeliste.
//

import SwiftUI

struct AccountHomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountVM: AccountViewModel

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            Group {
                if accountVM.isSignedIn {
                    FriendsView()
                } else {
                    AuthView()
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85),
                       value: accountVM.isSignedIn)
        }
        .navigationTitle(L10n.accountSection(appState.appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
    }
}
