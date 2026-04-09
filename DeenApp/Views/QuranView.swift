//
//  QuranView.swift
//  DeenApp
//
//  Mushaf: Authentische 604-Seiten-Ansicht — "Golden Mushaf" Premium-Layout.
//  Index:  Surah-Inhaltsverzeichnis mit Lesezeichen / Weiterlesen-Karte + Juz-Gruppierung.
//  Liste:  Sure-basierte Listenansicht mit Tajweed, Transliteration und Übersetzung.
//

import SwiftUI
import UIKit

// MARK: - Ansichtsmodus

enum QuranDisplayMode: String, CaseIterable {
    case mushaf = "mushaf"
    case list   = "list"
}

// MARK: - Navigation Target

enum QuranNavigationTarget: Hashable {
    case mushafPage(Int)
    case suraList(Int)
    case lastRead
}

// MARK: - Hardcoded Arabic font (Uthmanic Hafs mandatory)

private let kArabicFont = QuranArabicFont.uthmanicHafs

// MARK: - Root View

struct QuranView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var quranStore = QuranStore()
    @State private var displayMode: QuranDisplayMode = .mushaf
    @State private var arabicFontSize: CGFloat = 24
    @State private var translationOption: QuranTranslationOption = .none
    @State private var showSettings = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            QuranIndexView(
                store: quranStore,
                displayMode: $displayMode,
                language: appState.appLanguage,
                onNavigate: { target in navigationPath.append(target) }
            )
            .navigationDestination(for: QuranNavigationTarget.self) { target in
                QuranReaderView(
                    store: quranStore,
                    initialTarget: target,
                    displayMode: $displayMode,
                    arabicFontSize: $arabicFontSize,
                    translationOption: $translationOption,
                    language: appState.appLanguage,
                    showSettings: $showSettings
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            QuranSettingsSheet(
                language: appState.appLanguage,
                arabicFontSize: $arabicFontSize,
                translationOption: $translationOption,
                isTajweedEnabled: $appState.isTajweedEnabled,
                isReadingModeEnabled: $appState.isReadingModeEnabled
            )
        }
    }
}

// MARK: - Index-Ansicht (Inhaltsverzeichnis) with Juz sections

struct QuranIndexView: View {
    @ObservedObject var store: QuranStore
    @Binding var displayMode: QuranDisplayMode
    let language: AppLanguage
    let onNavigate: (QuranNavigationTarget) -> Void

    @State private var searchQuery = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                modePicker

