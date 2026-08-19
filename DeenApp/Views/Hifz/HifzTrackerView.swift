//
//  HifzTrackerView.swift
//  DeenApp
//
//  Hifz-Tracker: zeigt alle gelernten Suren / Abschnitte in einem 2-spaltigen
//  Raster, einen Statistik-Header mit Fortschritts-Kennzahlen, und erlaubt
//  via Add-Sheet neue Einträge sowie das Markieren als wiederholt.
//

import SwiftUI

struct HifzTrackerView: View {
    let onBack: () -> Void

    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = HifzTrackerViewModel()

    @State private var showAddSheet = false

    private var language: AppLanguage { appState.appLanguage }

    private var stats: HifzStats {
        HifzStats.compute(from: viewModel.entries, now: viewModel.tick)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                if viewModel.entries.isEmpty {
                    emptyState
                } else {
                    entriesGrid
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            HifzAddSheet { entries in
                for entry in entries { viewModel.add(entry) }
                showAddSheet = false
            } onCancel: {
                showAddSheet = false
            }
            .environmentObject(appState)
        }
        .onAppear {
            viewModel.language = language
        }
        .onChange(of: language) { _, newValue in
            viewModel.language = newValue
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.cardBackground))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.hifzTrackerTitle(language))
                    .font(.title2.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text(L10n.hifzTrackerSubtitle(language))
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                    Text(L10n.hifzAdd(language))
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(Theme.accent)
                        .shadow(color: Theme.accent.opacity(0.45), radius: 10, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Theme.accent.opacity(0.7))
            Text(L10n.hifzEmptyTitle(language))
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text(L10n.hifzEmptyHint(language))
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Grid

    private var entriesGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                HifzStatsCard(stats: stats, language: language)
                    .padding(.horizontal, 20)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(viewModel.entries) { entry in
                        HifzEntryTile(
                            entry: entry,
                            tick: viewModel.tick,
                            language: language,
                            onRevised: { viewModel.markRevised(entry) },
                            onDelete: { viewModel.delete(entry) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 140)
        }
    }
}

// MARK: - Stats

/// Aggregierte Kennzahlen über die Hifz-Sammlung. `totalQuranAyat` ist die
/// Standard-Hafs-Zählung (6236). Für `memorizedAyat` werden Overlapping-Bereiche
/// **pro Sure** vereint, damit dieselben Ayat nicht doppelt gezählt werden.
struct HifzStats {
    static let totalQuranAyat = 6236

    let totalEntries: Int
    let memorizedSurahs: Int      // Volle Suren (eindeutige Suren-Nummer mit fullSurah-Eintrag)
    let memorizedAyat: Int        // Eindeutige Ayat über alle Suren
    let overdueCount: Int
    let longestSurahNumber: Int?  // Längste vollständig memorierte Sure (nach Ayah-Anzahl)
    let longestSurahName: String?
    let longestSurahAyat: Int

    var percentOfQuran: Double {
        Double(memorizedAyat) / Double(Self.totalQuranAyat) * 100.0
    }

