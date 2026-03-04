//
//  QuranStore.swift
//  DeenApp
//
//  Lädt Surenliste, Sura-Inhalt und Mushaf-Seiten über api.alquran.cloud.
//

import SwiftUI
import Combine

private let baseURL = "https://api.alquran.cloud/v1"
private let kLastReadPage = "lastReadMushafPage"

@MainActor
final class QuranStore: ObservableObject {

    // MARK: - Surenliste (für Picker & Listenansicht)
    @Published private(set) var suraList: [QuranSuraInfo] = []
    @Published private(set) var currentSuraVerses: [QuranVerse] = []
    @Published private(set) var selectedSuraNumber: Int?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    // MARK: - Mushaf (604 Seiten) — wird in UserDefaults persistiert
    @Published var currentMushafPageNumber: Int {
        didSet {
            UserDefaults.standard.set(currentMushafPageNumber, forKey: kLastReadPage)
        }
    }
    @Published private(set) var mushafPageCache: [Int: MushafPage] = [:]
    @Published private(set) var isMushafLoading = false

    /// Tajweed HTML keyed by **global Quran ayah number** (same as MushafAyah.id).
    /// Populated automatically inside loadMushafPage — no separate load step needed.
    @Published private(set) var mushafTajweedCache: [Int: String] = [:]

    // MARK: - Sura-Übersetzungstexte (numberInSurah → übersetzter Text)
    @Published private(set) var suraTranslationTexts: [Int: String] = [:]
    @Published private(set) var isLoadingTranslationTexts = false

    // MARK: - Sura-Transliteration (numberInSurah → transliteration text)
    @Published private(set) var suraTransliterationTexts: [Int: String] = [:]
    @Published private(set) var isLoadingTransliteration = false

    // MARK: - Tajweed raw HTML cache (numberInSurah → tagged string)
    @Published private(set) var suraTajweedTexts: [Int: String] = [:]
    @Published private(set) var isLoadingTajweed = false

    // MARK: - Übersetzungs-Cache (Seitennummer → [TranslationAyah])
    @Published private(set) var pageTranslationCache: [Int: [TranslationAyah]] = [:]
    @Published private(set) var isLoadingTranslations = false

    /// Gesamtzahl der Seiten im Mushaf
    static let totalPages = 604

    // MARK: - Erste Mushaf-Seite je Sure (Standard Hafs Uthmani 15-Zeilen-Layout)
    static let surahFirstPage: [Int: Int] = [
         1: 1,   2: 2,   3: 50,  4: 77,  5: 106,  6: 128,  7: 151,  8: 177,  9: 187, 10: 208,
        11: 221, 12: 235, 13: 249, 14: 255, 15: 262, 16: 267, 17: 282, 18: 293, 19: 305, 20: 312,
        21: 322, 22: 332, 23: 342, 24: 350, 25: 359, 26: 367, 27: 377, 28: 385, 29: 396, 30: 404,
        31: 411, 32: 415, 33: 418, 34: 428, 35: 434, 36: 440, 37: 446, 38: 453, 39: 458, 40: 467,
        41: 477, 42: 483, 43: 489, 44: 496, 45: 499, 46: 502, 47: 507, 48: 511, 49: 515, 50: 518,
        51: 520, 52: 523, 53: 526, 54: 528, 55: 531, 56: 534, 57: 537, 58: 542, 59: 545, 60: 549,
        61: 551, 62: 553, 63: 554, 64: 556, 65: 558, 66: 560, 67: 562, 68: 564, 69: 566, 70: 568,
        71: 570, 72: 572, 73: 574, 74: 575, 75: 577, 76: 578, 77: 580, 78: 582, 79: 583, 80: 585,
        81: 586, 82: 587, 83: 587, 84: 589, 85: 590, 86: 591, 87: 591, 88: 592, 89: 593, 90: 594,
        91: 595, 92: 595, 93: 596, 94: 596, 95: 597, 96: 597, 97: 598, 98: 598, 99: 599,100: 599,
       101: 600,102: 600,103: 601,104: 601,105: 601,106: 602,107: 602,108: 602,109: 603,110: 603,
       111: 603,112: 604,113: 604,114: 604
    ]

    // MARK: - Juz starting pages (standard Hafs 15-line Mushaf layout)

    /// First page of each Juz (1–30) in the standard KFGQPC 604-page Mushaf.
    static let juzFirstPage: [Int: Int] = [
         1:   1,  2:  22,  3:  42,  4:  62,  5:  82,
         6: 102,  7: 121,  8: 142,  9: 162, 10: 182,
        11: 201, 12: 221, 13: 242, 14: 262, 15: 282,
        16: 302, 17: 322, 18: 342, 19: 362, 20: 382,
        21: 402, 22: 422, 23: 442, 24: 462, 25: 482,
        26: 502, 27: 522, 28: 542, 29: 562, 30: 582,
    ]

