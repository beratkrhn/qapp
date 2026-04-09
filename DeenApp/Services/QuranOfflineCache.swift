//
//  QuranOfflineCache.swift
//  DeenApp
//
//  Persistent raw-data cache for all alquran.cloud API responses.
//  QuranStore (the @MainActor caller) handles all JSON encoding/decoding;
//  this actor only reads and writes opaque Data blobs so there are no
//  Swift concurrency actor-isolation issues.
//
//  Cache key helpers  (static, call-site friendly)
//  ────────────────────────────────────────────────
//  QuranOfflineCache.keyForSurahList()
//  QuranOfflineCache.keyForSurah(3)               // default Uthmanic edition
//  QuranOfflineCache.keyForSurah(3, "quran-tajweed")
//  QuranOfflineCache.keyForPage(42)
//

import Foundation

actor QuranOfflineCache {

    static let shared = QuranOfflineCache()

    private let cacheDir: URL

    private init() {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? FileManager.default.temporaryDirectory
        cacheDir = support.appendingPathComponent("QuranCache", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: cacheDir, withIntermediateDirectories: true, attributes: nil
        )
    }

    // MARK: - Key helpers

    static func keyForSurahList() -> String { "surah_list" }

    static func keyForSurah(_ number: Int, _ edition: String = "") -> String {
        edition.isEmpty
            ? "surah_\(number)"
            : "surah_\(number)_\(edition.replacingOccurrences(of: ".", with: "_"))"
    }

    static func keyForPage(_ number: Int) -> String { "page_\(number)" }

    // MARK: - Raw data I/O

    func data(forKey key: String) -> Data? {
        try? Data(contentsOf: fileURL(key))
    }

    func store(_ data: Data, forKey key: String) {
        try? data.write(to: fileURL(key), options: .atomic)
    }

    func hasData(forKey key: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(key).path)
    }

    // MARK: - Private

    private func fileURL(_ key: String) -> URL {
        cacheDir.appendingPathComponent(key + ".json")
    }
}