    static func compute(from entries: [HifzEntry], now: Date) -> HifzStats {
        // Pro Sure: vereinige memorierte Ayah-Indizes.
        var ayatBySurah: [Int: Set<Int>] = [:]
        let surahLookup: [Int: QuranSuraInfo] = Dictionary(
            uniqueKeysWithValues: HifzSurahFallback.all.map { ($0.number, $0) }
        )

        for entry in entries {
            let total = surahLookup[entry.surahNumber]?.numberOfAyahs ?? 0
            switch entry.portion {
            case .fullSurah:
                if total > 0 {
                    ayatBySurah[entry.surahNumber, default: []].formUnion(1...total)
                }
            case .ayahRange(let from, let to):
                let lo = max(1, min(from, to))
                let hi = max(from, to)
                let bounded = total > 0 ? min(hi, total) : hi
                if lo <= bounded {
                    ayatBySurah[entry.surahNumber, default: []].formUnion(lo...bounded)
                }
            case .pages(let count):
                // Grobe Heuristik: ~15 Ayat pro Mushaf-Seite. Nur Schätzung —
                // wir markieren am Anfang der Sure die entsprechende Anzahl.
                let estimated = max(1, count * 15)
                let bounded = total > 0 ? min(estimated, total) : estimated
                ayatBySurah[entry.surahNumber, default: []].formUnion(1...bounded)
            }
        }

        let memorizedAyat = ayatBySurah.values.reduce(0) { $0 + $1.count }

        // "Vollständig memoriert" = alle Ayat dieser Sure sind erfasst.
        let memorizedSurahNumbers = ayatBySurah.compactMap { (num, set) -> Int? in
            let total = surahLookup[num]?.numberOfAyahs ?? 0
            return (total > 0 && set.count >= total) ? num : nil
        }

        let longestSurah = memorizedSurahNumbers
            .compactMap { surahLookup[$0] }
            .max(by: { $0.numberOfAyahs < $1.numberOfAyahs })

        return HifzStats(
            totalEntries: entries.count,
            memorizedSurahs: memorizedSurahNumbers.count,
            memorizedAyat: memorizedAyat,
            overdueCount: entries.filter { $0.isOverdue(now: now) }.count,
            longestSurahNumber: longestSurah?.number,
            longestSurahName: longestSurah?.nameTransliteration,
            longestSurahAyat: longestSurah?.numberOfAyahs ?? 0
        )
    }
}

private struct HifzStatsCard: View {
    let stats: HifzStats
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Text(L10n.hifzStatsTitle(language))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if stats.overdueCount > 0 {
                    Text(L10n.hifzStatsOverdue(language, count: stats.overdueCount))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Theme.warning))
                }
            }

            // Quran-Fortschrittsbalken
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(L10n.hifzStatsQuranProgress(language))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(String(format: "%.2f%%", stats.percentOfQuran))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Theme.accent)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.accent.opacity(0.15))
                            .frame(height: 8)
                        Capsule()
                            .fill(Theme.accent)
                            .frame(
                                width: max(4, geo.size.width * CGFloat(min(1.0, stats.percentOfQuran / 100.0))),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }

            // Kennzahlen-Raster
            HStack(spacing: 10) {
                statTile(
                    icon: "book.closed.fill",
                    value: "\(stats.memorizedSurahs)",
                    suffix: "/ 114",
                    label: L10n.hifzStatsSurahsLabel(language)
                )
                statTile(
                    icon: "text.alignleft",
                    value: "\(stats.memorizedAyat)",
                    suffix: "/ \(HifzStats.totalQuranAyat)",
                    label: L10n.hifzStatsAyatLabel(language)
                )
                statTile(
                    icon: "square.stack.3d.up.fill",
                    value: "\(stats.totalEntries)",
                    suffix: nil,
                    label: L10n.hifzStatsEntriesLabel(language)
                )
            }

            if let longestName = stats.longestSurahName {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                    Text(L10n.hifzStatsLongest(language, surahName: longestName, ayat: stats.longestSurahAyat))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
        )
    }

    private func statTile(icon: String, value: String, suffix: String?, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.accent)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                if let suffix {
                    Text(suffix)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.accent.opacity(0.08))
        )
    }
}

// MARK: - Entry Tile (compact)