                if store.isLoading && store.suraList.isEmpty {
                    ProgressView()
                        .tint(Theme.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = store.error, store.suraList.isEmpty {
                    ContentUnavailableView(
                        "Fehler", systemImage: "wifi.exclamationmark", description: Text(err)
                    )
                    .foregroundColor(Theme.textSecondary)
                } else {
                    suraList
                }
            }
        }
        .navigationTitle("القرآن الكريم")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var modePicker: some View {
        Picker("", selection: $displayMode) {
            Text(L10n.quranMushaf(language)).tag(QuranDisplayMode.mushaf)
            Text(L10n.quranList(language)).tag(QuranDisplayMode.list)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .background(Theme.background)
    }

    private var suraList: some View {
        List {
            if searchQuery.isEmpty {
                weiterlesenSection
                ForEach(mergedNavigationItems) { item in
                    switch item {
                    case .surah(let sura): surahRow(sura)
                    case .juz(let num, let page): juzRow(number: num, page: page)
                    }
                }
            } else {
                // Direct page-jump shortcut when query is a valid page number
                if let page = pageSearchTarget {
                    pageJumpRow(page: page)
                }
                let results = filteredNavigationItems
                if results.isEmpty && pageSearchTarget == nil {
                    // Empty state
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.textSecondary.opacity(0.4))
                        Text("Keine Ergebnisse f\u{FC}r \"\(searchQuery)\"")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(results) { item in
                        switch item {
                        case .surah(let sura): surahRow(sura)
                        case .juz(let num, let page): juzRow(number: num, page: page)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }
        .searchable(text: $searchQuery,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: searchPrompt)
    }

    private var searchPrompt: String {
        switch language {
        case .english: return "Surah, Juz or page"
        case .turkish: return "Sure, Cüz veya sayfa"
        default:       return "Sure, Juz oder Seite"
        }
    }

    /// Non-nil when query is a valid Mushaf page number (1–604).
    private var pageSearchTarget: Int? {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let page = Int(trimmed), page >= 1, page <= QuranStore.totalPages else { return nil }
        return page
    }

    /// Merged navigation items filtered by the current search query.
    /// - Surah: matches by number, transliteration, translation, or Arabic name.
    /// - Juz:   matches by number only.
    private var filteredNavigationItems: [QuranNavigationItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return mergedNavigationItems }
        let lower    = query.lowercased()
        let queryNum = Int(query)
        return mergedNavigationItems.filter { item in
            switch item {
            case .surah(let sura):
                if let n = queryNum, sura.number == n { return true }
                return sura.nameTransliteration.lowercased().contains(lower)
                    || sura.nameTranslation.lowercased().contains(lower)
                    || sura.nameArabic.contains(query)   // Arabic: original casing
            case .juz(let num, _):
                guard let n = queryNum else { return false }
                return num == n
            }
        }
    }

    /// Surahs and Juz entries merged and sorted by page number.
    /// On equal page numbers, the Juz marker comes first (matches how a Juz opens before the Surah text).
    private var mergedNavigationItems: [QuranNavigationItem] {
        var items: [QuranNavigationItem] = store.suraList.map { .surah($0) }
        for juz in 1...30 {
            let page = QuranStore.juzFirstPage[juz] ?? 1
            items.append(.juz(number: juz, page: page))
        }
        return items.sorted { a, b in
            if a.pageNumber != b.pageNumber { return a.pageNumber < b.pageNumber }
            if case .juz = a, case .surah = b { return true }
            return false
        }
    }

    // MARK: - Page Jump Row (shown when query is a valid page number)

    private func pageJumpRow(page: Int) -> some View {
        Button(action: { onNavigate(.mushafPage(page)) }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Theme.accent.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Theme.accent.opacity(0.45), lineWidth: 0.75)
                        )
                        .frame(width: 36, height: 36)
                    Image(systemName: "book.pages.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(L10n.quranPage(language)) \(page)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Direkt öffnen · Mushaf")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.body)
                    .foregroundColor(Theme.accent)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(Theme.accent.opacity(0.08))
        .listRowSeparatorTint(Theme.accent.opacity(0.3))
    }

    // MARK: - Weiterlesen Card

    @ViewBuilder
    private var weiterlesenSection: some View {
        Section {
            weiterlesenCard
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
        }
    }

    private var weiterlesenCard: some View {
        Button(action: { onNavigate(.lastRead) }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.iconFajr, Theme.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                    Image(systemName: "bookmark.fill")
                        .font(.body)
                        .foregroundColor(Theme.background)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.quranContinue(language))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(L10n.quranPage(language)) \(store.currentMushafPageNumber) · Mushaf")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .fill(Theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                            .strokeBorder(Theme.iconFajr.opacity(0.35), lineWidth: 0.75)
                    )
            )
            .shadow(color: Theme.shadowColor, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Juz Row

    private func juzRow(number: Int, page: Int) -> some View {
        Button(action: { onNavigate(.mushafPage(page)) }) {
            HStack(spacing: 12) {
                // Juz number badge — accent-tinted to distinguish from surah rows
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Theme.accent.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Theme.accent.opacity(0.45), lineWidth: 0.75)
                        )
                        .frame(width: 36, height: 36)
                    Text("\(number)")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundColor(Theme.accent)
                }

                Text("\(number). \(L10n.quranJuz(language)) · S.\(page)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.textSecondary)

                Spacer()
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .listRowBackground(Theme.accent.opacity(0.04))
        .listRowSeparatorTint(Theme.accent.opacity(0.25))
    }

    // MARK: - Shared Surah Row

    private func surahRow(_ sura: QuranSuraInfo) -> some View {
        Button(action: {
            if displayMode == .mushaf {
                onNavigate(.mushafPage(sura.pageNumber))
            } else {
                onNavigate(.suraList(sura.number))
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Theme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Theme.textSecondary.opacity(0.2), lineWidth: 0.5)
                        )
                        .frame(width: 36, height: 36)
                    Text("\(sura.number)")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundColor(Theme.textSecondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(sura.nameTransliteration)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Theme.textPrimary)
                    Text(sura.nameTranslation)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(sura.nameArabic)
                        .font(.title3.weight(.medium))
                        .foregroundColor(Theme.textPrimary)
                        .environment(\.layoutDirection, .rightToLeft)
                    HStack(spacing: 6) {
                        Text("S.\(sura.pageNumber)")
                            .font(.caption2.weight(.medium).monospacedDigit())
                            .foregroundColor(Theme.textSecondary.opacity(0.7))
                        Text("\(sura.numberOfAyahs) آية")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(Theme.cardBackground)
        .listRowSeparatorTint(Theme.textSecondary.opacity(0.2))
    }
}

// MARK: - Reader View (Mushaf + Liste)

struct QuranReaderView: View {
    @ObservedObject var store: QuranStore
    @EnvironmentObject var appState: AppState
    let initialTarget: QuranNavigationTarget
    @Binding var displayMode: QuranDisplayMode
    @Binding var arabicFontSize: CGFloat
    @Binding var translationOption: QuranTranslationOption
    let language: AppLanguage
    @Binding var showSettings: Bool

    private var readingMode: Bool { appState.isReadingModeEnabled }
    private var readerBg: Color { readingMode ? .white : Theme.background }

    var body: some View {
        ZStack {
            readerBg.ignoresSafeArea()
            VStack(spacing: 0) {
                modePicker
                switch displayMode {
                case .mushaf:
                    QuranMushafPageView(
                        store: store,
                        arabicFontSize: arabicFontSize,
                        translationOption: translationOption,
                        language: language
                    )
                case .list:
                    if store.currentSuraVerses.isEmpty && store.selectedSuraNumber == nil {
                        ContentUnavailableView(
                            "Sure auswählen",
                            systemImage: "list.bullet",
                            description: Text("Kehre zurück und wähle eine Sure aus der Liste.")
                        )
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        QuranListView(
                            store: store,
                            arabicFontSize: arabicFontSize,
                            translationOption: translationOption,
                            isTajweedEnabled: appState.isTajweedEnabled,
                            readingMode: readingMode
                        )
                    }
                }
            }
        }
        .navigationTitle(readerTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "textformat.size")
                }
                .foregroundColor(Theme.textPrimary)
            }
        }
        .onAppear {
            switch initialTarget {
            case .mushafPage(let page):
                store.goToMushafPage(page)
            case .suraList(let surah):
                store.selectSura(surah)
            case .lastRead:
                displayMode = .mushaf
            }
        }
        .onChange(of: displayMode) { oldMode, newMode in
            switch (oldMode, newMode) {
            case (.mushaf, .list):
                // Derive which Surah is on the current Mushaf page and load it in the list.
                let surah = store.surahNumberForMushafPage(store.currentMushafPageNumber)
                store.selectSura(surah)
            case (.list, .mushaf):
                // Jump the Mushaf to the first page of the currently displayed Surah.
                if let surah = store.selectedSuraNumber,
                   let page = QuranStore.surahFirstPage[surah] {
                    store.goToMushafPage(page)
                }
            default:
                break
            }
        }
    }

