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
    @State private var showResetAlert = false
    @State private var pdfExportURL: URL?
    @State private var showWordStatusList = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Theme.sectionSpacing) {
                    progressSection
                    statsRow
                    Divider()
                        .background(Theme.textSecondary.opacity(0.2))
                    actionButtons
                    exportPdfSection
                        .padding(.top, 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 140)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(L10n.tabLernen(appState.appLanguage))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showResetAlert = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.body.weight(.semibold))
                            .foregroundColor(Theme.textSecondary)
                            .padding(8)
                            .background(Circle().fill(Theme.cardBackground))
                    }
                }
            }
            .alert("Fortschritt zurücksetzen?",
                   isPresented: $showResetAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Zurücksetzen", role: .destructive) {
                    srsViewModel.resetProgress()
                }
            } message: {
                Text("Bist du dir sicher dass du deinen Fortschritt zurücksetzen willst?")
            }
            .navigationDestination(item: $activeSessionType) { type in
                FlashcardSessionView(sessionType: type)
            }
            .fullScreenCover(isPresented: $showWordStatusList) {
                WordStatusListView()
                    .environment(srsViewModel)
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 22) {
            // Gesamter Quran (nach Vorkommen gelernt vs. ~77.800)
            VStack(spacing: 14) {
                Text("Quran insgesamt")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                ZStack {
                    CircularProgressRing(progress: min(max(srsViewModel.quranProgressPercent / 100, 0), 1))
                        .frame(width: 190, height: 190)

                    VStack(spacing: 6) {
                        Text("\(Int(srsViewModel.quranProgressPercent.rounded()))%")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        Text("Vorkommen")
                            .font(.caption.weight(.medium))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.5)
                    }
                }
            }

            // Deck „QWords“ — getrennt vom Gesamt-Quran
            VStack(alignment: .leading, spacing: 10) {
                Text("Deck-Fortschritt")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Karten")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                    Text("\(srsViewModel.graduatedCount) / \(srsViewModel.deckCardCount)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(Int(srsViewModel.deckProgressPercentByCards.rounded())) %")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Theme.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .fill(Theme.cardBackground)
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - PDF Export

    private var exportPdfSection: some View {
        Group {
            if let url = pdfExportURL {
                ShareLink(
                    item: url,
                    subject: Text("My Learned Quran Words"),
                    message: Text("PDF export from DailyDeen"),
                    preview: SharePreview("My Learned Quran Words", icon: Image(systemName: "doc.fill"))
                ) {
                    exportPdfLabel
                }
            } else {
                Button {
                    guard !srsViewModel.graduatedCards.isEmpty else { return }
                    pdfExportURL = try? PDFGenerator.generateLearnedWordsPDF(cards: srsViewModel.graduatedCards)
                } label: {
                    exportPdfLabel
                }
                .disabled(srsViewModel.graduatedCards.isEmpty)
            }
        }
        .onChange(of: srsViewModel.graduatedCount) { _, _ in
            pdfExportURL = nil
        }
    }

    private var exportPdfLabel: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.and.arrow.up")
                .font(.headline)
            Text("Export Learned Words (PDF)")
                .font(.headline)
        }
        .foregroundColor(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.accent)
        )
        .shadow(color: Theme.accent.opacity(0.35), radius: 8, x: 0, y: 4)
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
                count: srsViewModel.reviewableLearnedCount,
                countLabel: "Gelernt"
            ) {
                activeSessionType = .reviewOnly
            }
            .disabled(srsViewModel.reviewableLearnedCount == 0)

            SessionActionButton(
                title: "Alle Wörter anzeigen",
                icon: "list.bullet.rectangle",
                count: srsViewModel.deckCardCount,
                countLabel: "Gesamt"
            ) {
                showWordStatusList = true
            }
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
                .stroke(Theme.cardBackground, lineWidth: 15)

            // Fill — gradient starts and ends on the same color so the ring is
            // seamless at any trim value; the round lineCap gives a smooth endpoint.
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: Theme.accent,              location: 0.0),
                            .init(color: Theme.accent.opacity(0.65), location: 0.5),
                            .init(color: Theme.accent,              location: 1.0),
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round)
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
