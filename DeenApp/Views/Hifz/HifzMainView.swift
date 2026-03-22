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
    @State private var selectedSurah: SurahEntry = SurahEntry.all[0]
    @State private var showPicker = false

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose a Surah")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)

                Button {
                    showPicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedSurah.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("Surah \(selectedSurah.number)")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                Button("Begin Session") {
                    onSelect(selectedSurah.number)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .sheet(isPresented: $showPicker) {
            SurahListSheet(selected: $selectedSurah)
        }
    }
}

// MARK: - Surah List Sheet

private struct SurahListSheet: View {
    @Binding var selected: SurahEntry
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [SurahEntry] {
        searchText.isEmpty
            ? SurahEntry.all
            : SurahEntry.all.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                "\($0.number)".contains(searchText)
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                List(filtered) { surah in
                    Button {
                        selected = surah
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Text("\(surah.number)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 28, alignment: .trailing)

                            Text(surah.name)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()

                            if surah.number == selected.number {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.cardBackground)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search Surah…")
            }
            .navigationTitle("Select Surah")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

// MARK: - Surah Data

private struct SurahEntry: Identifiable {
    let id: Int
    var number: Int { id }
    let name: String

    static let all: [SurahEntry] = [
        SurahEntry(id: 1,   name: "Al-Fatihah"),
        SurahEntry(id: 2,   name: "Al-Baqarah"),
        SurahEntry(id: 3,   name: "Ali 'Imran"),
        SurahEntry(id: 4,   name: "An-Nisa"),
        SurahEntry(id: 5,   name: "Al-Ma'idah"),
        SurahEntry(id: 6,   name: "Al-An'am"),
        SurahEntry(id: 7,   name: "Al-A'raf"),
        SurahEntry(id: 8,   name: "Al-Anfal"),
        SurahEntry(id: 9,   name: "At-Tawbah"),
        SurahEntry(id: 10,  name: "Yunus"),
        SurahEntry(id: 11,  name: "Hud"),
        SurahEntry(id: 12,  name: "Yusuf"),
        SurahEntry(id: 13,  name: "Ar-Ra'd"),
        SurahEntry(id: 14,  name: "Ibrahim"),
        SurahEntry(id: 15,  name: "Al-Hijr"),
        SurahEntry(id: 16,  name: "An-Nahl"),
        SurahEntry(id: 17,  name: "Al-Isra"),
        SurahEntry(id: 18,  name: "Al-Kahf"),
        SurahEntry(id: 19,  name: "Maryam"),
        SurahEntry(id: 20,  name: "Ta-Ha"),
        SurahEntry(id: 21,  name: "Al-Anbiya"),
        SurahEntry(id: 22,  name: "Al-Hajj"),
        SurahEntry(id: 23,  name: "Al-Mu'minun"),
        SurahEntry(id: 24,  name: "An-Nur"),
        SurahEntry(id: 25,  name: "Al-Furqan"),
        SurahEntry(id: 26,  name: "Ash-Shu'ara"),
        SurahEntry(id: 27,  name: "An-Naml"),
        SurahEntry(id: 28,  name: "Al-Qasas"),
        SurahEntry(id: 29,  name: "Al-Ankabut"),
        SurahEntry(id: 30,  name: "Ar-Rum"),
        SurahEntry(id: 31,  name: "Luqman"),
        SurahEntry(id: 32,  name: "As-Sajdah"),
        SurahEntry(id: 33,  name: "Al-Ahzab"),
        SurahEntry(id: 34,  name: "Saba"),
        SurahEntry(id: 35,  name: "Fatir"),
        SurahEntry(id: 36,  name: "Ya-Sin"),
        SurahEntry(id: 37,  name: "As-Saffat"),
        SurahEntry(id: 38,  name: "Sad"),
        SurahEntry(id: 39,  name: "Az-Zumar"),
        SurahEntry(id: 40,  name: "Ghafir"),
        SurahEntry(id: 41,  name: "Fussilat"),
        SurahEntry(id: 42,  name: "Ash-Shura"),
        SurahEntry(id: 43,  name: "Az-Zukhruf"),
        SurahEntry(id: 44,  name: "Ad-Dukhan"),
        SurahEntry(id: 45,  name: "Al-Jathiyah"),
        SurahEntry(id: 46,  name: "Al-Ahqaf"),
        SurahEntry(id: 47,  name: "Muhammad"),
        SurahEntry(id: 48,  name: "Al-Fath"),
        SurahEntry(id: 49,  name: "Al-Hujurat"),
        SurahEntry(id: 50,  name: "Qaf"),
        SurahEntry(id: 51,  name: "Adh-Dhariyat"),
        SurahEntry(id: 52,  name: "At-Tur"),
        SurahEntry(id: 53,  name: "An-Najm"),
        SurahEntry(id: 54,  name: "Al-Qamar"),
        SurahEntry(id: 55,  name: "Ar-Rahman"),
        SurahEntry(id: 56,  name: "Al-Waqi'ah"),
        SurahEntry(id: 57,  name: "Al-Hadid"),
        SurahEntry(id: 58,  name: "Al-Mujadila"),
        SurahEntry(id: 59,  name: "Al-Hashr"),
        SurahEntry(id: 60,  name: "Al-Mumtahanah"),
        SurahEntry(id: 61,  name: "As-Saf"),
        SurahEntry(id: 62,  name: "Al-Jumu'ah"),
        SurahEntry(id: 63,  name: "Al-Munafiqun"),
        SurahEntry(id: 64,  name: "At-Taghabun"),
        SurahEntry(id: 65,  name: "At-Talaq"),
        SurahEntry(id: 66,  name: "At-Tahrim"),
        SurahEntry(id: 67,  name: "Al-Mulk"),
        SurahEntry(id: 68,  name: "Al-Qalam"),
        SurahEntry(id: 69,  name: "Al-Haqqah"),
        SurahEntry(id: 70,  name: "Al-Ma'arij"),
        SurahEntry(id: 71,  name: "Nuh"),
        SurahEntry(id: 72,  name: "Al-Jinn"),
        SurahEntry(id: 73,  name: "Al-Muzzammil"),
        SurahEntry(id: 74,  name: "Al-Muddaththir"),
        SurahEntry(id: 75,  name: "Al-Qiyamah"),
        SurahEntry(id: 76,  name: "Al-Insan"),
        SurahEntry(id: 77,  name: "Al-Mursalat"),
        SurahEntry(id: 78,  name: "An-Naba"),
        SurahEntry(id: 79,  name: "An-Nazi'at"),
        SurahEntry(id: 80,  name: "Abasa"),
        SurahEntry(id: 81,  name: "At-Takwir"),
        SurahEntry(id: 82,  name: "Al-Infitar"),
        SurahEntry(id: 83,  name: "Al-Mutaffifin"),
        SurahEntry(id: 84,  name: "Al-Inshiqaq"),
        SurahEntry(id: 85,  name: "Al-Buruj"),
        SurahEntry(id: 86,  name: "At-Tariq"),
        SurahEntry(id: 87,  name: "Al-A'la"),
        SurahEntry(id: 88,  name: "Al-Ghashiyah"),
        SurahEntry(id: 89,  name: "Al-Fajr"),
        SurahEntry(id: 90,  name: "Al-Balad"),
        SurahEntry(id: 91,  name: "Ash-Shams"),
        SurahEntry(id: 92,  name: "Al-Layl"),
        SurahEntry(id: 93,  name: "Ad-Duha"),
        SurahEntry(id: 94,  name: "Ash-Sharh"),
        SurahEntry(id: 95,  name: "At-Tin"),
        SurahEntry(id: 96,  name: "Al-Alaq"),
        SurahEntry(id: 97,  name: "Al-Qadr"),
        SurahEntry(id: 98,  name: "Al-Bayyinah"),
        SurahEntry(id: 99,  name: "Az-Zalzalah"),
        SurahEntry(id: 100, name: "Al-Adiyat"),
        SurahEntry(id: 101, name: "Al-Qari'ah"),
        SurahEntry(id: 102, name: "At-Takathur"),
        SurahEntry(id: 103, name: "Al-Asr"),
        SurahEntry(id: 104, name: "Al-Humazah"),
        SurahEntry(id: 105, name: "Al-Fil"),
        SurahEntry(id: 106, name: "Quraysh"),
        SurahEntry(id: 107, name: "Al-Ma'un"),
        SurahEntry(id: 108, name: "Al-Kawthar"),
        SurahEntry(id: 109, name: "Al-Kafirun"),
        SurahEntry(id: 110, name: "An-Nasr"),
        SurahEntry(id: 111, name: "Al-Masad"),
        SurahEntry(id: 112, name: "Al-Ikhlas"),
        SurahEntry(id: 113, name: "Al-Falaq"),
        SurahEntry(id: 114, name: "An-Nas"),
    ]
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