private struct HifzEntryTile: View {
    let entry: HifzEntry
    let tick: Date
    let language: AppLanguage
    let onRevised: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private var isOverdue: Bool { entry.isOverdue(now: tick) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.accent.opacity(isOverdue ? 0.25 : 0.15))
                        .frame(width: 36, height: 36)
                    Text("\(entry.surahNumber)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.accent)
                }
                Spacer(minLength: 0)
                if isOverdue {
                    Text(L10n.hifzOverdueBadge(language))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.warning))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.surahTransliteration)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(entry.surahArabicName)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            Text(entry.portion.shortLabel(language: language))
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)

            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption2)
                    .foregroundStyle(isOverdue ? Theme.warning : Theme.textSecondary)
                Text(relativeTimeString)
                    .font(.caption2)
                    .foregroundStyle(isOverdue ? Theme.warning : Theme.textSecondary)
                    .lineLimit(1)
            }

            Button(action: onRevised) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                    Text(L10n.hifzMarkRevised(language))
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Theme.accent.opacity(0.18))
                )
                .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
        )
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label(L10n.hifzDelete(language), systemImage: "trash")
            }
        }
        .confirmationDialog(
            L10n.hifzDelete(language),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.hifzDelete(language), role: .destructive, action: onDelete)
            Button(L10n.hifzCancel(language), role: .cancel) {}
        }
    }

    private var relativeTimeString: String {
        let seconds = Int(tick.timeIntervalSince(entry.lastRevisedAt))
        if seconds < 60 {
            return L10n.hifzJustNow(language)
        }
        let minutes = seconds / 60
        if minutes < 60 {
            return L10n.hifzAgoMinutes(language, minutes: minutes)
        }
        let hours = minutes / 60
        if hours < 24 {
            return L10n.hifzAgoHours(language, hours: hours)
        }
        let days = entry.daysSinceLastRevision(now: tick)
        return L10n.hifzAgoDays(language, days: max(1, days))
    }
}

// MARK: - Add Sheet

private struct HifzAddSheet: View {
    let onSave: ([HifzEntry]) -> Void
    let onCancel: () -> Void

    @EnvironmentObject private var appState: AppState

    /// Ausgewählte Suren in der Reihenfolge der Auswahl.
    @State private var selectedSurahs: [QuranSuraInfo] = []
    @State private var scope: Scope = .full
    @State private var ayahFromText: String = "1"
    @State private var ayahToText: String = "1"
    @State private var pagesText: String = "1"
    @State private var showSurahPicker = false

    private enum Scope: String, CaseIterable, Identifiable {
        case full, ayahRange, pages
        var id: String { rawValue }
    }

    private var language: AppLanguage { appState.appLanguage }

    /// Statische Suren-Liste (alle 114 Suren) — komplett offline, kein
    /// Netzwerk-Store nötig.
    private var resolvedSuraList: [QuranSuraInfo] { HifzSurahFallback.all }