    /// Nur für Abwärtskompatibilität (pages/allVerses aus aktueller Sura)
    var allVerses: [QuranVerse] { currentSuraVerses }
    var pages: [QuranPage] {
        let versesPerPage = 15
        guard !currentSuraVerses.isEmpty else { return [] }
        return stride(from: 0, to: currentSuraVerses.count, by: versesPerPage).enumerated().map { index, start in
            let end = min(start + versesPerPage, currentSuraVerses.count)
            return QuranPage(id: index + 1, verses: Array(currentSuraVerses[start..<end]))
        }
    }

    init() {
        let saved = UserDefaults.standard.integer(forKey: kLastReadPage)
        currentMushafPageNumber = saved > 0 ? saved : 1
        Task { await loadSuraList() }
    }

    // MARK: - Arabischer Text: Sanitisierung

    /// Entfernt Rendering-Artefakte aus dem Uthmani-Text (Kreise, Waqf-Zeichen, BOM, etc.)
    private func sanitizeArabicText(_ text: String) -> String {
        // Stripped Unicode ranges:
        // U+0600–U+0605   Arabic number signs / special prefixes
        // U+0610–U+061A   Arabic extended signs (small high marks, etc.)
        // U+06D6–U+06ED   Full Quranic annotation block (Waqf/pause markers, end-of-ayah circles, etc.)
        //                 Includes U+06DD (Arabic End of Ayah circle) explicitly
        // U+FD3E–U+FD3F   Ornate Arabic parentheses
        // U+200B–U+200F   Zero-width / directional control chars
        // U+2028–U+2029   Line/paragraph separators
        // U+FEFF          BOM / Zero Width No-Break Space
        let rangesToStrip: [ClosedRange<Unicode.Scalar>] = [
            "\u{0600}"..."\u{0605}",
            "\u{0610}"..."\u{061A}",
            "\u{06D6}"..."\u{06ED}",  // covers 06DD (end-of-ayah) and all Waqf marks
            "\u{FD3E}"..."\u{FD3F}",
            "\u{200B}"..."\u{200F}",
            "\u{2028}"..."\u{2029}"
        ]
        let singleChars: [Unicode.Scalar] = ["\u{FEFF}"]

        var unwanted = CharacterSet()
        for range in rangesToStrip { unwanted.insert(charactersIn: range) }
        for scalar in singleChars  { unwanted.insert(scalar) }

        return text.unicodeScalars
            .filter { !unwanted.contains($0) }
            .reduce(into: "") { $0.append(Character($1)) }
    }

    // MARK: - Bismillah-Stripping

    /// Known Bismillah prefix variants as they appear in the alquran.cloud API responses.
    /// The Uthmanic HAFS edition uses ٱ (U+0671, alef wasla) in "ٱللَّهِ" etc.
    private static let bismillahPrefixes: [String] = [
        "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",   // Uthmanic (alef wasla)
        "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",     // standard alef
        "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",      // simplified harakat variant
        "بسم الله الرحمن الرحيم",                       // unvocalised
    ]

    /// Strips the Bismillah prefix (and any leading/trailing whitespace) from a verse text.
    /// Only applies when `suraNumber != 1` (Surah 1 verse 1 IS the Bismillah).
    private func stripBismillahIfNeeded(from text: String, suraNumber: Int) -> String {
        guard suraNumber != 1 else { return text }
        for prefix in Self.bismillahPrefixes {
            if text.hasPrefix(prefix) {
                return String(text.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespaces)
            }
        }
        return text
    }

    // MARK: - Surenliste

