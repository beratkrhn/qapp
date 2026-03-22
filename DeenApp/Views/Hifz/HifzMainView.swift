// DeenApp/Views/Hifz/HifzMainView.swift
//
// Root view for the Hifz tab. Presents surah selection when idle,
// then delegates to the active session view for all memorisation phases.

import SwiftUI
import SwiftData

struct HifzMainView: View {

    @StateObject private var viewModel: HifzViewModel
    @Query(sort: \DailyActivity.date, order: .reverse) private var activities: [DailyActivity]

    init(modelContext: ModelContext) {
        let audio = HifzAudioService()
        _viewModel = StateObject(wrappedValue: HifzViewModel(
            audioService: audio,
            modelContext: modelContext
        ))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    headerSection
                    heatmapSection
                    sessionSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hifz Mode")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.textPrimary)
                Text("3×3 Memorisation Method")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(Theme.accent)
        }
    }

    // MARK: - Heatmap

    private var heatmapSection: some View {
        ContributionHeatmapView(activities: activities, title: "Your Activity")
    }

    // MARK: - Session

    @ViewBuilder
    private var sessionSection: some View {
        switch viewModel.phase {
        case .idle:
            SurahPickerCard { surahNumber in
                viewModel.startSession(surahNumber: surahNumber)
            }

        case .readAndListen, .activeRecall, .concatenation, .commitToMemory:
            if let chunk = viewModel.currentChunk {
                HifzSessionView(viewModel: viewModel, chunk: chunk)
            }

        case .saving:
            savingView

        case .complete:
            completeView { viewModel.phase = .idle }

        case .error(let msg):
            errorView(message: msg) { viewModel.phase = .idle }
        }
    }

    // MARK: - Terminal State Views

    private var savingView: some View {
        CardContainer {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(Theme.accent)
                Text("Saving progress…")
                    .foregroundStyle(Theme.textSecondary)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func completeView(onContinue: @escaping () -> Void) -> some View {
        CardContainer {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent)

                Text("Block Complete!")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textPrimary)

                Text("Chunk saved for SRS review. Keep going!")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Next Chunk", action: onContinue)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }

    private func errorView(message: String, onRetry: @escaping () -> Void) -> some View {
        CardContainer {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Retry", action: onRetry)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Surah Picker Card

private struct SurahPickerCard: View {
    let onSelect: (Int) -> Void
    @State private var surahNumber: Int = 1

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose a Surah")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)

                HStack {
                    Text("Surah")
                        .foregroundStyle(Theme.textSecondary)
                        .font(.subheadline)

                    Spacer()

                    Stepper("\(surahNumber)", value: $surahNumber, in: 1...114)
                        .labelsHidden()
                        .tint(Theme.accent)

                    Text("\(surahNumber)")
                        .foregroundStyle(Theme.textPrimary)
                        .font(.headline)
                        .frame(minWidth: 32, alignment: .trailing)
                }

                Button("Begin Session") {
                    onSelect(surahNumber)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

// MARK: - Session View (phases 2a / 2b / 3 / 4)

private struct HifzSessionView: View {
    @ObservedObject var viewModel: HifzViewModel
    let chunk: HifzChunk

    var body: some View {
        VStack(spacing: 16) {
            progressHeader
            phaseCard
            actionButtons
        }
    }

    // MARK: Progress Header

    private var progressHeader: some View {
        HStack {
            Label(phaseLabel, systemImage: phaseIcon)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.accent)
            Spacer()
            Text("Surah \(chunk.surahNumber) · Chunk \(chunk.chunkIndex + 1)")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: Phase Card

    @ViewBuilder
    private var phaseCard: some View {
        switch viewModel.phase {

        case .readAndListen(let vi, let count):
            let ayah = chunk.ayat[safe: vi]
            VStack(spacing: 12) {
                verseKeyLabel(ayah?.verseKey)
                HifzCardView(
                    words: ayah?.words ?? [],
                    activeWordID: viewModel.activeWordID,
                    isBlurred: false
                )
                readDots(count: count, total: 3, label: "Read")
            }

        case .activeRecall(let vi, let count):
            let ayah = chunk.ayat[safe: vi]
            VStack(spacing: 12) {
                verseKeyLabel(ayah?.verseKey)
                HifzCardView(
                    words: ayah?.words ?? [],
                    activeWordID: nil,
                    isBlurred: true
                )
                readDots(count: count, total: 3, label: "Recall")
            }

        case .concatenation:
            VStack(spacing: 12) {
                Text("Full Block Review")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                ForEach(chunk.ayat) { ayah in
                    HifzCardView(words: ayah.words, activeWordID: nil, isBlurred: false)
                }
            }

        case .commitToMemory(let count):
            VStack(spacing: 12) {
                Text("Commit to Memory")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                ForEach(chunk.ayat) { ayah in
                    HifzCardView(words: ayah.words, activeWordID: nil, isBlurred: true)
                }
                readDots(count: count, total: 3, label: "Block Recall")
            }

        default:
            EmptyView()
        }
    }

    // MARK: Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch viewModel.phase {

        case .readAndListen:
            VStack(spacing: 10) {
                Button("Play Again") { viewModel.playCurrentVerse() }
                    .buttonStyle(SecondaryButtonStyle())
                Button("I Read It ✓") { viewModel.confirmRead() }
                    .buttonStyle(PrimaryButtonStyle())
            }

        case .activeRecall:
            VStack(spacing: 10) {
                Button("I Recalled It ✓") { viewModel.confirmRecall() }
                    .buttonStyle(PrimaryButtonStyle())
                Button("I Made a Mistake") { viewModel.reportMistake() }
                    .buttonStyle(DestructiveButtonStyle())
            }

        case .concatenation:
            Button("I've Read The Block →") { viewModel.confirmConcatenation() }
                .buttonStyle(PrimaryButtonStyle())

        case .commitToMemory:
            VStack(spacing: 10) {
                Button("I Recalled The Block ✓") { viewModel.confirmBlockRecall() }
                    .buttonStyle(PrimaryButtonStyle())
                Button("I Made a Mistake") { viewModel.reportBlockMistake() }
                    .buttonStyle(DestructiveButtonStyle())
            }

        default:
            EmptyView()
        }
    }

    // MARK: Helpers

    @ViewBuilder
    private func verseKeyLabel(_ key: String?) -> some View {
        if let key {
            Text(key)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func readDots(count: Int, total: Int, label: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            HStack(spacing: 5) {
                ForEach(0..<total, id: \.self) { i in
                    Circle()
                        .fill(i < count ? Theme.accent : Theme.textSecondary.opacity(0.3))
                        .frame(width: 9, height: 9)
                        .animation(.spring(response: 0.3), value: count)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private var phaseLabel: String {
        switch viewModel.phase {
        case .readAndListen:  return "Read & Listen"
        case .activeRecall:   return "Active Recall"
        case .concatenation:  return "Block Review"
        case .commitToMemory: return "Commit to Memory"
        default:              return ""
        }
    }

    private var phaseIcon: String {
        switch viewModel.phase {
        case .readAndListen:  return "ear.fill"
        case .activeRecall:   return "eye.slash.fill"
        case .concatenation:  return "list.bullet"
        case .commitToMemory: return "brain.head.profile"
        default:              return "circle"
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.accent)
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Theme.accent.opacity(0.5), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.red.opacity(0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.red.opacity(0.3), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
