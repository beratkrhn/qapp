//
//  NudgePickerView.swift
//  DeenApp
//
//  Sheet, das einem Freund per Push einen Anstupser zu einem Ziel schickt.
//  Die Vorschläge werden aus dem Goal abgeleitet (Khatma, Tagesseiten,
//  Pflichtgebete oder Sunnah).
//

import SwiftUI

struct NudgePickerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountVM: AccountViewModel
    @Environment(\.dismiss) private var dismiss

    let recipient: FriendInfo
    let goal: Goal

    @State private var sending = false
    @State private var resultMessage: String?
    @State private var isError = false

    private var messages: [String] {
        Self.suggestedMessages(for: goal, language: appState.appLanguage)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        recipientHeader
                        ForEach(messages, id: \.self) { msg in
                            messageButton(msg)
                        }
                        if let resultMessage {
                            Text(resultMessage)
                                .font(.footnote)
                                .foregroundColor(isError ? Theme.destructive : Theme.accent)
                                .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(L10n.nudgePickMessage(appState.appLanguage))
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
                    Text(goal.title(language: appState.appLanguage))
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }
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
        guard !sending, let me = accountVM.account else { return }
        sending = true
        resultMessage = nil
        let lang = appState.appLanguage
        let title = "Akh-ira"
        let recipientUid = recipient.id
        let recipientName = recipient.visibleName
        let goalType = goal.type
        Task {
            do {
                // `send` wartet auf das Ergebnis der Cloud Function — erst
                // danach steht fest, ob die Push wirklich rausging.
                let delivery = try await NudgeService.shared.send(
                    toRecipientUid: recipientUid,
                    sender: me,
                    title: title,
                    body: message,
                    goalType: goalType
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

    // MARK: - Suggestions

    static func suggestedMessages(for goal: Goal, language: AppLanguage) -> [String] {
        switch goal.type {
        case .fivePrayersDaily:
            return FardPrayer.allCases.map { p in
                L10n.nudgeMsgPrayer(language, prayerName: p.localizedName(language: language))
            }
        case .dailyQuranPages:
            let pages = goal.dailyPagesTarget ?? 5
            return [L10n.nudgeMsgPages(language, pages: pages)]
        case .khatmByDate:
            return [L10n.nudgeMsgKhatma(language)]
        case .sunnahPrayer:
            let name = goal.sunnahKind?.localizedName(language: language)
                ?? L10n.goalTypeSunnah(language)
            return [L10n.nudgeMsgSunnah(language, prayerName: name)]
        }
    }
}