    private var modePicker: some View {
        Picker("", selection: $displayMode) {
            Text(L10n.quranMushaf(language)).tag(QuranDisplayMode.mushaf)
            Text(L10n.quranList(language)).tag(QuranDisplayMode.list)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.background)
    }

    private var readerTitle: String {
        switch displayMode {
        case .mushaf:
            return "\(L10n.quranPage(language)) \(store.currentMushafPageNumber)"
        case .list:
            if let num = store.selectedSuraNumber,
               let info = store.suraList.first(where: { $0.number == num }) {
                return info.nameTransliteration
            }
            return L10n.tabQuran(language)
        }
    }
}

// MARK: - Mushaf Premium Layout (ScrollView paging) + Page Slider

struct QuranMushafPageView: View {
    @ObservedObject var store: QuranStore
    @EnvironmentObject var appState: AppState
    let arabicFontSize: CGFloat
    let translationOption: QuranTranslationOption
    let language: AppLanguage

    @State private var pageInput: String = ""
    @State private var showPageJump = false
    @State private var pageScrollID: Int? = nil
    @State private var sliderPage: Double = 1

    private var readingMode: Bool { appState.isReadingModeEnabled }
    private var pageBg: Color { readingMode ? .white : Theme.background }
    private var primaryText: Color { readingMode ? .black : Theme.textPrimary }
    private var cardBg: Color { readingMode ? Color(hex: "F5F5F0") : Theme.cardBackground }

