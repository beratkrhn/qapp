//
//  ContinueAyahView.swift
//  DeenApp
//
//  "Continue the Ayah" learning challenge: pick one or more Surahs
//  (or a Juz), then a random verse from that scope is shown and the
//  user has to recite the next one before revealing.
//

import SwiftUI

// MARK: - Scope

private enum ContinueAyahScope: String, CaseIterable, Identifiable {
    case surahs = "By Surah"
    case juz    = "By Juz"
    var id: String { rawValue }
}

// MARK: - Surah → Juz pool

/// Surahs that have any content within each Juz (1–30).
/// Used to expand a Juz selection into a pool of pickable Surahs.
private enum JuzPool {
    static let surahs: [Int: [Int]] = [
        1:  [1, 2],
        2:  [2],
        3:  [2, 3],
        4:  [3, 4],
        5:  [4],
        6:  [4, 5],
        7:  [5, 6],
        8:  [6, 7],
        9:  [7, 8],
        10: [8, 9],
        11: [9, 10, 11],
        12: [11, 12],
        13: [12, 13, 14],
        14: [15, 16],
        15: [17, 18],
        16: [18, 19, 20],
        17: [21, 22],
        18: [23, 24, 25],
        19: [25, 26, 27],
        20: [27, 28, 29],
        21: [29, 30, 31, 32, 33],
        22: [33, 34, 35, 36],
        23: [36, 37, 38, 39],
        24: [39, 40, 41],
        25: [41, 42, 43, 44, 45],
        26: [46, 47, 48, 49, 50, 51],
        27: [51, 52, 53, 54, 55, 56, 57],
        28: [58, 59, 60, 61, 62, 63, 64, 65, 66],
        29: [67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77],
        30: Array(78...114),
    ]
}

// MARK: - Challenge State

private struct ContinueAyahChallenge: Equatable {
    let suraNumber: Int
    let suraName: String        // transliteration
    let suraArabicName: String
    let promptVerseNumber: Int
    let promptArabic: String
    let totalVerses: Int
}

// MARK: - Root View

struct ContinueAyahView: View {
    let onBack: () -> Void

    @StateObject private var store = QuranStore()

    // Selection
    @State private var scope: ContinueAyahScope = .surahs
    @State private var selectedSurahs: Set<Int> = []
    @State private var selectedJuz: Int = 30
    @State private var showSurahPicker = false

    // Session
    @State private var isInSession = false
    @State private var isLoadingChallenge = false
    @State private var challenge: ContinueAyahChallenge?
    @State private var revealNextCount: Int = 0     // how many follow-up ayahs are shown
    @State private var showFullSurahFromPrompt: Bool = false