    /// Bei Mehrfachauswahl ist der Scope auf "ganze Sure" festgelegt, weil
    /// Ayah-/Seitenbereiche nur für eine einzelne Sure Sinn ergeben.
    private var isMultiSelect: Bool { selectedSurahs.count > 1 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        surahSection
                        if !isMultiSelect {
                            scopeSection
                            if scope == .ayahRange { ayahInputs }
                            if scope == .pages { pagesInput }
                        } else {
                            multiSelectHint
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L10n.hifzAddTitle(language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.hifzCancel(language), action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.hifzSave(language)) { save() }
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showSurahPicker) {
                HifzSurahPicker(
                    suraList: resolvedSuraList,
                    initiallySelected: Set(selectedSurahs.map(\.number))
                ) { picked in
                    selectedSurahs = picked
                    if let only = picked.first, picked.count == 1 {
                        let ayahCount = max(1, only.numberOfAyahs)
                        ayahFromText = "1"
                        ayahToText = "\(ayahCount)"
                    }
                    showSurahPicker = false
                } onCancel: {
                    showSurahPicker = false
                }
            }
        }
    }

    private var surahSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.hifzSelectSurah(language))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            Button {
                showSurahPicker = true
            } label: {
                HStack {
                    if selectedSurahs.isEmpty {
                        Text(L10n.hifzSelectSurah(language))
                            .foregroundStyle(Theme.textSecondary)
                    } else if selectedSurahs.count == 1, let s = selectedSurahs.first {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(s.number). \(s.nameTransliteration)")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                            Text(s.nameArabic)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.hifzSelectedCount(language, count: selectedSurahs.count))
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                            Text(selectedSurahs.prefix(3).map(\.nameTransliteration).joined(separator: ", ")
                                 + (selectedSurahs.count > 3 ? " …" : ""))
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(Theme.cardBackground)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.hifzScope(language))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            Picker("", selection: $scope) {
                Text(L10n.hifzScopeFullSurah(language)).tag(Scope.full)
                Text(L10n.hifzScopeAyatRange(language)).tag(Scope.ayahRange)
                Text(L10n.hifzScopePages(language)).tag(Scope.pages)
            }
            .pickerStyle(.segmented)
        }
    }

    private var multiSelectHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Theme.accent)
            Text(L10n.hifzMultiSelectHint(language))
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Theme.accent.opacity(0.1))
        )
    }

    private var ayahInputs: some View {
        HStack(spacing: 12) {
            labeledField(label: L10n.hifzAyahFrom(language), text: $ayahFromText)
            labeledField(label: L10n.hifzAyahTo(language), text: $ayahToText)
        }
    }

    private var pagesInput: some View {
        labeledField(label: L10n.hifzPagesCount(language), text: $pagesText)
    }

    private func labeledField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            TextField("", text: text)
                .keyboardType(.numberPad)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(Theme.cardBackground)
                )
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var canSave: Bool {
        guard !selectedSurahs.isEmpty else { return false }
        if isMultiSelect { return true }
        switch scope {
        case .full: return true
        case .ayahRange:
            guard let from = Int(ayahFromText), let to = Int(ayahToText),
                  from >= 1, to >= from else { return false }
            return true
        case .pages:
            guard let count = Int(pagesText), count >= 1 else { return false }
            return true
        }
    }

    private func save() {
        guard !selectedSurahs.isEmpty else { return }
        let portion: HifzPortion
        if isMultiSelect {
            portion = .fullSurah
        } else {
            switch scope {
            case .full:
                portion = .fullSurah
            case .ayahRange:
                let from = max(1, Int(ayahFromText) ?? 1)
                let to = max(from, Int(ayahToText) ?? from)
                portion = .ayahRange(from: from, to: to)
            case .pages:
                portion = .pages(count: max(1, Int(pagesText) ?? 1))
            }
        }
        let entries = selectedSurahs.map { s in
            HifzEntry(
                surahNumber: s.number,
                surahTransliteration: s.nameTransliteration,
                surahArabicName: s.nameArabic,
                portion: portion
            )
        }
        onSave(entries)
    }
}

// MARK: - Surah Picker

private struct HifzSurahPicker: View {
    let suraList: [QuranSuraInfo]
    let initiallySelected: Set<Int>
    let onConfirm: ([QuranSuraInfo]) -> Void
    let onCancel: () -> Void

    @EnvironmentObject private var appState: AppState
    @State private var query: String = ""
    @State private var selectedNumbers: Set<Int> = []

    init(
        suraList: [QuranSuraInfo],
        initiallySelected: Set<Int> = [],
        onConfirm: @escaping ([QuranSuraInfo]) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.suraList = suraList
        self.initiallySelected = initiallySelected
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _selectedNumbers = State(initialValue: initiallySelected)
    }

    private var language: AppLanguage { appState.appLanguage }

    private var filtered: [QuranSuraInfo] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return suraList }
        return suraList.filter {
            $0.nameTransliteration.lowercased().contains(q)
                || "\($0.number)" == q
                || $0.nameArabic.contains(query)
        }
    }

    private func confirmSelection() {
        let ordered = suraList.filter { selectedNumbers.contains($0.number) }
        onConfirm(ordered)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List(filtered) { s in
                    let isSelected = selectedNumbers.contains(s.number)
                    Button {
                        if isSelected { selectedNumbers.remove(s.number) }
                        else { selectedNumbers.insert(s.number) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary.opacity(0.5))
                            Text("\(s.number).")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 36, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.nameTransliteration)
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)
                                Text(s.nameArabic)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text("\(s.numberOfAyahs)")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .searchable(text: $query)
            }
            .navigationTitle(L10n.hifzSelectSurah(language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.hifzCancel(language), action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.hifzDone(language)) { confirmSelection() }
                        .disabled(selectedNumbers.isEmpty)
                }
            }
        }
    }
}