    var body: some View {
        VStack(spacing: 0) {
            if store.isMushafLoading && store.mushafPageCache.isEmpty {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { geo in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 0) {
                            ForEach(1...QuranStore.totalPages, id: \.self) { pageNum in
                                mushafPageContent(pageNum)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                                    .id(pageNum)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $pageScrollID)
                    .environment(\.layoutDirection, .rightToLeft)
                }
                .onChange(of: pageScrollID) { _, newID in
                    guard let page = newID, page != store.currentMushafPageNumber else { return }
                    store.currentMushafPageNumber = page
                    sliderPage = Double(page)
                    appState.incrementDailyPages()
                    Task { await store.preloadMushafPages(around: page) }
                }
                .onChange(of: store.currentMushafPageNumber) { _, newPage in
                    guard pageScrollID != newPage else { return }
                    sliderPage = Double(newPage)
                    withAnimation(.easeInOut(duration: 0.25)) { pageScrollID = newPage }
                }

                pageSlider
                bottomBar
            }
        }
        .onAppear {
            pageScrollID = store.currentMushafPageNumber
            sliderPage = Double(store.currentMushafPageNumber)
            Task { await store.preloadMushafPages(around: store.currentMushafPageNumber) }
        }
    }

    // MARK: - Page Slider

    private var pageSlider: some View {
        VStack(spacing: 2) {
            Text("\(L10n.quranPage(language)) \(Int(sliderPage))")
                .font(.caption2.weight(.medium).monospacedDigit())
                .foregroundColor(Theme.textSecondary)
            Slider(value: $sliderPage, in: 1...Double(QuranStore.totalPages), step: 1)
                .tint(Theme.accent)
                .environment(\.layoutDirection, .rightToLeft)
                .onChange(of: sliderPage) { _, newVal in
                    let page = Int(newVal)
                    guard page != store.currentMushafPageNumber else { return }
                    store.goToMushafPage(page)
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(Theme.cardBackground.opacity(0.9))
    }

    // MARK: - Page Content

    @ViewBuilder
    private func mushafPageContent(_ pageNum: Int) -> some View {
        if let page = store.mushafPageCache[pageNum] {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    pageHeaderView(page: page)
                    ornamentalDivider
                    pageBodyView(page: page)
                    pageFooterView(pageNum: pageNum)
                }
                .padding(.horizontal, 22)
                .padding(.top, 10)
                .padding(.bottom, 16)
            }
            .background(pageBg)
        } else {
            VStack(spacing: 10) {
                ProgressView().tint(Theme.accent)
                Text("\(L10n.quranPage(language)) \(pageNum)")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { Task { await store.loadMushafPage(pageNum) } }
        }
    }

    // MARK: - Page Header

    private func pageHeaderView(page: MushafPage) -> some View {
        HStack(alignment: .center) {
            Text(page.suraArabicNames.first ?? "")
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.accent)
            Spacer()
            Text("الجزء \(toEasternArabic(page.juzNumber))")
                .font(.caption.weight(.medium))
                .foregroundColor(Theme.accent)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .padding(.horizontal, 4)
        .padding(.bottom, 6)
    }

    private var ornamentalDivider: some View {
        HStack(spacing: 6) {
            Rectangle().frame(height: 0.5).foregroundColor(Theme.accent.opacity(0.5))
            Image(systemName: "diamond.fill").font(.system(size: 5)).foregroundColor(Theme.accent.opacity(0.8))
            Rectangle().frame(height: 0.5).foregroundColor(Theme.accent.opacity(0.5))
        }
        .padding(.bottom, 10)
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: - Page Body

    @ViewBuilder
    private func pageBodyView(page: MushafPage) -> some View {
        let segments = pageSegments(for: page)
        ForEach(segments) { segment in
            if segment.isFirstOnPage { suraHeaderBanner(segment: segment) }
            if segment.showBismillah { bismillahView }
            mushafTextBlock(for: segment.ayahs).padding(.bottom, 6)
        }
    }

    private func suraHeaderBanner(segment: PageSegment) -> some View {
        VStack(spacing: 5) {
            ornamentalRule
            VStack(spacing: 3) {
                Text(segment.suraName)
                    .font(kArabicFont.font(size: arabicFontSize * 0.85))
                    .foregroundColor(Theme.accent)
                    .multilineTextAlignment(.center)
                    .environment(\.layoutDirection, .rightToLeft)
                Text(segment.suraEnglishName)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(Theme.textSecondary)
                    .tracking(0.5)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Theme.accent.opacity(0.25), lineWidth: 0.5))
            )
            ornamentalRule
        }
        .padding(.vertical, 8)
        .environment(\.layoutDirection, .leftToRight)
    }