    // MARK: - Body

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
                        Text("Scope")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)

                        Picker("", selection: $scope) {
                            ForEach(ContinueAyahScope.allCases) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)

                        if scope == .surahs {
                            surahScopeSection
                        } else {
                            juzScopeSection
                        }

                        startButton
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 120)
        }
        .sheet(isPresented: $showSurahPicker) {
            ContinueAyahSurahPickerSheet(selected: $selectedSurahs)
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
                    Text("Continue the Ayah")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)
                    Text("Recite the next ayah from memory")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "text.book.closed.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var surahScopeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showSurahPicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedSurahsLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(selectedSurahs.isEmpty
                             ? "Tap to choose one or more"
                             : "\(selectedSurahs.count) selected")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
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

            Text("A random ayah from the selected surahs is shown.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var selectedSurahsLabel: String {
        if selectedSurahs.isEmpty { return "Select Surahs" }
        let names = selectedSurahs
            .sorted()
            .compactMap { num in ContinueAyahSurahCatalog.all.first(where: { $0.number == num })?.name }
        return names.prefix(3).joined(separator: ", ")
            + (names.count > 3 ? " +\(names.count - 3) more" : "")
    }

    private var juzScopeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Juz \(selectedJuz)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)

            Slider(value: Binding(
                get: { Double(selectedJuz) },
                set: { selectedJuz = Int($0.rounded()) }
            ), in: 1...30, step: 1)
                .tint(Theme.accent)

            HStack {
                Text("1").font(.caption2.monospacedDigit())
                Spacer()
                Text("30").font(.caption2.monospacedDigit())
            }
            .foregroundStyle(Theme.textSecondary)

            Text("A random ayah from any surah within the selected juz.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var startButton: some View {
        Button {
            handleStart()
        } label: {
            Group {
                if isLoadingChallenge {
                    ProgressView().tint(.black)
                } else {
                    Text("Start Challenge")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canStart ? Theme.accent : Theme.accent.opacity(0.35))
            )
        }
        .disabled(!canStart || isLoadingChallenge)
    }

    private var canStart: Bool {
        switch scope {
        case .surahs: return !resolvedSurahPool().isEmpty
        case .juz:    return !resolvedSurahPool().isEmpty
        }
    }

    // MARK: - Resolve Scope → Surah Pool

    private func resolvedSurahPool() -> [Int] {
        switch scope {
        case .surahs:
            return Array(selectedSurahs).filter(suraHasContinuableAyah)
        case .juz:
            let raw = JuzPool.surahs[selectedJuz] ?? []
            return raw.filter(suraHasContinuableAyah)
        }
    }

    /// A surah needs at least 2 ayahs so a "next" ayah exists.
    private func suraHasContinuableAyah(_ number: Int) -> Bool {
        guard let info = ContinueAyahSurahCatalog.all.first(where: { $0.number == number }) else {
            return false
        }
        return info.numberOfAyahs >= 2
    }

    // MARK: - Start / Reroll

    private func handleStart() {
        let pool = resolvedSurahPool()
        guard !pool.isEmpty else { return }
        isLoadingChallenge = true
        Task {
            await loadAndPickChallenge(from: pool)
            await MainActor.run {
                isLoadingChallenge = false
                if challenge != nil {
                    withAnimation { isInSession = true }
                }
            }
        }
    }

    private func nextChallenge() {
        let pool = resolvedSurahPool()
        guard !pool.isEmpty else { return }
        isLoadingChallenge = true
        revealNextCount = 0
        showFullSurahFromPrompt = false
        Task {
            await loadAndPickChallenge(from: pool)
            await MainActor.run { isLoadingChallenge = false }
        }
    }

    private func loadAndPickChallenge(from pool: [Int]) async {
        guard let suraNumber = pool.randomElement() else { return }
        await store.loadSura(suraNumber)
        await MainActor.run {
            let verses = store.currentSuraVerses
            guard verses.count >= 2 else {
                challenge = nil
                return
            }
            // pool of indices that still have a "next" ayah within the same surah
            let candidateIndices = Array(0..<(verses.count - 1))
            guard let idx = candidateIndices.randomElement() else { return }
            let prompt = verses[idx]
            let info = ContinueAyahSurahCatalog.all.first(where: { $0.number == suraNumber })
            challenge = ContinueAyahChallenge(
                suraNumber: suraNumber,
                suraName: info?.name ?? "Surah \(suraNumber)",
                suraArabicName: store.suraList.first(where: { $0.number == suraNumber })?.nameArabic ?? "",
                promptVerseNumber: prompt.verseNumber,
                promptArabic: prompt.arabic,
                totalVerses: verses.count
            )
            revealNextCount = 0
            showFullSurahFromPrompt = false
        }
    }

    // MARK: - Session View

    private var sessionView: some View {
        VStack(spacing: 0) {
            sessionTopBar
            if let c = challenge {
                challengeContent(c)
            } else if isLoadingChallenge {
                Spacer()
                ProgressView().tint(Theme.accent)
                Spacer()
            } else {
                Spacer()
                Text("No challenge available.")
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }
        }
    }

    private var sessionTopBar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation { isInSession = false }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.cardBackground))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Continue the Ayah")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                if let c = challenge {
                    Text("\(c.suraName) — Ayah \(c.promptVerseNumber)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func challengeContent(_ c: ContinueAyahChallenge) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                promptCard(c)

                if showFullSurahFromPrompt {
                    fullSurahCard(c)
                } else if revealNextCount > 0 {
                    revealedNextCard(c)
                }

                actionButtons(c)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 140)
        }
    }

    private func promptCard(_ c: ContinueAyahChallenge) -> some View {
        CardContainer {
            VStack(alignment: .center, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.suraName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                        Text("Ayah \(c.promptVerseNumber) of \(c.totalVerses)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    if !c.suraArabicName.isEmpty {
                        Text(c.suraArabicName)
                            .font(QuranArabicFont.getHafsFont(size: 20))
                            .foregroundStyle(Theme.textPrimary)
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                }

                Divider().background(Theme.textSecondary.opacity(0.2))

                arabicBlock(
                    verses: [(text: c.promptArabic, number: c.promptVerseNumber)],
                    bodySize: 26
                )

                Text("What comes next?")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func revealedNextCard(_ c: ContinueAyahChallenge) -> some View {
        let upcoming = Array(upcomingVerses(for: c).prefix(revealNextCount))
        return CardContainer(useHighlightBackground: true) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Next ayah\(revealNextCount > 1 ? "s" : "")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)

                arabicBlock(
                    verses: upcoming.map { (text: $0.arabic, number: $0.verseNumber) },
                    bodySize: 22
                )
            }
        }
    }

    private func fullSurahCard(_ c: ContinueAyahChallenge) -> some View {
        let rest = upcomingVerses(for: c)
        return CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text("Surah from ayah \(c.promptVerseNumber + 1) onward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)

                arabicBlock(
                    verses: rest.map { (text: $0.arabic, number: $0.verseNumber) },
                    bodySize: 22
                )
            }
        }
    }

    /// Renders a contiguous Mushaf-style Arabic block. Body text uses the KFGQPC Hafs
    /// UIFont via `JustifiedArabicText` (UITextView + CoreText) for correct OpenType
    /// shaping; the ayah-number marker `﴿N﴾` is rendered with the system font as a
    /// separate marker segment, matching the Mushaf screen.
    private func arabicBlock(verses: [(text: String, number: Int)], bodySize: CGFloat) -> some View {
        let segments: [(text: String, isMarker: Bool, ayahID: Int)] = verses.flatMap { v in
            [(v.text, false, -1),
             (" ﴿\(v.number)﴾ ", true, -1)]
        }
        return JustifiedArabicText(
            segments: segments,
            bodyFont: QuranArabicFont.getHafsUIFont(size: bodySize),
            markerFont: UIFont.systemFont(ofSize: max(bodySize - 8, 12), weight: .medium),
            tajweedEnabled: false,
            tajweedCache: [:],
            readingMode: false
        )
        .frame(maxWidth: .infinity)
    }

    private func upcomingVerses(for c: ContinueAyahChallenge) -> [QuranVerse] {
        store.currentSuraVerses
            .filter { $0.suraNumber == c.suraNumber && $0.verseNumber > c.promptVerseNumber }
    }

    private func actionButtons(_ c: ContinueAyahChallenge) -> some View {
        let canRevealMore = revealNextCount < (c.totalVerses - c.promptVerseNumber) && !showFullSurahFromPrompt
        return VStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if showFullSurahFromPrompt { return }
                    revealNextCount += 1
                }
            } label: {
                actionLabel(
                    title: revealNextCount == 0 ? "Reveal Next Ayah" : "Reveal One More",
                    systemImage: "eye.fill",
                    enabled: canRevealMore
                )
            }
            .disabled(!canRevealMore)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFullSurahFromPrompt = true
                    revealNextCount = 0
                }
            } label: {
                actionLabel(
                    title: "Show Full Surah from Here",
                    systemImage: "list.bullet.rectangle",
                    enabled: !showFullSurahFromPrompt
                )
            }
            .disabled(showFullSurahFromPrompt)

            Button {
                nextChallenge()
            } label: {
                actionLabel(
                    title: "Next Challenge",
                    systemImage: "shuffle",
                    enabled: !isLoadingChallenge,
                    primary: true
                )
            }
            .disabled(isLoadingChallenge)
        }
    }

    private func actionLabel(title: String, systemImage: String, enabled: Bool, primary: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(primary ? .black : (enabled ? Theme.textPrimary : Theme.textSecondary.opacity(0.4)))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(primary
                      ? (enabled ? Theme.accent : Theme.accent.opacity(0.35))
                      : Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            primary ? Color.clear : Theme.accent.opacity(enabled ? 0.5 : 0.2),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Surah Picker Sheet (multi-select)

private struct ContinueAyahSurahPickerSheet: View {
    @Binding var selected: Set<Int>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [ContinueAyahSurahCatalog.Entry] {
        if searchText.isEmpty { return ContinueAyahSurahCatalog.all }
        return ContinueAyahSurahCatalog.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || "\($0.number)".contains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List(filtered, id: \.number) { entry in
                    Button {
                        if selected.contains(entry.number) {
                            selected.remove(entry.number)
                        } else {
                            selected.insert(entry.number)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Text("\(entry.number)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 28, alignment: .trailing)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.name)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(entry.numberOfAyahs) ayat")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: selected.contains(entry.number) ? "checkmark.square.fill" : "square")
                                .font(.body)
                                .foregroundStyle(selected.contains(entry.number) ? Theme.accent : Theme.textSecondary.opacity(0.5))
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
            .navigationTitle("Select Surahs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") { selected.removeAll() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

// MARK: - Surah Catalog (number, name, ayah count)

private enum ContinueAyahSurahCatalog {
    struct Entry {
        let number: Int
        let name: String
        let numberOfAyahs: Int
    }

    static let all: [Entry] = [
        .init(number: 1,   name: "Al-Fatihah",      numberOfAyahs: 7),
        .init(number: 2,   name: "Al-Baqarah",      numberOfAyahs: 286),
        .init(number: 3,   name: "Ali 'Imran",      numberOfAyahs: 200),
        .init(number: 4,   name: "An-Nisa",         numberOfAyahs: 176),
        .init(number: 5,   name: "Al-Ma'idah",      numberOfAyahs: 120),
        .init(number: 6,   name: "Al-An'am",        numberOfAyahs: 165),
        .init(number: 7,   name: "Al-A'raf",        numberOfAyahs: 206),
        .init(number: 8,   name: "Al-Anfal",        numberOfAyahs: 75),
        .init(number: 9,   name: "At-Tawbah",       numberOfAyahs: 129),
        .init(number: 10,  name: "Yunus",           numberOfAyahs: 109),
        .init(number: 11,  name: "Hud",             numberOfAyahs: 123),
        .init(number: 12,  name: "Yusuf",           numberOfAyahs: 111),
        .init(number: 13,  name: "Ar-Ra'd",         numberOfAyahs: 43),
        .init(number: 14,  name: "Ibrahim",         numberOfAyahs: 52),
        .init(number: 15,  name: "Al-Hijr",         numberOfAyahs: 99),
        .init(number: 16,  name: "An-Nahl",         numberOfAyahs: 128),
        .init(number: 17,  name: "Al-Isra",         numberOfAyahs: 111),
        .init(number: 18,  name: "Al-Kahf",         numberOfAyahs: 110),
        .init(number: 19,  name: "Maryam",          numberOfAyahs: 98),
        .init(number: 20,  name: "Ta-Ha",           numberOfAyahs: 135),
        .init(number: 21,  name: "Al-Anbiya",       numberOfAyahs: 112),
        .init(number: 22,  name: "Al-Hajj",         numberOfAyahs: 78),
        .init(number: 23,  name: "Al-Mu'minun",     numberOfAyahs: 118),
        .init(number: 24,  name: "An-Nur",          numberOfAyahs: 64),
        .init(number: 25,  name: "Al-Furqan",       numberOfAyahs: 77),
        .init(number: 26,  name: "Ash-Shu'ara",     numberOfAyahs: 227),
        .init(number: 27,  name: "An-Naml",         numberOfAyahs: 93),
        .init(number: 28,  name: "Al-Qasas",        numberOfAyahs: 88),
        .init(number: 29,  name: "Al-Ankabut",      numberOfAyahs: 69),
        .init(number: 30,  name: "Ar-Rum",          numberOfAyahs: 60),
        .init(number: 31,  name: "Luqman",          numberOfAyahs: 34),
        .init(number: 32,  name: "As-Sajdah",       numberOfAyahs: 30),
        .init(number: 33,  name: "Al-Ahzab",        numberOfAyahs: 73),
        .init(number: 34,  name: "Saba",            numberOfAyahs: 54),
        .init(number: 35,  name: "Fatir",           numberOfAyahs: 45),
        .init(number: 36,  name: "Ya-Sin",          numberOfAyahs: 83),
        .init(number: 37,  name: "As-Saffat",       numberOfAyahs: 182),
        .init(number: 38,  name: "Sad",             numberOfAyahs: 88),
        .init(number: 39,  name: "Az-Zumar",        numberOfAyahs: 75),
        .init(number: 40,  name: "Ghafir",          numberOfAyahs: 85),
        .init(number: 41,  name: "Fussilat",        numberOfAyahs: 54),
        .init(number: 42,  name: "Ash-Shura",       numberOfAyahs: 53),
        .init(number: 43,  name: "Az-Zukhruf",      numberOfAyahs: 89),
        .init(number: 44,  name: "Ad-Dukhan",       numberOfAyahs: 59),
        .init(number: 45,  name: "Al-Jathiyah",     numberOfAyahs: 37),
        .init(number: 46,  name: "Al-Ahqaf",        numberOfAyahs: 35),
        .init(number: 47,  name: "Muhammad",        numberOfAyahs: 38),
        .init(number: 48,  name: "Al-Fath",         numberOfAyahs: 29),
        .init(number: 49,  name: "Al-Hujurat",      numberOfAyahs: 18),
        .init(number: 50,  name: "Qaf",             numberOfAyahs: 45),
        .init(number: 51,  name: "Adh-Dhariyat",    numberOfAyahs: 60),
        .init(number: 52,  name: "At-Tur",          numberOfAyahs: 49),
        .init(number: 53,  name: "An-Najm",         numberOfAyahs: 62),
        .init(number: 54,  name: "Al-Qamar",        numberOfAyahs: 55),
        .init(number: 55,  name: "Ar-Rahman",       numberOfAyahs: 78),
        .init(number: 56,  name: "Al-Waqi'ah",      numberOfAyahs: 96),
        .init(number: 57,  name: "Al-Hadid",        numberOfAyahs: 29),
        .init(number: 58,  name: "Al-Mujadila",     numberOfAyahs: 22),
        .init(number: 59,  name: "Al-Hashr",        numberOfAyahs: 24),
        .init(number: 60,  name: "Al-Mumtahanah",   numberOfAyahs: 13),
        .init(number: 61,  name: "As-Saf",          numberOfAyahs: 14),
        .init(number: 62,  name: "Al-Jumu'ah",      numberOfAyahs: 11),
        .init(number: 63,  name: "Al-Munafiqun",    numberOfAyahs: 11),
        .init(number: 64,  name: "At-Taghabun",     numberOfAyahs: 18),
        .init(number: 65,  name: "At-Talaq",        numberOfAyahs: 12),
        .init(number: 66,  name: "At-Tahrim",       numberOfAyahs: 12),
        .init(number: 67,  name: "Al-Mulk",         numberOfAyahs: 30),
        .init(number: 68,  name: "Al-Qalam",        numberOfAyahs: 52),
        .init(number: 69,  name: "Al-Haqqah",       numberOfAyahs: 52),
        .init(number: 70,  name: "Al-Ma'arij",      numberOfAyahs: 44),
        .init(number: 71,  name: "Nuh",             numberOfAyahs: 28),
        .init(number: 72,  name: "Al-Jinn",         numberOfAyahs: 28),
        .init(number: 73,  name: "Al-Muzzammil",    numberOfAyahs: 20),
        .init(number: 74,  name: "Al-Muddaththir",  numberOfAyahs: 56),
        .init(number: 75,  name: "Al-Qiyamah",      numberOfAyahs: 40),
        .init(number: 76,  name: "Al-Insan",        numberOfAyahs: 31),
        .init(number: 77,  name: "Al-Mursalat",     numberOfAyahs: 50),
        .init(number: 78,  name: "An-Naba",         numberOfAyahs: 40),
        .init(number: 79,  name: "An-Nazi'at",      numberOfAyahs: 46),
        .init(number: 80,  name: "Abasa",           numberOfAyahs: 42),
        .init(number: 81,  name: "At-Takwir",       numberOfAyahs: 29),
        .init(number: 82,  name: "Al-Infitar",      numberOfAyahs: 19),
        .init(number: 83,  name: "Al-Mutaffifin",   numberOfAyahs: 36),
        .init(number: 84,  name: "Al-Inshiqaq",     numberOfAyahs: 25),
        .init(number: 85,  name: "Al-Buruj",        numberOfAyahs: 22),
        .init(number: 86,  name: "At-Tariq",        numberOfAyahs: 17),
        .init(number: 87,  name: "Al-A'la",         numberOfAyahs: 19),
        .init(number: 88,  name: "Al-Ghashiyah",    numberOfAyahs: 26),
        .init(number: 89,  name: "Al-Fajr",         numberOfAyahs: 30),
        .init(number: 90,  name: "Al-Balad",        numberOfAyahs: 20),
        .init(number: 91,  name: "Ash-Shams",       numberOfAyahs: 15),
        .init(number: 92,  name: "Al-Layl",         numberOfAyahs: 21),
        .init(number: 93,  name: "Ad-Duha",         numberOfAyahs: 11),
        .init(number: 94,  name: "Ash-Sharh",       numberOfAyahs: 8),
        .init(number: 95,  name: "At-Tin",          numberOfAyahs: 8),
        .init(number: 96,  name: "Al-Alaq",         numberOfAyahs: 19),
        .init(number: 97,  name: "Al-Qadr",         numberOfAyahs: 5),
        .init(number: 98,  name: "Al-Bayyinah",     numberOfAyahs: 8),
        .init(number: 99,  name: "Az-Zalzalah",     numberOfAyahs: 8),
        .init(number: 100, name: "Al-Adiyat",       numberOfAyahs: 11),
        .init(number: 101, name: "Al-Qari'ah",      numberOfAyahs: 11),
        .init(number: 102, name: "At-Takathur",     numberOfAyahs: 8),
        .init(number: 103, name: "Al-Asr",          numberOfAyahs: 3),
        .init(number: 104, name: "Al-Humazah",      numberOfAyahs: 9),
        .init(number: 105, name: "Al-Fil",          numberOfAyahs: 5),
        .init(number: 106, name: "Quraysh",         numberOfAyahs: 4),
        .init(number: 107, name: "Al-Ma'un",        numberOfAyahs: 7),
        .init(number: 108, name: "Al-Kawthar",      numberOfAyahs: 3),
        .init(number: 109, name: "Al-Kafirun",      numberOfAyahs: 6),
        .init(number: 110, name: "An-Nasr",         numberOfAyahs: 3),
        .init(number: 111, name: "Al-Masad",        numberOfAyahs: 5),
        .init(number: 112, name: "Al-Ikhlas",       numberOfAyahs: 4),
        .init(number: 113, name: "Al-Falaq",        numberOfAyahs: 5),
        .init(number: 114, name: "An-Nas",          numberOfAyahs: 6),
    ]
}

#Preview {
    ContinueAyahView(onBack: {})
        .environmentObject(AppState())
}
