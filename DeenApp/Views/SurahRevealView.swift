// DeenApp/Views/SurahRevealView.swift
//
// Progressive-reveal Surah memorisation tool.
// Select a Surah, set a starting point (Ayah number or Mushaf page),
// then reveal / hide Ayat one at a time with the arrow buttons.

import SwiftUI
import UIKit
import AVFoundation

// MARK: - Reciter

private struct ReciterOption: Identifiable, Equatable {
    let id: String      // everyayah.com folder name
    let name: String

    func audioURL(surah: Int, ayah: Int) -> URL? {
        let file = String(format: "%03d%03d.mp3", surah, ayah)
        return URL(string: "https://everyayah.com/data/\(id)/\(file)")
    }

    static let all: [ReciterOption] = [
        ReciterOption(id: "Alafasy_128kbps",              name: "Mishary Alafasy"),
        ReciterOption(id: "Maher_AlMuaiqly_128kbps",      name: "Maher Al-Muaiqly"),
        ReciterOption(id: "Abdul_Basit_Murattal_128kbps", name: "Abdul Basit"),
        ReciterOption(id: "Husary_128kbps",               name: "Mahmoud Khalil Al-Husary"),
    ]
}

// MARK: - Start Mode

private enum RevealStartMode: String, CaseIterable {
    case byAyah = "From Ayah"
    case byPage = "From Page"
}

// MARK: - Root View

struct SurahRevealView: View {
    let onBack: () -> Void

    @StateObject private var store = QuranStore()

    // Selection state
    @State private var selectedEntry: SurahRevealEntry = SurahRevealEntry.all[0]
    @State private var startMode: RevealStartMode = .byAyah
    @State private var startAyahInput: String = ""
    @State private var startPageInput: String = ""
    @State private var showSurahPicker = false
    @State private var isStarting = false

    // Session state
    @State private var isInSession = false
    @State private var revealedCount: Int = 0
    @State private var surahSliderValue: Double = 1

    // Audio state
    @State private var selectedReciter: ReciterOption? = nil
    @State private var showReciterPicker = false
    @State private var audioPlayer: AVPlayer? = nil

