//
//  QuranWord.swift
//  DeenApp
//
//  Ein häufig vorkommendes Quran-Wort für Karteikarten (80%-Wortschatz).
//

import Foundation

struct QuranWord: Identifiable, Decodable {
    let id: String
    let arabic: String
    let meaningDE: String
    let meaningEN: String
    let root: String?
    let frequency: Int?

    enum CodingKeys: String, CodingKey {
        case id, arabic, meaningDE = "meaning_de", meaningEN = "meaning_en", root, frequency
    }
}

struct QuranWordsDeck: Decodable {
    let words: [QuranWord]
}
