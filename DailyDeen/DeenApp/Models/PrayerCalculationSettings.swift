//
//  PrayerCalculationSettings.swift
//  DeenApp
//
//  Aladhan presets (inkl. Fazilet) und vollständig benutzerdefinierte Winkel + Minuten-Offsets.
//

import Foundation

// MARK: - Presets (Aladhan `method` oder Spezialfall Fazilet)

enum AladhanPresetCalculation: String, CaseIterable, Identifiable, Codable {
    case ditib = "ditib"
    case mwl = "mwl"
    case isna = "isna"
    case egypt = "egypt"
    case karachi = "karachi"
    case fazilet = "fazilet"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ditib:   return "DITIB (Diyanet)"
        case .mwl:     return "Muslim World League"
        case .isna:    return "ISNA"
        case .egypt:   return "Ägyptische Behörde"
        case .karachi: return "Karachi"
        case .fazilet: return "Fazilet (Winkel 18° / 17°)"
        }
    }

    /// Standard-Aladhan-Methoden-ID (ohne Fazilet/Custom).
    var aladhanMethodId: Int {
        switch self {
        case .ditib:   return 13
        case .mwl:     return 3
        case .isna:    return 2
        case .egypt:   return 5
        case .karachi: return 1
        case .fazilet: return 99
        }
    }
}

// MARK: - Custom (method=99 + methodSettings + tune)

/// Minuten-Anpassung je Gebetszeit in der Reihenfolge der Aladhan-API `tune`:
/// Imsak, Fajr, Sunrise, Dhuhr, Asr, Maghrib, Sunset, Isha, Midnight
struct CustomPrayerParameters: Codable, Equatable {
    var fajrAngle: Double
    var maghribMinutesAfterSunset: Int
    var ishaAngle: Double

    var offsetImsak: Int
    var offsetFajr: Int
    var offsetSunrise: Int
    var offsetDhuhr: Int
    var offsetAsr: Int
    var offsetMaghrib: Int
    var offsetIsha: Int

    static let `default` = CustomPrayerParameters(
        fajrAngle: 18,
        maghribMinutesAfterSunset: 0,
        ishaAngle: 17,
        offsetImsak: 0,
        offsetFajr: 0,
        offsetSunrise: 0,
        offsetDhuhr: 0,
        offsetAsr: 0,
        offsetMaghrib: 0,
        offsetIsha: 0
    )

    /// `methodSettings`: FajrAngle, Maghrib (Minuten nach Sonnenuntergang oder `null`), Isha-Winkel
    var methodSettingsQueryValue: String {
        let maghribPart = maghribMinutesAfterSunset == 0 ? "null" : "\(maghribMinutesAfterSunset)"
        let fajrStr = trimDecimal(fajrAngle)
        let ishaStr = trimDecimal(ishaAngle)
        return "\(fajrStr),\(maghribPart),\(ishaStr)"
    }

    /// `tune`-Parameter (Sunset + Midnight mit 0).
    var tuneQueryValue: String {
        "\(offsetImsak),\(offsetFajr),\(offsetSunrise),\(offsetDhuhr),\(offsetAsr),\(offsetMaghrib),0,\(offsetIsha),0"
    }

    private func trimDecimal(_ x: Double) -> String {
        if x.rounded() == x { return String(format: "%.0f", x) }
        return String(x)
    }
}

// MARK: - Auswahl: Preset oder Custom

enum PrayerCalculationSettings: Codable, Equatable {
    case preset(AladhanPresetCalculation)
    case custom(CustomPrayerParameters)

    private enum CodingKeys: String, CodingKey { case kind, preset, custom }

    private enum Kind: String, Codable { case preset, custom }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .kind) {
        case .preset:
            self = .preset(try c.decode(AladhanPresetCalculation.self, forKey: .preset))
        case .custom:
            self = .custom(try c.decode(CustomPrayerParameters.self, forKey: .custom))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .preset(let p):
            try c.encode(Kind.preset, forKey: .kind)
            try c.encode(p, forKey: .preset)
        case .custom(let x):
            try c.encode(Kind.custom, forKey: .kind)
            try c.encode(x, forKey: .custom)
        }
    }

    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }

    var presetValue: AladhanPresetCalculation? {
        if case .preset(let p) = self { return p }
        return nil
    }

    var customValue: CustomPrayerParameters? {
        if case .custom(let x) = self { return x }
        return nil
    }
}
