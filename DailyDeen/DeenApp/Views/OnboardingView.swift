//
//  OnboardingView.swift
//  DeenApp
//
//  Einmalige Abfrage: Name + App-Sprache (DE, EN, TR, Deutsch/Arabisch).
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""
    @State private var selectedLanguage: AppLanguage = .german

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Text(L10n.greetingArabic)
                    .font(.largeTitle)
                    .foregroundColor(Theme.accent)
                    .padding(.top, 40)

                Text(L10n.onboardingTitle(selectedLanguage))
                    .font(.title2.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.onboardingNamePrompt(selectedLanguage))
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    TextField("z. B. Berat", text: $name)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        .foregroundColor(Theme.textPrimary)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.onboardingLanguagePrompt(selectedLanguage))
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    Picker("", selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.textPrimary)
                    .padding(14)
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(action: {
                    appState.completeOnboarding(name: name, language: selectedLanguage)
                }) {
                    Text(L10n.onboardingContinue(selectedLanguage))
                        .font(.headline)
                        .foregroundColor(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