    private var ornamentalRule: some View {
        HStack(spacing: 4) {
            Rectangle().frame(height: 0.5).foregroundColor(Theme.accent.opacity(0.4))
            Circle().frame(width: 4, height: 4).foregroundColor(Theme.accent.opacity(0.6))
            Circle().frame(width: 3, height: 3).foregroundColor(Theme.accent.opacity(0.4))
            Circle().frame(width: 4, height: 4).foregroundColor(Theme.accent.opacity(0.6))
            Rectangle().frame(height: 0.5).foregroundColor(Theme.accent.opacity(0.4))
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var bismillahView: some View {
        Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
            .font(kArabicFont.font(size: arabicFontSize))
            .foregroundColor(primaryText)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)
            .environment(\.layoutDirection, .rightToLeft)
    }

    private func mushafTextBlock(for ayahs: [MushafAyah]) -> some View {
        // Segments carry the global ayah ID so JustifiedArabicText can look up
        // the tajweed HTML from mushafTajweedCache without extra plumbing.
        let segments: [(text: String, isMarker: Bool, ayahID: Int)] = ayahs.flatMap { ayah in
            [(ayah.text, false, ayah.id),
             (" \(ayahMarker(ayah.numberInSurah)) ", true, -1)]
        }
        let bodyUIFont   = QuranArabicFont.getHafsUIFont(size: arabicFontSize)
        let markerUIFont = UIFont.systemFont(ofSize: max(arabicFontSize - 7, 10))
        return JustifiedArabicText(
            segments: segments,
            bodyFont: bodyUIFont,
            markerFont: markerUIFont,
            tajweedEnabled: appState.isTajweedEnabled,
            tajweedCache: store.mushafTajweedCache,
            readingMode: readingMode
        )
        .frame(maxWidth: .infinity)
    }

    private func pageFooterView(pageNum: Int) -> some View {
        HStack(spacing: 8) {
            Rectangle().frame(width: 24, height: 0.5).foregroundColor(Theme.accent.opacity(0.4))
            Text(toEasternArabic(pageNum)).font(.caption.weight(.medium)).foregroundColor(Theme.textSecondary)
            Rectangle().frame(width: 24, height: 0.5).foregroundColor(Theme.accent.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: - Bottom Navigation Bar

    private var bottomBar: some View {
        HStack {
            Button(action: {
                if store.currentMushafPageNumber > 1 { store.currentMushafPageNumber -= 1 }
            }) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(store.currentMushafPageNumber > 1 ? Theme.accent : Theme.textSecondary.opacity(0.3))
            }
            .disabled(store.currentMushafPageNumber <= 1)

            Spacer()

            Button(action: { showPageJump = true }) {
                Text("\(store.currentMushafPageNumber) / \(QuranStore.totalPages)")
                    .font(.subheadline.weight(.medium).monospacedDigit())
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Theme.cardBackground))
            }
            .alert(L10n.quranPage(language), isPresented: $showPageJump) {
                TextField("1–604", text: $pageInput).keyboardType(.numberPad)
                Button(L10n.settingsDone(language)) {
                    if let p = Int(pageInput) { store.goToMushafPage(p) }
                    pageInput = ""
                }
                Button("Abbrechen", role: .cancel) { pageInput = "" }
            } message: {
                Text("\(L10n.quranPage(language)) (1–\(QuranStore.totalPages))")
            }

            Spacer()

            Button(action: {
                if store.currentMushafPageNumber < QuranStore.totalPages { store.currentMushafPageNumber += 1 }
            }) {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(store.currentMushafPageNumber < QuranStore.totalPages ? Theme.accent : Theme.textSecondary.opacity(0.3))
            }
            .disabled(store.currentMushafPageNumber >= QuranStore.totalPages)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.cardBackground.opacity(0.95))
    }

    // MARK: - Page Segment Helpers

    private struct PageSegment: Identifiable {
        let id: Int
        let suraNumber: Int
        let suraName: String
        let suraEnglishName: String
        let isFirstOnPage: Bool
        let showBismillah: Bool
        let ayahs: [MushafAyah]
    }

    private func pageSegments(for page: MushafPage) -> [PageSegment] {
        var result: [PageSegment] = []
        var currentSura = -1, currentName = "", currentEN = "", batch: [MushafAyah] = []
        var isFirst = false

        func flush() {
            guard !batch.isEmpty else { return }
            result.append(PageSegment(
                id: currentSura, suraNumber: currentSura,
                suraName: currentName, suraEnglishName: currentEN,
                isFirstOnPage: isFirst,
                showBismillah: isFirst && currentSura != 1 && currentSura != 9,
                ayahs: batch))
        }
        for ayah in page.ayahs {
            if ayah.suraNumber != currentSura {
                flush()
                currentSura = ayah.suraNumber; currentName = ayah.suraName
                currentEN = ayah.suraEnglishName; isFirst = ayah.numberInSurah == 1
                batch = [ayah]
            } else { batch.append(ayah) }
        }
        flush()
        return result
    }

    // MARK: - Numeral Helpers

    private func toEasternArabic(_ number: Int) -> String {
        let digits = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(number).map { c in
            guard let d = Int(String(c)) else { return String(c) }
            return digits[d]
        }.joined()
    }

    private func ayahMarker(_ number: Int) -> String { "﴿\(number)﴾" }
}

// MARK: - Translation Bottom Sheet

private struct TranslationBottomSheet: View {
    let pageNumber: Int
    @ObservedObject var store: QuranStore
    let translationOption: QuranTranslationOption
    let language: AppLanguage