    private var verses: [QuranVerse] { store.currentSuraVerses }
    private var totalVerses: Int { verses.count }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if isInSession {
                sessionView
            } else {
                selectionView
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isInSession)
    }

    // MARK: - Selection View

    private var selectionView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                selectionHeader

                CardContainer {
                    VStack(alignment: .leading, spacing: 20) {

                        // Surah picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Surah")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textSecondary)

                            Button { showSurahPicker = true } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(selectedEntry.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Theme.textPrimary)
                                        Text("Surah \(selectedEntry.number)")
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
                        }

                        // Starting point picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Starting Point")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textSecondary)

                            Picker("", selection: $startMode) {
                                ForEach(RevealStartMode.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.segmented)

                            if startMode == .byAyah {
                                RevealTextField(
                                    placeholder: "Ayah number (default: 1)",
                                    text: $startAyahInput
                                )
                                Text("Ayat before the given number are pre-revealed.")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            } else {
                                RevealTextField(
                                    placeholder: "Page number (1–604)",
                                    text: $startPageInput
                                )
                                Text("All ayat before the first ayah on that page are pre-revealed.")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }

                        // Start button
                        if isStarting {
                            HStack {
                                Spacer()
                                ProgressView().tint(Theme.accent)
                                Spacer()
                            }
                            .frame(height: 48)
                        } else {
                            Button("Start Session") { handleStart() }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.accent)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 120)
        }
        .sheet(isPresented: $showSurahPicker) {
            SurahRevealListSheet(selected: $selectedEntry)
        }
    }

    private var selectionHeader: some View {
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
                    Text("Surah Reveal")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)
                    Text("Reveal Ayat one by one to memorise")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "eye.slash.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    // MARK: - Start Session

    private func handleStart() {
        if startMode == .byAyah {
            let ayah = max(1, Int(startAyahInput) ?? 1)
            revealedCount = ayah - 1
            surahSliderValue = Double(selectedEntry.number)
            store.selectSura(selectedEntry.number)
            withAnimation { isInSession = true }
        } else {
            let page = max(1, min(604, Int(startPageInput) ?? 1))
            isStarting = true
            Task {
                await store.loadMushafPage(page)

                if let mushafPage = store.mushafPageCache[page],
                   let firstAyah = mushafPage.ayahs.first {
                    let surahNum = firstAyah.suraNumber
                    let ayahNum  = firstAyah.numberInSurah
                    if let entry = SurahRevealEntry.all.first(where: { $0.number == surahNum }) {
                        selectedEntry = entry
                    }
                    surahSliderValue = Double(surahNum)
                    revealedCount = max(0, ayahNum - 1)
                    store.selectSura(surahNum)
                } else {
                    let surahNum = QuranStore.surahFirstPage
                        .filter { $0.value <= page }
                        .max(by: { $0.key < $1.key })?.key ?? 1
                    if let entry = SurahRevealEntry.all.first(where: { $0.number == surahNum }) {
                        selectedEntry = entry
                    }
                    surahSliderValue = Double(surahNum)
                    revealedCount = 0
                    store.selectSura(surahNum)
                }

                isStarting = false
                withAnimation { isInSession = true }
            }
        }
    }

    // MARK: - Session View

    private var sessionView: some View {
        VStack(spacing: 0) {
            sessionTopBar
            surahSliderBar
            contentArea
        }
        .overlay(alignment: .bottom) {
            revealNavigationBar
                .padding(.bottom, 90)
        }
        // Auto-play the last revealed ayah when count increases; stop on hide.
        .onChange(of: revealedCount) { _, newCount in
            guard newCount > 0, let reciter = selectedReciter else {
                if selectedReciter != nil { audioPlayer?.pause() }
                return
            }
            let verse = verses[newCount - 1]
            playAudio(surah: verse.suraNumber, ayah: verse.verseNumber, reciter: reciter)
        }
        // Stop audio when reciter changes.
        .onChange(of: selectedReciter) { _, _ in
            audioPlayer?.pause()
            audioPlayer = nil
        }
        // Stop when leaving session.
        .onChange(of: isInSession) { _, active in
            if !active { audioPlayer?.pause(); audioPlayer = nil }
        }
        .sheet(isPresented: $showReciterPicker) {
            reciterPickerSheet
        }
    }

    private func playAudio(surah: Int, ayah: Int, reciter: ReciterOption) {
        audioPlayer?.pause()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        guard let url = reciter.audioURL(surah: surah, ayah: ayah) else { return }
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()
    }

    // MARK: - Reciter Picker Sheet

    private var reciterPickerSheet: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    // Off option
                    Button {
                        selectedReciter = nil
                        showReciterPicker = false
                    } label: {
                        HStack {
                            Image(systemName: "speaker.slash")
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 24)
                            Text("Off")
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if selectedReciter == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accent)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .listRowBackground(Theme.cardBackground)

                    ForEach(ReciterOption.all) { reciter in
                        Button {
                            selectedReciter = reciter
                            showReciterPicker = false
                        } label: {
                            HStack {
                                Image(systemName: "person.wave.2")
                                    .foregroundStyle(Theme.textSecondary)
                                    .frame(width: 24)
                                Text(reciter.name)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if selectedReciter == reciter {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.accent)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .listRowBackground(Theme.cardBackground)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Reciter")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    // MARK: - Session Top Bar

    private var sessionTopBar: some View {
        HStack(spacing: 12) {
            Button {
                store.clearSuraSelection()
                withAnimation { isInSession = false }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.cardBackground))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedEntry.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                if totalVerses > 0 {
                    Text("\(revealedCount) / \(totalVerses) revealed")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            // Reset to ayah 1
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { revealedCount = 0 }
                audioPlayer?.pause()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(revealedCount > 0 ? Theme.accent : Theme.textSecondary.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.cardBackground))
            }
            .disabled(revealedCount == 0)

            // Reciter picker
            Button { showReciterPicker = true } label: {
                Image(systemName: selectedReciter == nil ? "speaker.slash" : "speaker.wave.2")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(selectedReciter == nil ? Theme.textSecondary.opacity(0.5) : Theme.accent)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.cardBackground))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: - Surah Slider

    private var surahSliderBar: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Text("1")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)

                Slider(value: $surahSliderValue, in: 1...114, step: 1) { editing in
                    if !editing {
                        let num = Int(surahSliderValue)
                        guard num != selectedEntry.number else { return }
                        if let entry = SurahRevealEntry.all.first(where: { $0.number == num }) {
                            selectedEntry = entry
                        }
                        revealedCount = 0
                        store.selectSura(num)
                    }
                }
                .tint(Theme.accent)

                Text("114")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }

            Text("Surah \(Int(surahSliderValue)) — \(selectedEntry.name)")
                .font(.caption2)
                .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.cardBackground.opacity(0.6))
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if store.isLoading {
            Spacer()
            VStack(spacing: 12) {
                ProgressView().tint(Theme.accent).scaleEffect(1.2)
                Text("Loading Surah…")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        } else if let error = store.error {
            Spacer()
            Text(error)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    surahHeaderView
                    // Single continuous Mushaf-style text block for all ayahs.
                    // Revealed ayahs show full justified Arabic text + marker.
                    // Hidden ayahs pass "" so only the ﴿N﴾ circle is visible.
                    JustifiedArabicText(
                        segments: mushafSegments,
                        bodyFont: QuranArabicFont.getHafsUIFont(size: 22),
                        markerFont: UIFont.systemFont(ofSize: 15, weight: .medium),
                        tajweedEnabled: false,
                        tajweedCache: [:],
                        readingMode: false
                    )
                    .frame(maxWidth: .infinity)
                    .animation(.easeInOut(duration: 0.2), value: revealedCount)
                }
                .padding(.horizontal, 20)
                // Extra bottom padding: nav bar (88) + tab bar (90) + margin (16)
                .padding(.bottom, 194)
            }
        }
    }

    /// Segments for the single Mushaf text block.
    /// Only verses up to revealedCount + 1 are included:
    ///   – Revealed ayahs: full text + ﴿N﴾ marker
    ///   – The single next-to-reveal ayah: just the ﴿N﴾ marker (empty text)
    ///   – All further hidden ayahs: omitted entirely
    private var mushafSegments: [(text: String, isMarker: Bool, ayahID: Int)] {
        let showUpTo = min(revealedCount + 1, verses.count)
        return verses.prefix(showUpTo).enumerated().flatMap { index, verse -> [(text: String, isMarker: Bool, ayahID: Int)] in
            var rawText = verse.arabic
            // Belt-and-suspenders: ensure verse 1 never contains a bismillah prefix for
            // surahs 2–114 (except 9), even if QuranStore stripping produced no match.
            if index == 0, selectedEntry.number != 1, selectedEntry.number != 9 {
                rawText = Self.stripBismillahPrefix(from: rawText)
            }
            let text = index < revealedCount ? TajweedParser.sanitizePlain(rawText) : ""
            return [
                (text, false, verse.id),
                (" ﴿\(verse.verseNumber)﴾ ", true, -1)
            ]
        }
    }

    /// Strips a leading bismillah from `text` using NFC-normalised prefix matching
    /// so that variant orderings of combining diacritics all resolve correctly.
    private static func stripBismillahPrefix(from text: String) -> String {
        let prefixes = [
            "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
            "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
            "بسم الله الرحمن الرحيم",
        ]
        let nfc = text.precomposedStringWithCanonicalMapping
        for prefix in prefixes {
            let nfcPrefix = prefix.precomposedStringWithCanonicalMapping
            if nfc.hasPrefix(nfcPrefix) {
                // Advance by the prefix character count in the original string.
                let idx = text.index(text.startIndex, offsetBy: prefix.count, limitedBy: text.endIndex) ?? text.endIndex
                return String(text[idx...]).trimmingCharacters(in: .whitespaces)
            }
        }
        return text
    }

    // MARK: - Surah Header (ornamental, like the Mushaf view)

    private var surahHeaderView: some View {
        let arabicName = store.suraList.first { $0.number == selectedEntry.number }?.nameArabic
            ?? selectedEntry.name

        return VStack(spacing: 6) {
            ornamentalRule

            VStack(spacing: 4) {
                Text(arabicName)
                    .font(QuranArabicFont.getHafsFont(size: 24))
                    .foregroundStyle(Theme.accent)
                    .multilineTextAlignment(.center)
                    .environment(\.layoutDirection, .rightToLeft)

                Text(selectedEntry.name)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Theme.accent.opacity(0.25), lineWidth: 0.5)
                    )
            )

            ornamentalRule
        }
        .padding(.vertical, 12)
    }

    // Thin ornamental rule matching the Mushaf view style
    private var ornamentalRule: some View {
        HStack(spacing: 4) {
            Rectangle().frame(height: 0.5).foregroundStyle(Theme.accent.opacity(0.4))
            Circle().frame(width: 4, height: 4).foregroundStyle(Theme.accent.opacity(0.6))
            Circle().frame(width: 3, height: 3).foregroundStyle(Theme.accent.opacity(0.4))
            Circle().frame(width: 4, height: 4).foregroundStyle(Theme.accent.opacity(0.6))
            Rectangle().frame(height: 0.5).foregroundStyle(Theme.accent.opacity(0.4))
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: - Bottom Navigation Bar

    // The bar itself is 88 pt tall. Combined with the .padding(.bottom, 90) applied
    // in the overlay, the visible button content sits just above the tab bar.
    // The .ultraThinMaterial background uses ignoresSafeArea so it seamlessly
    // blends into the area that the tab bar occupies below the buttons.
    private var revealNavigationBar: some View {
        HStack(spacing: 0) {

            // Left arrow — hide last revealed ayah
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if revealedCount > 0 { revealedCount -= 1 }
                }
            } label: {
                VStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 30, weight: .medium))
                    Text("Hide")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(revealedCount > 0
                    ? Theme.textPrimary
                    : Theme.textSecondary.opacity(0.3))
                .frame(maxWidth: .infinity)
                .frame(height: 88)
            }
            .disabled(revealedCount <= 0)

            Rectangle()
                .fill(Theme.textSecondary.opacity(0.15))
                .frame(width: 1, height: 48)

            // Right arrow — reveal next ayah
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if revealedCount < totalVerses { revealedCount += 1 }
                }
            } label: {
                VStack(spacing: 5) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 30, weight: .medium))
                    Text("Reveal")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(revealedCount < totalVerses
                    ? Theme.textPrimary
                    : Theme.textSecondary.opacity(0.3))
                .frame(maxWidth: .infinity)
                .frame(height: 88)
            }
            .disabled(revealedCount >= totalVerses)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.textSecondary.opacity(0.1))
                .frame(height: 1)
        }
    }
}

