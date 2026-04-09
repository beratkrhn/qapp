//
//  AlquranAPI.swift
//  DeenApp
//
//  API-Modelle für api.alquran.cloud (Surenliste + Sura-Detail mit Versen).
//

import Foundation

// MARK: - Surenliste GET /v1/surah
struct AlquranSurahListResponse: Codable {
    let code: Int
    let data: [AlquranSurahListItem]
}

struct AlquranSurahListItem: Codable, Identifiable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String

    var id: Int { number }
}

// MARK: - Sura-Detail GET /v1/surah/{number}
struct AlquranSurahDetailResponse: Codable {
    let code: Int
    let data: AlquranSurahDetail
}

struct AlquranSurahDetail: Codable, Sendable {
    let number: Int
    let name: String
    let englishName: String
    let numberOfAyahs: Int
    let ayahs: [AlquranAyah]
}

struct AlquranAyah: Codable, Sendable {
    let number: Int
    let text: String
    let numberInSurah: Int
}

// MARK: - Mushaf Page GET /v1/page/{pageNumber}/quran-uthmani

struct AlquranPageResponse: Codable {
    let code: Int
    let data: AlquranPageData
}

struct AlquranPageData: Codable, Sendable {
    let number: Int
    let ayahs: [AlquranPageAyah]
}

struct AlquranPageAyah: Codable, Sendable {
    let number: Int
    let text: String
    let numberInSurah: Int
    let juz: Int
    let page: Int
    let surah: AlquranPageSurah
}

struct AlquranPageSurah: Codable, Sendable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
}
