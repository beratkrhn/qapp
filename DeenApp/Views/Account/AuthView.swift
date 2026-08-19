//
//  AuthView.swift
//  DeenApp
//
//  Schaltbare Anmelde-/Registrierungs-Maske.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountVM: AccountViewModel

    private enum Mode { case signIn, signUp }
    @State private var mode: Mode = .signIn

    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var displayName = ""

    @FocusState private var focused: Field?
    private enum Field { case email, password, username, displayName }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 22) {
                header

                card {
                    VStack(spacing: 14) {
                        if mode == .signUp {
                            field(L10n.accountUsername(appState.appLanguage),
                                  systemImage: "at",
                                  text: $username,
                                  focus: .username,
                                  hint: L10n.accountUsernameHint(appState.appLanguage),
                                  autocaps: false)
                            field(L10n.accountDisplayName(appState.appLanguage),
                                  systemImage: "person.fill",
                                  text: $displayName,
                                  focus: .displayName,
                                  autocaps: true)
                        }
                        field(L10n.accountEmail(appState.appLanguage),
                              systemImage: "envelope.fill",
                              text: $email,
                              focus: .email,
                              isEmail: true)
                        secureField(L10n.accountPassword(appState.appLanguage),
                                    systemImage: "lock.fill",
                                    text: $password,
                                    focus: .password)
                    }
                }

                if let error = accountVM.errorMessage, !error.isEmpty {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                if let info = accountVM.infoMessage, !info.isEmpty {
                    Text(info)
                        .font(.footnote)
                        .foregroundColor(Theme.accent)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                actionButton
                if mode == .signIn {
                    forgotPasswordButton
                }
                switchModeButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(Theme.accent)
            Text(mode == .signIn
                 ? L10n.accountSignIn(appState.appLanguage)
                 : L10n.accountSignUp(appState.appLanguage))
                .font(.title2.weight(.semibold))
                .foregroundColor(Theme.textPrimary)
            Text(L10n.accountSubtitleGuest(appState.appLanguage))
                .font(.footnote)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var actionButton: some View {
        Button(action: submit) {
            HStack(spacing: 10) {
                if accountVM.isWorking {
                    ProgressView().tint(.white)
                }
                Text(mode == .signIn
                     ? L10n.accountSignIn(appState.appLanguage)
                     : L10n.accountSignUp(appState.appLanguage))
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.accent)
            )
        }
        .disabled(accountVM.isWorking || !isFormValid)
        .opacity(isFormValid ? 1 : 0.6)
    }

    private var forgotPasswordButton: some View {
        Button {
            focused = nil
            let lang = appState.appLanguage
            let address = email.trimmingCharacters(in: .whitespaces)
            guard address.contains("@") else {
                accountVM.errorMessage = L10n.authResetNeedsEmail(lang)
                return
            }
            Task {
                await accountVM.sendPasswordReset(
                    email: address,
                    confirmation: L10n.authResetEmailSent(lang)
                )
            }
        } label: {
            Text(L10n.authForgotPassword(appState.appLanguage))
                .font(.footnote.weight(.medium))
                .foregroundColor(Theme.textSecondary)
        }
    }

    private var switchModeButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                mode = (mode == .signIn) ? .signUp : .signIn
                accountVM.errorMessage = nil
            }
        } label: {
            Text(mode == .signIn
                 ? L10n.accountSwitchToSignUp(appState.appLanguage)
                 : L10n.accountSwitchToSignIn(appState.appLanguage))
                .font(.footnote.weight(.medium))
                .foregroundColor(Theme.accent)
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        switch mode {
        case .signIn:
            return email.contains("@") && password.count >= 6
        case .signUp:
            return email.contains("@") && password.count >= 6
                && UsernameRule.isValid(username)
        }
    }

    private func submit() {
        focused = nil
        Task {
            switch mode {
            case .signIn:
                await accountVM.signIn(email: email, password: password)
            case .signUp:
                await accountVM.signUp(
                    email: email,
                    password: password,
                    username: username,
                    displayName: displayName
                )
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) { content() }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .shadow(color: Theme.shadowColor.opacity(0.4),
                    radius: 8, x: 0, y: 4)
    }

    private func field(_ title: String,
                       systemImage: String,
                       text: Binding<String>,
                       focus: Field,
                       hint: String? = nil,
                       autocaps: Bool = false,
                       isEmail: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.accent)
                    .frame(width: 22)
                TextField(title, text: text)
                    .textFieldStyle(.plain)
                    .foregroundColor(Theme.textPrimary)
                    .textInputAutocapitalization(autocaps ? .words : .never)
                    .autocorrectionDisabled()
                    .keyboardType(isEmail ? .emailAddress : .default)
                    .focused($focused, equals: focus)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.background)
            )
            if let hint {
                Text(hint)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.leading, 4)
            }
        }
    }

    private func secureField(_ title: String,
                             systemImage: String,
                             text: Binding<String>,
                             focus: Field) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14))
                .foregroundColor(Theme.accent)
                .frame(width: 22)
            SecureField(title, text: text)
                .textFieldStyle(.plain)
                .foregroundColor(Theme.textPrimary)
                .focused($focused, equals: focus)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.background)
        )
    }
}
