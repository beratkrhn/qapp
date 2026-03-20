//
//  QuranWord.swift
//  DeenApp
//
//  Ein häufig vorkommendes Quran-Wort für Karteikarten (80%-Wortschatz).
//

// DailyDeen/DeenApp/Models/QuranWord.swift
import Foundation

struct QuranWord: Identifiable, Codable {
    let id: String
    let arabic: String
    let frequency: Int
    let partOfSpeech: String
    /// Kumulativer Anteil des Quran-Textes „bis zu diesem Wort“ in der Quelldatei — **nicht** der Einzelanteil dieses Worts.
    let percentage: Double
    let meaningEN: String

    private enum CodingKeys: String, CodingKey {
        case id, arabic, frequency, partOfSpeech, percentage, meaningEN
        case meaningDE
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        arabic = try c.decode(String.self, forKey: .arabic)
        frequency = try c.decode(Int.self, forKey: .frequency)
        partOfSpeech = try c.decode(String.self, forKey: .partOfSpeech)
        percentage = try c.decode(Double.self, forKey: .percentage)
        if let m = try c.decodeIfPresent(String.self, forKey: .meaningEN) {
            meaningEN = m
        } else if let legacy = try c.decodeIfPresent(String.self, forKey: .meaningDE) {
            meaningEN = legacy
        } else {
            meaningEN = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(arabic, forKey: .arabic)
        try c.encode(frequency, forKey: .frequency)
        try c.encode(partOfSpeech, forKey: .partOfSpeech)
        try c.encode(percentage, forKey: .percentage)
        try c.encode(meaningEN, forKey: .meaningEN)
    }
}

// MARK: - Quran-Abdeckung (Schätzungen für UI)

enum QuranVocabularyProgress {
    /// Übliche Schätzung der Wortanzahl im Quran (für Vorkommens-/Fortschritts-Quote).
    static let approximateQuranWordCount = 77800

    /// Geschätzter Anteil der **Vorkommen** dieses Worts am Quran (0…100), aus der Häufigkeit.
    static func wordOccurrenceSharePercent(frequency: Int) -> Double {
        (Double(frequency) / Double(approximateQuranWordCount)) * 100.0
    }
}

extension Bundle {
    /// Liefert die URL von `QWords.json` im App-Bundle (Root oder `Resources/`).
    func qwordsJSONURL() -> URL? {
        url(forResource: "QWords", withExtension: "json")
            ?? url(forResource: "QWords", withExtension: "json", subdirectory: "Resources")
    }
}
