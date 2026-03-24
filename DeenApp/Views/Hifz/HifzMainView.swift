// DeenApp/Views/Hifz/HifzMainView.swift
//
// Root view for the Hifz feature (nested under Learn tab).
// Presents surah selection when idle, then a full-page Ayah reader
// with audio playback, navigation, eye toggle, and loop controls.

import SwiftUI
import SwiftData

struct HifzMainView: View {

    @StateObject private var viewModel: HifzViewModel
    let onBack: () -> Void

    init(modelContext: ModelContext, onBack: @escaping () -> Void) {
        self.onBack = onBack
        let audio = HifzAudioService()
        _viewModel = StateObject(wrappedValue: HifzViewModel(
            audioService: audio,
            modelContext: modelContext
        ))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if viewModel.isInSession {
                sessionView
            } else if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else {
                idleView
            }
        }
    }

    // MARK: - Idle (Surah Picker)

    private var idleView: some View {
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {
                idleHeader

                SurahPickerCard { number, name in
                    viewModel.startSession(surahNumber: number, surahName: name)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 120)
        }
    }

    private var idleHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("Learn")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(Theme.accent)
                }
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hifz Mode")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)
                    Text("Memorise the Quran, Ayah by Ayah")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    // MARK: - Session View

    private var sessionView: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

            phaseIndicator
                .padding(.top, 4)
                .padding(.bottom, 2)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(viewModel.allAyat.enumerated()), id: \.element.id) { index, ayah in
                            HifzCardView(
                                ayah: ayah,
                                isActive: index == viewModel.playingAyahIndex,
                                isTextHidden: viewModel.isTextHidden
                            )
                            .id(ayah.id)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    viewModel.jumpToAyah(at: index)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
                .onChange(of: viewModel.playingAyahIndex) { _, newIndex in
                    guard let ayah = viewModel.allAyat[safe: newIndex] else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(ayah.id, anchor: .center)
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            bottomPill
                .padding(.horizontal, 40)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Phase Indicator

    private var phaseIndicator: some View {
        HStack(spacing: 10) {
            Image(systemName: viewModel.phaseDisplayIcon)
                .font(.caption2)
                .foregroundStyle(Theme.accent)

            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.phaseDisplayLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)

                if let range = viewModel.connectRangeLabel {
                    Text(range)
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i <= viewModel.phaseRepeatCount
                              ? Theme.accent
                              : Theme.textSecondary.opacity(0.3))
                        .frame(width: 7, height: 7)
                        .animation(.spring(response: 0.3), value: viewModel.phaseRepeatCount)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBackground.opacity(0.7))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.endSession()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.cardBackground))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.surahName)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text("Ayah \(viewModel.currentAyahIndex + 1) / \(viewModel.totalAyahCount)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
            }

            revelationBadge

            Spacer()

            playPauseButton
        }
    }

    private var revelationBadge: some View {
        Text(SurahMetadata.revelationType(for: viewModel.surahNumber))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(Theme.accent.opacity(0.12))
            )
    }

    private var playPauseButton: some View {
        Button(action: { viewModel.togglePlayPause() }) {
            ZStack {
                Circle()
                    .stroke(Theme.textSecondary.opacity(0.2), lineWidth: 3)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: viewModel.playbackProgress)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: viewModel.playbackProgress)

                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    // MARK: - Bottom Floating Pill

    private var bottomPill: some View {
        HStack(spacing: 28) {
            Button(action: { viewModel.goToPreviousAyah() }) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(viewModel.canGoPrevious ? Theme.textPrimary : Theme.textSecondary.opacity(0.3))
            }
            .disabled(!viewModel.canGoPrevious)

            Button(action: { viewModel.toggleTextVisibility() }) {
                Image(systemName: viewModel.isTextHidden ? "eye.slash" : "eye")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(viewModel.isTextHidden ? Theme.accent : Theme.textPrimary)
            }

            Button(action: { viewModel.toggleLoop() }) {
                Image(systemName: "repeat")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(viewModel.isLooping ? Theme.accent : Theme.textPrimary)
                    .overlay(alignment: .topTrailing) {
                        if viewModel.isLooping {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 6, height: 6)
                                .offset(x: 2, y: -2)
                        }
                    }
            }

            Button(action: { viewModel.goToNextAyah() }) {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(viewModel.canGoNext ? Theme.textPrimary : Theme.textSecondary.opacity(0.3))
            }
            .disabled(!viewModel.canGoNext)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(Theme.accent.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Theme.shadowColor, radius: 16, x: 0, y: 8)
        )
    }

    // MARK: - Loading / Error

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Theme.accent)
                .scaleEffect(1.2)
            Text("Loading Surah…")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Retry") {
                viewModel.endSession()
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 160)
        }
    }
}

// MARK: - Surah Metadata

private enum SurahMetadata {
    static let medinanSurahs: Set<Int> = [
        2, 3, 4, 5, 8, 9, 22, 24, 33, 47, 48, 49,
        55, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 76, 98, 110
    ]

    static func revelationType(for surahNumber: Int) -> String {
        medinanSurahs.contains(surahNumber) ? "Medinan" : "Meccan"
    }
}

// MARK: - Surah Picker Card

private struct SurahPickerCard: View {
    let onSelect: (Int, String) -> Void
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
                    onSelect(selectedSurah.number, selectedSurah.name)
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
