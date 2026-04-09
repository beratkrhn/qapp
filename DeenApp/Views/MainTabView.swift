//
//  MainTabView.swift
//  DeenApp
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State private var srsViewModel = SRSViewModel()
    @State private var prayerTutorialViewModel = PrayerTutorialViewModel()
    @State private var showSettings = false

    // Shown exactly once after the user completes onboarding.
    @AppStorage("hasSeenDisclaimer") private var hasSeenDisclaimer = false
    @State private var showDisclaimer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background
                .ignoresSafeArea()

            Group {
                switch appState.selectedTab {
                case .start:
                    DashboardView(showSettings: $showSettings)
                case .quran:
                    QuranView()
                case .lernen:
                    LearnTabView()
                        .environment(srsViewModel)
                case .gebet:
                    PrayerSelectionView()
                        .environment(prayerTutorialViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBarView()
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            if !hasSeenDisclaimer {
                showDisclaimer = true
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showDisclaimer, onDismiss: { hasSeenDisclaimer = true }) {
            DisclaimerSheetView()
        }
    }
}

// MARK: - Disclaimer Sheet

private struct DisclaimerSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Icon ────────────────────────────────────────────────────────
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 40)
                    .padding(.bottom, 20)

                // ── Title ───────────────────────────────────────────────────────
                Text("Beta-Hinweis")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.bottom, 20)

                // ── Body ────────────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 14) {
                    Text(
                        "Diese App befindet sich noch in der Entwicklung. " +
                        "Bitte verlasse dich nicht zu 100 % auf die Angaben der App, " +
                        "insbesondere bezüglich der Gebetszeiten."
                    )
                    Text(
                        "Fehler können immer vorkommen. " +
                        "Es ist daher empfehlenswert, die Zeiten noch einmal gegenzuprüfen."
                    )
                    Text("wAllahu a3lam")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 28)

                Spacer()

                // ── Dismiss button ───────────────────────────────────────────────
                Button {
                    dismiss()
                } label: {
                    Text("Verstanden")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
}

#Preview {
    MainTabView()
        .environmentObject(PrayerTimeManager())
        .environmentObject(AppState())
}