    private var edition: String? { QuranStore.translationEdition(for: translationOption) }
    private var translations: [TranslationAyah] { store.pageTranslationCache[pageNumber] ?? [] }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if translationOption == .none {
                    noTranslationPlaceholder
                } else if store.isLoadingTranslations && translations.isEmpty {
                    ProgressView().tint(Theme.accent).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    translationList
                }
            }
            .navigationTitle(L10n.quranTranslation(language) + " – \(L10n.quranPage(language)) \(pageNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            guard let ed = edition else { return }
            Task { await store.loadPageTranslation(pageNumber, edition: ed) }
        }
    }

    private var translationList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(translations.enumerated()), id: \.element.id) { idx, ayah in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "diamond.fill").font(.system(size: 6)).foregroundColor(Theme.iconFajr)
                            Text("\(ayah.suraName)  \(ayah.suraNumber):\(ayah.numberInSurah)")
                                .font(.caption.weight(.medium)).foregroundColor(Theme.iconFajr)
                        }
                        Text(ayah.text).font(.body).foregroundColor(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 12).padding(.horizontal, 20)
                    if idx < translations.count - 1 {
                        Divider().background(Theme.textSecondary.opacity(0.15)).padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    private var noTranslationPlaceholder: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.book.closed").font(.largeTitle).foregroundColor(Theme.textSecondary.opacity(0.5))
            Text("Keine Übersetzung gewählt.\nBitte in den Einstellungen aktivieren.")
                .font(.subheadline).foregroundColor(Theme.textSecondary).multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - RTL Flow Layout (iOS 16+)

private struct RTLWordFlowLayout: Layout {
    var horizontalSpacing: CGFloat = 5
    var verticalSpacing: CGFloat = 8

    private struct Row {
        var items: [(subview: LayoutSubview, size: CGSize)] = []
        var maxHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.replacingUnspecifiedDimensions().width
        let rows = computeRows(subviews: subviews, containerWidth: containerWidth)
        let totalHeight = rows.enumerated().reduce(CGFloat(0)) { acc, el in
            acc + el.element.maxHeight + (el.offset < rows.count - 1 ? verticalSpacing : 0)
        }
        return CGSize(width: containerWidth, height: max(totalHeight, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(subviews: subviews, containerWidth: bounds.width)
        var yPos = bounds.minY
        for row in rows {
            var xPos = bounds.maxX
            for item in row.items {
                xPos -= item.size.width
                item.subview.place(at: CGPoint(x: xPos, y: yPos), proposal: ProposedViewSize(item.size))
                xPos -= horizontalSpacing
            }
            yPos += row.maxHeight + verticalSpacing
        }
    }

    private func computeRows(subviews: Subviews, containerWidth: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let last = rows.last!
            let addedWidth = last.totalWidth + size.width + (last.items.isEmpty ? 0 : horizontalSpacing)
            if addedWidth > containerWidth && !last.items.isEmpty {
                rows.append(Row(items: [(subview, size)], maxHeight: size.height, totalWidth: size.width))
            } else {
                rows[rows.count - 1].items.append((subview, size))
                rows[rows.count - 1].maxHeight = max(rows[rows.count - 1].maxHeight, size.height)
                rows[rows.count - 1].totalWidth = addedWidth
            }
        }
        return rows
    }
}

// MARK: - List View with Tajweed + Transliteration + Translation

struct QuranListView: View {
    @ObservedObject var store: QuranStore
    let arabicFontSize: CGFloat
    let translationOption: QuranTranslationOption
    let isTajweedEnabled: Bool
    let readingMode: Bool

    @State private var selectedWord: String? = nil
    @State private var showWordSheet = false

    private var primaryText: Color { readingMode ? .black : Theme.textPrimary }
    private var secondaryText: Color { readingMode ? Color(hex: "555555") : Theme.textSecondary }
    private var rowBg: Color { readingMode ? .white : Theme.cardBackground }
    private var tajweedDefault: Color { readingMode ? .black : Theme.tajweedDefault }

    var body: some View {
        Group {
            if store.currentSuraVerses.isEmpty && store.isLoading {
                ProgressView().tint(Theme.accent).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.allVerses.isEmpty {
                ContentUnavailableView(
                    "Keine Verse", systemImage: "book.closed",
                    description: Text("Verse konnten nicht geladen werden.")
                )
                .foregroundColor(Theme.textSecondary)
            } else {
                List {
                    // Bismillah header (except Surah 1 and 9)
                    if let surahNum = store.selectedSuraNumber,
                       surahNum != 1, surahNum != 9,
                       !store.allVerses.isEmpty {
                        Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                            .font(kArabicFont.font(size: arabicFontSize))
                            .foregroundColor(Theme.iconFajr)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                            .environment(\.layoutDirection, .rightToLeft)
                            .listRowBackground(rowBg)
                            .listRowSeparator(.hidden)
                    }

                    ForEach(store.allVerses) { verse in
                        VStack(alignment: .trailing, spacing: 10) {

                            // 1. Arabic text
                            // When Tajweed is on we always use the AttributedString path so the
                            // layout never jumps: plain Hafs/white is shown while the API call
                            // is in-flight, then colours appear once the HTML data arrives.
                            if isTajweedEnabled {
                                let tajweedHTML = store.suraTajweedTexts[verse.verseNumber]
                                Text(QuranStore.parseTajweedAttributedString(
                                    tajweedHTML ?? verse.arabic,
                                    fontSize: arabicFontSize,
                                    enabled: tajweedHTML != nil,
                                    defaultColor: tajweedDefault
                                ))
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .environment(\.layoutDirection, .rightToLeft)
                            } else {
                                // Sanitize through the same whitelist as the Tajweed path so
                                // characters the KFGQPC font can't render don't appear as circles.
                                let words = TajweedParser.stripAllTags(verse.arabic)
                                    .split(separator: " ")
                                    .map(String.init)
                                    .filter { !$0.isEmpty }

                                RTLWordFlowLayout(horizontalSpacing: 4, verticalSpacing: 6) {
                                    ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                                        Button(action: {
                                            selectedWord = word
                                            showWordSheet = true
                                        }) {
                                            Text(word)
                                                .font(kArabicFont.font(size: arabicFontSize))
                                                .foregroundColor(primaryText)
                                                .padding(.horizontal, 3)
                                                .padding(.vertical, 2)
                                                .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }

                            // 2. Transliteration (DIN 31635)
                            if let translit = store.suraTransliterationTexts[verse.verseNumber],
                               !translit.isEmpty {
                                Text(translit)
                                    .font(.subheadline.italic())
                                    .foregroundColor(secondaryText.opacity(0.8))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            // 3. Translation (German / English)
                            if translationOption != .none,
                               let translation = store.suraTranslationTexts[verse.verseNumber],
                               !translation.isEmpty {
                                Divider().background(secondaryText.opacity(0.15))
                                Text(translation)
                                    .font(.subheadline)
                                    .foregroundColor(secondaryText)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            // Verse reference
                            Text("﴿ \(verse.suraNumber):\(verse.verseNumber) ﴾")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(Theme.accent.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(rowBg)
                        .listRowSeparatorTint(secondaryText.opacity(0.2))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }
            }
        }
        .task(id: translationOption) {
            guard let surahNum = store.selectedSuraNumber,
                  let edition = QuranStore.translationEdition(for: translationOption) else { return }
            await store.loadSuraTranslation(surahNum, edition: edition)
        }
        .task(id: store.selectedSuraNumber) {
            guard let surahNum = store.selectedSuraNumber else { return }
            async let translit: () = store.loadSuraTransliteration(surahNum)
            async let tajweed: () = store.loadSuraTajweed(surahNum)
            _ = await (translit, tajweed)
        }
        .sheet(isPresented: $showWordSheet) {
            if let word = selectedWord {
                WordTranslationSheet(word: word)
                    .presentationDetents([.height(240)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Theme.background)
            }
        }
    }
}

// MARK: - Word Translation Sheet

private struct WordTranslationSheet: View {
    let word: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Theme.textSecondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            Text(word)
                .font(.system(size: 52, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.top, 4)

            ornamentalDivider

            VStack(spacing: 6) {
                Text("Wort-für-Wort Übersetzung")
                    .font(.caption.weight(.medium))
                    .tracking(0.6)
                    .foregroundColor(Theme.textSection)
                Text("Übersetzung: \(word)")
                    .font(.title3.weight(.medium))
                    .foregroundColor(Theme.accent)
                    .multilineTextAlignment(.center)
                Text("Vollständige Wortdatenbank demnächst verfügbar.")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .background(Theme.background)
    }

    private var ornamentalDivider: some View {
        HStack(spacing: 6) {
            Rectangle().frame(height: 0.5).foregroundColor(Theme.iconFajr.opacity(0.4))
            Image(systemName: "diamond.fill").font(.system(size: 5)).foregroundColor(Theme.iconFajr.opacity(0.7))
            Rectangle().frame(height: 0.5).foregroundColor(Theme.iconFajr.opacity(0.4))
        }
    }
}

// MARK: - Settings Sheet (font size, translation, tajweed toggle — no font picker)

struct QuranSettingsSheet: View {
    let language: AppLanguage
    @Binding var arabicFontSize: CGFloat
    @Binding var translationOption: QuranTranslationOption
    @Binding var isTajweedEnabled: Bool
    @Binding var isReadingModeEnabled: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.quranFontSize(language)) {
                    Slider(value: $arabicFontSize, in: 14...36, step: 2)
                    Text("\(Int(arabicFontSize)) pt").font(.caption).foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Theme.cardBackground)

                Section(L10n.quranTranslation(language)) {
                    Picker(L10n.quranTranslation(language), selection: $translationOption) {
                        Text(L10n.quranNone(language)).tag(QuranTranslationOption.none)
                        Text("Deutsch").tag(QuranTranslationOption.german)
                        Text("English").tag(QuranTranslationOption.english)
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.accent)
                    .foregroundStyle(Theme.textPrimary)
                    .listRowBackground(Theme.cardBackground)
                }

                Section(L10n.quranTajweed(language)) {
                    Toggle(L10n.quranTajweed(language), isOn: $isTajweedEnabled)
                        .tint(Theme.accent)
                        .foregroundStyle(Theme.textPrimary)
                }
                .listRowBackground(Theme.cardBackground)

                Section {
                    Toggle(L10n.quranReadingMode(language), isOn: $isReadingModeEnabled)
                        .tint(Theme.accent)
                        .foregroundStyle(Theme.textPrimary)
                    Text(L10n.quranReadingModeDescription(language))
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                } header: {
                    Text(L10n.quranReadingMode(language))
                }
                .listRowBackground(Theme.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(L10n.settingsTitle(language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.settingsDone(language)) { dismiss() }.foregroundColor(Theme.accent)
                }
            }
        }
    }
}

// JustifiedArabicText moved to DeenApp/Views/Components/JustifiedArabicText.swift

// MARK: - Preview

#Preview {
    QuranView()
        .environmentObject(AppState())
}
