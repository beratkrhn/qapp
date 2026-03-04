//
//  LearningDashboardView.swift
//  DeenApp
//
//  "Lernen"-Tab: Fortschrittsring, Statistiken, Session-Aktionsschaltflächen.
//

import SwiftUI

// MARK: - Dashboard

struct LearningDashboardView: View {
    @Environment(SRSViewModel.self) private var srsViewModel
    @EnvironmentObject var appState: AppState

    @State private var activeSessionType: LearningSessionType?

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Theme.sectionSpacing) {
                    progressSection
                    statsRow
                    Divider()
                        .background(Theme.textSecondary.opacity(0.2))
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(L10n.tabLernen(appState.appLanguage))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $activeSessionType) { type in
                FlashcardSessionView(sessionType: type)
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 20) {
            ZStack {
                CircularProgressRing(progress: srsViewModel.progressPercent / 100)
                    .frame(width: 190, height: 190)

                VStack(spacing: 6) {
                    Text("\(Int(srsViewModel.progressPercent.rounded()))%")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text("verstanden")
                        .font(.caption.weight(.medium))
                        .foregroundColor(Theme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
            }

            VStack(spacing: 4) {
                Text("Du verstehst bereits \(Int(srsViewModel.progressPercent.rounded()))%!")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("der häufigsten Quran-Wörter")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            LearningStatPill(value: srsViewModel.graduatedCount,
                             label: "Gelernt",
                             accentColor: Theme.accent)
            LearningStatPill(value: srsViewModel.dueCount,
                             label: "Zu wiederholen",
                             accentColor: Color(hex: "FF9800"))
            LearningStatPill(value: srsViewModel.newCount,
                             label: "Neu",
                             accentColor: Theme.textSecondary)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Primary — mixed session (due + new)
            Button {
                activeSessionType = .mixed
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                    Text("Lernen")
                        .font(.headline)
                    Spacer()
                    let total = srsViewModel.dueCount + srsViewModel.newCount
                    if total > 0 {
                        Text("\(total) Karten")
                            .font(.subheadline.weight(.medium))
                            .opacity(0.8)
                    }
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .fill(Theme.accent)
                )
            }
            .shadow(color: Theme.accent.opacity(0.45), radius: 10, x: 0, y: 5)
            .disabled(srsViewModel.dueCount == 0 && srsViewModel.newCount == 0)

            // Secondary — new words only
            SessionActionButton(
                title: "Neue Wörter lernen",
                icon: "sparkles",
                count: srsViewModel.newCount,
                countLabel: "Neu"
            ) {
                activeSessionType = .newOnly
            }
            .disabled(srsViewModel.newCount == 0)

            // Secondary — review only
            SessionActionButton(
                title: "Wiederholen",
                icon: "arrow.clockwise",
                count: srsViewModel.dueCount,
                countLabel: "Fällig"
            ) {
                activeSessionType = .reviewOnly
            }
            .disabled(srsViewModel.dueCount == 0)
        }
    }
}

// MARK: - Circular Progress Ring

struct CircularProgressRing: View {
    let progress: Double    // 0.0 … 1.0

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Theme.cardBackground, lineWidth: 14)

            // Fill
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    AngularGradient(
                        colors: [Theme.accent.opacity(0.65), Theme.accent],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: progress)
        }
        // Glow effect
        .shadow(color: Theme.accent.opacity(0.5), radius: 12, x: 0, y: 0)
    }
}

// MARK: - Stat Pill

struct LearningStatPill: View {
    let value: Int
    let label: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(accentColor)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBackground)
        )
    }
}

// MARK: - Session Action Button (Secondary Style)

struct SessionActionButton: View {
    let title: String
    let icon: String
    let count: Int
    let countLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundColor(Theme.accent)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                if count > 0 {
                    Text("\(count)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Theme.accent.opacity(0.15))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .fill(Theme.cardBackground)
                    .shadow(color: Theme.shadowColor, radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    LearningDashboardView()
        .environment(SRSViewModel())
        .environmentObject(AppState())
}