// MARK: - Text Field Helper

private struct RevealTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .font(.subheadline)
            .foregroundStyle(Theme.textPrimary)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Theme.textSecondary.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Surah List Sheet

private struct SurahRevealListSheet: View {
    @Binding var selected: SurahRevealEntry
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [SurahRevealEntry] {
        searchText.isEmpty
            ? SurahRevealEntry.all
            : SurahRevealEntry.all.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                    || "\($0.number)".contains(searchText)
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

private struct SurahRevealEntry: Identifiable {
    let id: Int
    var number: Int { id }
    let name: String

    static let all: [SurahRevealEntry] = [
        SurahRevealEntry(id: 1,   name: "Al-Fatihah"),
        SurahRevealEntry(id: 2,   name: "Al-Baqarah"),
        SurahRevealEntry(id: 3,   name: "Ali 'Imran"),
        SurahRevealEntry(id: 4,   name: "An-Nisa"),
        SurahRevealEntry(id: 5,   name: "Al-Ma'idah"),
        SurahRevealEntry(id: 6,   name: "Al-An'am"),
        SurahRevealEntry(id: 7,   name: "Al-A'raf"),
        SurahRevealEntry(id: 8,   name: "Al-Anfal"),
        SurahRevealEntry(id: 9,   name: "At-Tawbah"),
        SurahRevealEntry(id: 10,  name: "Yunus"),
        SurahRevealEntry(id: 11,  name: "Hud"),
        SurahRevealEntry(id: 12,  name: "Yusuf"),
        SurahRevealEntry(id: 13,  name: "Ar-Ra'd"),
        SurahRevealEntry(id: 14,  name: "Ibrahim"),
        SurahRevealEntry(id: 15,  name: "Al-Hijr"),
        SurahRevealEntry(id: 16,  name: "An-Nahl"),
        SurahRevealEntry(id: 17,  name: "Al-Isra"),
        SurahRevealEntry(id: 18,  name: "Al-Kahf"),
        SurahRevealEntry(id: 19,  name: "Maryam"),
        SurahRevealEntry(id: 20,  name: "Ta-Ha"),
        SurahRevealEntry(id: 21,  name: "Al-Anbiya"),
        SurahRevealEntry(id: 22,  name: "Al-Hajj"),
        SurahRevealEntry(id: 23,  name: "Al-Mu'minun"),
        SurahRevealEntry(id: 24,  name: "An-Nur"),
        SurahRevealEntry(id: 25,  name: "Al-Furqan"),
        SurahRevealEntry(id: 26,  name: "Ash-Shu'ara"),
        SurahRevealEntry(id: 27,  name: "An-Naml"),
        SurahRevealEntry(id: 28,  name: "Al-Qasas"),
        SurahRevealEntry(id: 29,  name: "Al-Ankabut"),
        SurahRevealEntry(id: 30,  name: "Ar-Rum"),
        SurahRevealEntry(id: 31,  name: "Luqman"),
        SurahRevealEntry(id: 32,  name: "As-Sajdah"),
        SurahRevealEntry(id: 33,  name: "Al-Ahzab"),
        SurahRevealEntry(id: 34,  name: "Saba"),
        SurahRevealEntry(id: 35,  name: "Fatir"),
        SurahRevealEntry(id: 36,  name: "Ya-Sin"),
        SurahRevealEntry(id: 37,  name: "As-Saffat"),
        SurahRevealEntry(id: 38,  name: "Sad"),
        SurahRevealEntry(id: 39,  name: "Az-Zumar"),
        SurahRevealEntry(id: 40,  name: "Ghafir"),
        SurahRevealEntry(id: 41,  name: "Fussilat"),
        SurahRevealEntry(id: 42,  name: "Ash-Shura"),
        SurahRevealEntry(id: 43,  name: "Az-Zukhruf"),
        SurahRevealEntry(id: 44,  name: "Ad-Dukhan"),
        SurahRevealEntry(id: 45,  name: "Al-Jathiyah"),
        SurahRevealEntry(id: 46,  name: "Al-Ahqaf"),
        SurahRevealEntry(id: 47,  name: "Muhammad"),
        SurahRevealEntry(id: 48,  name: "Al-Fath"),
        SurahRevealEntry(id: 49,  name: "Al-Hujurat"),
        SurahRevealEntry(id: 50,  name: "Qaf"),
        SurahRevealEntry(id: 51,  name: "Adh-Dhariyat"),
        SurahRevealEntry(id: 52,  name: "At-Tur"),
        SurahRevealEntry(id: 53,  name: "An-Najm"),
        SurahRevealEntry(id: 54,  name: "Al-Qamar"),
        SurahRevealEntry(id: 55,  name: "Ar-Rahman"),
        SurahRevealEntry(id: 56,  name: "Al-Waqi'ah"),
        SurahRevealEntry(id: 57,  name: "Al-Hadid"),
        SurahRevealEntry(id: 58,  name: "Al-Mujadila"),
        SurahRevealEntry(id: 59,  name: "Al-Hashr"),
        SurahRevealEntry(id: 60,  name: "Al-Mumtahanah"),
        SurahRevealEntry(id: 61,  name: "As-Saf"),
        SurahRevealEntry(id: 62,  name: "Al-Jumu'ah"),
        SurahRevealEntry(id: 63,  name: "Al-Munafiqun"),
        SurahRevealEntry(id: 64,  name: "At-Taghabun"),
        SurahRevealEntry(id: 65,  name: "At-Talaq"),
        SurahRevealEntry(id: 66,  name: "At-Tahrim"),
        SurahRevealEntry(id: 67,  name: "Al-Mulk"),
        SurahRevealEntry(id: 68,  name: "Al-Qalam"),
        SurahRevealEntry(id: 69,  name: "Al-Haqqah"),
        SurahRevealEntry(id: 70,  name: "Al-Ma'arij"),
        SurahRevealEntry(id: 71,  name: "Nuh"),
        SurahRevealEntry(id: 72,  name: "Al-Jinn"),
        SurahRevealEntry(id: 73,  name: "Al-Muzzammil"),
        SurahRevealEntry(id: 74,  name: "Al-Muddaththir"),
        SurahRevealEntry(id: 75,  name: "Al-Qiyamah"),
        SurahRevealEntry(id: 76,  name: "Al-Insan"),
        SurahRevealEntry(id: 77,  name: "Al-Mursalat"),
        SurahRevealEntry(id: 78,  name: "An-Naba"),
        SurahRevealEntry(id: 79,  name: "An-Nazi'at"),
        SurahRevealEntry(id: 80,  name: "Abasa"),
        SurahRevealEntry(id: 81,  name: "At-Takwir"),
        SurahRevealEntry(id: 82,  name: "Al-Infitar"),
        SurahRevealEntry(id: 83,  name: "Al-Mutaffifin"),
        SurahRevealEntry(id: 84,  name: "Al-Inshiqaq"),
        SurahRevealEntry(id: 85,  name: "Al-Buruj"),
        SurahRevealEntry(id: 86,  name: "At-Tariq"),
        SurahRevealEntry(id: 87,  name: "Al-A'la"),
        SurahRevealEntry(id: 88,  name: "Al-Ghashiyah"),
        SurahRevealEntry(id: 89,  name: "Al-Fajr"),
        SurahRevealEntry(id: 90,  name: "Al-Balad"),
        SurahRevealEntry(id: 91,  name: "Ash-Shams"),
        SurahRevealEntry(id: 92,  name: "Al-Layl"),
        SurahRevealEntry(id: 93,  name: "Ad-Duha"),
        SurahRevealEntry(id: 94,  name: "Ash-Sharh"),
        SurahRevealEntry(id: 95,  name: "At-Tin"),
        SurahRevealEntry(id: 96,  name: "Al-Alaq"),
        SurahRevealEntry(id: 97,  name: "Al-Qadr"),
        SurahRevealEntry(id: 98,  name: "Al-Bayyinah"),
        SurahRevealEntry(id: 99,  name: "Az-Zalzalah"),
        SurahRevealEntry(id: 100, name: "Al-Adiyat"),
        SurahRevealEntry(id: 101, name: "Al-Qari'ah"),
        SurahRevealEntry(id: 102, name: "At-Takathur"),
        SurahRevealEntry(id: 103, name: "Al-Asr"),
        SurahRevealEntry(id: 104, name: "Al-Humazah"),
        SurahRevealEntry(id: 105, name: "Al-Fil"),
        SurahRevealEntry(id: 106, name: "Quraysh"),
        SurahRevealEntry(id: 107, name: "Al-Ma'un"),
        SurahRevealEntry(id: 108, name: "Al-Kawthar"),
        SurahRevealEntry(id: 109, name: "Al-Kafirun"),
        SurahRevealEntry(id: 110, name: "An-Nasr"),
        SurahRevealEntry(id: 111, name: "Al-Masad"),
        SurahRevealEntry(id: 112, name: "Al-Ikhlas"),
        SurahRevealEntry(id: 113, name: "Al-Falaq"),
        SurahRevealEntry(id: 114, name: "An-Nas"),
    ]
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