    func loadSuraList() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        guard let url = URL(string: "\(baseURL)/surah") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let res = try JSONDecoder().decode(AlquranSurahListResponse.self, from: data)
            guard res.code == 200 else { error = "API Fehler"; return }
            suraList = res.data.map { item in
                QuranSuraInfo(
                    number: item.number,
                    nameArabic: item.name,
                    nameTransliteration: item.englishName,
                    nameTranslation: item.englishNameTranslation,
                    numberOfAyahs: item.numberOfAyahs,
                    pageNumber: Self.surahFirstPage[item.number] ?? 1
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func selectSura(_ number: Int) {
        selectedSuraNumber = number
        suraTranslationTexts = [:]
        suraTransliterationTexts = [:]
        suraTajweedTexts = [:]
        Task { await loadSura(number) }
    }

    func clearSuraSelection() {
        selectedSuraNumber = nil
        currentSuraVerses = []
        suraTranslationTexts = [:]
        suraTransliterationTexts = [:]
        suraTajweedTexts = [:]
    }

    func loadSura(_ number: Int) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        guard let url = URL(string: "\(baseURL)/surah/\(number)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let res = try JSONDecoder().decode(AlquranSurahDetailResponse.self, from: data)
            guard res.code == 200 else { error = "API Fehler"; return }
            let suraNumber = res.data.number
            currentSuraVerses = res.data.ayahs.map { ayah in
                let rawArabic = sanitizeArabicText(ayah.text.trimmingCharacters(in: .whitespacesAndNewlines))
                let cleanArabic = stripBismillahIfNeeded(from: rawArabic, suraNumber: suraNumber)
                return QuranVerse(
                    id: ayah.number,
                    suraNumber: suraNumber,
                    verseNumber: ayah.numberInSurah,
                    arabic: cleanArabic,
                    translationEN: nil,
                    translationDE: nil
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Sura-Übersetzung für Listenansicht

    func loadSuraTranslation(_ number: Int, edition: String) async {
        isLoadingTranslationTexts = true
        defer { isLoadingTranslationTexts = false }
        guard let url = URL(string: "\(baseURL)/surah/\(number)/\(edition)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let res = try JSONDecoder().decode(AlquranSurahDetailResponse.self, from: data)
            guard res.code == 200 else { return }
            suraTranslationTexts = res.data.ayahs.reduce(into: [:]) { dict, ayah in
                dict[ayah.numberInSurah] = ayah.text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch { /* Fehler still behandelt */ }
    }

    // MARK: - Mushaf Pages

    func loadMushafPage(_ pageNumber: Int) async {
        guard pageNumber >= 1, pageNumber <= QuranStore.totalPages else { return }
        if mushafPageCache[pageNumber] != nil { return }

        isMushafLoading = true
        defer { isMushafLoading = false }

        // Use the tajweed edition as the single source of truth.
        // The raw HTML is cached for coloured rendering; tags are stripped for plain display.
        guard let url = URL(string: "\(baseURL)/page/\(pageNumber)/\(Self.tajweedEdition)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let res = try JSONDecoder().decode(AlquranPageResponse.self, from: data)
            guard res.code == 200 else { return }
            let ayahs = res.data.ayahs.map { a -> MushafAyah in
                // Store raw tajweed HTML for JustifiedArabicText coloured rendering
                mushafTajweedCache[a.number] = a.text
                // Strip tags → sanitize → remove Bismillah prefix for plain-text display
                let stripped = TajweedParser.stripAllTags(a.text)
                let rawText  = sanitizeArabicText(stripped.trimmingCharacters(in: .whitespacesAndNewlines))
                let cleanText = stripBismillahIfNeeded(from: rawText, suraNumber: a.surah.number)
                return MushafAyah(
                    id: a.number,
                    text: cleanText,
                    numberInSurah: a.numberInSurah,
                    suraNumber: a.surah.number,
                    suraName: a.surah.name,
                    suraEnglishName: a.surah.englishName,
                    juz: a.juz
                )
            }
            mushafPageCache[pageNumber] = MushafPage(id: pageNumber, ayahs: ayahs)
        } catch { }
    }

    func preloadMushafPages(around page: Int) async {
        let pagesToLoad = [page - 1, page, page + 1].filter {
            $0 >= 1 && $0 <= QuranStore.totalPages && mushafPageCache[$0] == nil
        }
        for p in pagesToLoad {
            await loadMushafPage(p)
        }
    }

    func goToMushafPage(_ page: Int) {
        let clamped = min(max(page, 1), QuranStore.totalPages)
        currentMushafPageNumber = clamped
        Task { await preloadMushafPages(around: clamped) }
    }

    /// Returns the Surah number whose text starts on or before `page`.
    /// Prefers the live page cache (first ayah's sura); falls back to the static lookup table.
    func surahNumberForMushafPage(_ page: Int) -> Int {
        if let cached = mushafPageCache[page], let first = cached.ayahs.first {
            return first.suraNumber
        }
        let matches = Self.surahFirstPage.filter { $0.value <= page }
        return matches.max(by: { $0.key < $1.key })?.key ?? 1
    }


    // MARK: - Seiten-Übersetzungen (Bottom-Sheet)

    func loadPageTranslation(_ pageNumber: Int, edition: String) async {
        guard pageTranslationCache[pageNumber] == nil else { return }
        isLoadingTranslations = true
        defer { isLoadingTranslations = false }

        guard let url = URL(string: "\(baseURL)/page/\(pageNumber)/\(edition)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let res = try JSONDecoder().decode(AlquranPageResponse.self, from: data)
            guard res.code == 200 else { return }
            pageTranslationCache[pageNumber] = res.data.ayahs.map { a in
                TranslationAyah(
                    id: a.number,
                    numberInSurah: a.numberInSurah,
                    suraNumber: a.surah.number,
                    suraName: a.surah.englishName,
                    text: a.text.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
        } catch { /* Fehler still behandelt */ }
    }

    static func translationEdition(for option: QuranTranslationOption) -> String? {
        switch option {
        case .none:    return nil
        case .german:  return "de.aburida"
        case .english: return "en.sahih"
        }
    }

    // MARK: - Transliteration

    static let transliterationEdition = "en.transliteration"

    func loadSuraTransliteration(_ number: Int) async {
        isLoadingTransliteration = true
        defer { isLoadingTransliteration = false }
        guard let url = URL(string: "\(baseURL)/surah/\(number)/\(Self.transliterationEdition)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let res = try JSONDecoder().decode(AlquranSurahDetailResponse.self, from: data)
            guard res.code == 200 else { return }
            suraTransliterationTexts = res.data.ayahs.reduce(into: [:]) { dict, ayah in
                dict[ayah.numberInSurah] = ayah.text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch { /* silently handled */ }
    }

    // MARK: - Tajweed (ar.tajweed edition returns HTML-tagged Arabic)

    static let tajweedEdition = "quran-tajweed"

    func loadSuraTajweed(_ number: Int) async {
        isLoadingTajweed = true
        defer { isLoadingTajweed = false }
        guard let url = URL(string: "\(baseURL)/surah/\(number)/\(Self.tajweedEdition)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let res = try JSONDecoder().decode(AlquranSurahDetailResponse.self, from: data)
            guard res.code == 200 else { return }
            suraTajweedTexts = res.data.ayahs.reduce(into: [:]) { dict, ayah in
                dict[ayah.numberInSurah] = ayah.text
            }
        } catch { /* silently handled */ }
    }

    // MARK: - Tajweed → AttributedString Parser

    /// Parses the HTML-tagged Tajweed text into a SwiftUI AttributedString.
    /// Delegates all work to `TajweedParser` which handles multiple tag formats:
    ///   • <tajweed class="rule">…</tajweed>
    ///   • <ghunna>…</ghunna> and other named semantic tags
    ///   • <font color="#rrggbb">…</font>
    static func parseTajweedAttributedString(
        _ taggedHTML: String,
        fontSize: CGFloat,
        enabled: Bool
    ) -> AttributedString {
        TajweedParser.parse(taggedHTML, fontSize: fontSize, enabled: enabled)
    }

    // MARK: - Juz Boundaries (first Surah number in each of the 30 Juz)

    static let juzFirstSurah: [(juz: Int, firstSurah: Int)] = [
        (1, 1), (2, 2), (3, 2), (4, 3), (5, 4), (6, 4), (7, 5), (8, 6), (9, 7), (10, 8),
        (11, 9), (12, 11), (13, 12), (14, 15), (15, 17), (16, 18), (17, 21), (18, 23),
        (19, 25), (20, 27), (21, 29), (22, 33), (23, 36), (24, 39), (25, 41), (26, 46),
        (27, 51), (28, 58), (29, 67), (30, 78)
    ]

    /// Returns the Juz number for a given Surah number.
    static func juzForSurah(_ surahNumber: Int) -> Int {
        for i in stride(from: juzFirstSurah.count - 1, through: 0, by: -1) {
            if surahNumber >= juzFirstSurah[i].firstSurah {
                return juzFirstSurah[i].juz
            }
        }
        return 1
    }
}

// MARK: - Surenlisten-Modell (mit Mushaf-Seitennummer)

struct QuranSuraInfo: Identifiable {
    let id: Int
    let number: Int
    let nameArabic: String
    let nameTransliteration: String
    let nameTranslation: String
    let numberOfAyahs: Int
    /// Erste Seite dieser Sure im 604-seitigen Hafs-Mushaf
    let pageNumber: Int

    init(number: Int, nameArabic: String, nameTransliteration: String,
         nameTranslation: String, numberOfAyahs: Int, pageNumber: Int) {
        self.id = number
        self.number = number
        self.nameArabic = nameArabic
        self.nameTransliteration = nameTransliteration
        self.nameTranslation = nameTranslation
        self.numberOfAyahs = numberOfAyahs
        self.pageNumber = pageNumber
    }
}
