//
//  ReminderComposerView.swift
//  DeenApp
//
//  Sheet, das einem Freund eine freie Erinnerung schickt — unabhängig von
//  geteilten Zielen: Pflichtgebete, Qur'an, Dhikr oder eine eigene kurze
//  Nachricht. Versand läuft wie beim Ziel-Anstupser über NudgeService und
//  die Cloud Function (Freundschafts-Check + Tageslimit serverseitig).
//

import SwiftUI

struct ReminderComposerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountVM: AccountViewModel
    @Environment(\.dismiss) private var dismiss

    let recipient: FriendInfo

    @State private var customMessage = ""
    @State private var sending = false
    @State private var resultMessage: String?
    @State private var isError = false
    @FocusState private var customFocused: Bool

    private static let customMessageLimit = 200

    private var prayerMessages: [String] {
        FardPrayer.allCases.map { p in
            L10n.nudgeMsgPrayer(appState.appLanguage,
                                prayerName: p.localizedName(language: appState.appLanguage))
        }
    }

    private var quranMessages: [String] {
        [
            L10n.nudgeMsgQuranGeneric(appState.appLanguage),
            L10n.nudgeMsgDhikr(appState.appLanguage)
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        recipientHeader
                        section(L10n.reminderSectionPrayer(appState.appLanguage),
                                messages: prayerMessages)
                        section(L10n.reminderSectionQuran(appState.appLanguage),
                                messages: quranMessages)
                        customSection
                        if let resultMessage {
                            Text(resultMessage)
                                .font(.footnote)
                                .foregroundColor(isError ? Theme.destructive : Theme.accent)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(L10n.reminderComposerTitle(appState.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.commonCancel(appState.appLanguage)) { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }

    // MARK: - Subviews

    private var recipientHeader: some View {
        CardContainer {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundColor(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipient.visibleName)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Text("@\(recipient.username)")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }
        }
    }

    private func section(_ title: String, messages: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.leading, 4)
            ForEach(messages, id: \.self) { msg in
                messageButton(msg)
            }
        }
    }

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.reminderSectionCustom(appState.appLanguage))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.leading, 4)
            VStack(alignment: .leading, spacing: 10) {
                TextField(L10n.reminderCustomPlaceholder(appState.appLanguage),
                          text: $customMessage,
                          axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.plain)
                    .foregroundColor(Theme.textPrimary)
                    .focused($customFocused)
                    .onChange(of: customMessage) { _, newValue in
                        if newValue.count > Self.customMessageLimit {
                            customMessage = String(newValue.prefix(Self.customMessageLimit))
                        }
                    }
                Button {
                    send(message: customMessage.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    HStack {
                        if sending {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Text(L10n.reminderSend(appState.appLanguage))
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "paperplane.fill")
                            .font(.subheadline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.accent)
                    )
                }
                .buttonStyle(.plain)
                .disabled(sending || customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.cardBackground)
            )
        }
    }

    private func messageButton(_ message: String) -> some View {
        Button {
            send(message: message)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(Theme.accent)
                    .padding(.top, 2)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if sending {
                    ProgressView().tint(Theme.accent)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.subheadline)
                        .foregroundColor(Theme.accent)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.cardBackground)
            )
        }
        .buttonStyle(.plain)
        .disabled(sending)
    }

    // MARK: - Send

    private func send(message: String) {
        guard !sending, !message.isEmpty, let me = accountVM.account else { return }
        sending = true
        resultMessage = nil
        customFocused = false
        let lang = appState.appLanguage
        let recipientUid = recipient.id
        let recipientName = recipient.visibleName
        Task {
            do {
                // `send` wartet auf das Ergebnis der Cloud Function — erst
                // danach steht fest, ob die Push wirklich rausging.
                let delivery = try await NudgeService.shared.send(
                    toRecipientUid: recipientUid,
                    sender: me,
                    title: "Akh-ira",
                    body: message,
                    goalType: nil
                )
                let result = delivery.message(language: lang, recipientName: recipientName)
                resultMessage = result.text
                isError = result.isError
                if !result.isError {
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    dismiss()
                }
            } catch {
                resultMessage = L10n.nudgeFailed(lang)
                isError = true
            }
            sending = false
        }
    }
}
