//
//  DitibModels.swift
//  DeenApp
//
//  Codable models for the Diyanet/DITIB prayer-times API
//  (ezanvakti.imsakiyem.com – official Diyanet data source).
//

import Foundation

// MARK: - Generic API Envelope

struct DitibAPIResponse<T: Decodable>: Decodable {
    let success: Bool
    let code: Int
    let message: String?
    let data: [T]
}

// MARK: - Federal State (Bundesland)

/// A hardcoded German federal state with its Diyanet state_id baked in.
/// The Diyanet state IDs were discovered via the search endpoint in March 2026
/// and are stable identifiers in the ezanvakti.imsakiyem.com API.
struct DitibFederalState: Codable, Identifiable, Hashable {
    let id: String              // ISO 3166-2:DE code (e.g. "bw")
    let name: String            // German name (e.g. "Baden-Württemberg")
    let nameEn: String?         // English name
    let diyanetStateId: String  // Diyanet API state_id (e.g. "850")
}

// MARK: - Selectable City (DITIB District for location picking)

/// A resolved DITIB city/district, persisted when the user selects their location.
/// `id` maps directly to the Diyanet district ID used for prayer-time fetching.
struct DitibCity: Codable, Identifiable, Hashable {
    let id: String          // Diyanet district ID (e.g. "11036" for Augsburg)
    let name: String
    let stateId: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case stateId = "state_id"
    }
}

extension DitibFederalState {
    /// All 16 German federal states with their hardcoded Diyanet state IDs.
    /// Diyanet state IDs confirmed via search endpoint (March 2026).
    static let germanStates: [DitibFederalState] = [
        DitibFederalState(id: "bw", name: "Baden-Württemberg",      nameEn: "Baden-Württemberg",        diyanetStateId: "850"),
        DitibFederalState(id: "by", name: "Bayern",                 nameEn: "Bavaria",                  diyanetStateId: "851"),
        DitibFederalState(id: "be", name: "Berlin",                 nameEn: "Berlin",                   diyanetStateId: "852"),
        DitibFederalState(id: "bb", name: "Brandenburg",            nameEn: "Brandenburg",               diyanetStateId: "853"),
        DitibFederalState(id: "hb", name: "Bremen",                 nameEn: "Bremen",                   diyanetStateId: "854"),
        DitibFederalState(id: "hh", name: "Hamburg",                nameEn: "Hamburg",                  diyanetStateId: "855"),
        DitibFederalState(id: "he", name: "Hessen",                 nameEn: "Hesse",                    diyanetStateId: "856"),
        DitibFederalState(id: "ni", name: "Niedersachsen",          nameEn: "Lower Saxony",             diyanetStateId: "857"),
        DitibFederalState(id: "mv", name: "Mecklenburg-Vorpommern", nameEn: "Mecklenburg-Vorpommern",   diyanetStateId: "858"),
        DitibFederalState(id: "nw", name: "Nordrhein-Westfalen",    nameEn: "North Rhine-Westphalia",   diyanetStateId: "859"),
        DitibFederalState(id: "rp", name: "Rheinland-Pfalz",       nameEn: "Rhineland-Palatinate",     diyanetStateId: "860"),
        DitibFederalState(id: "sl", name: "Saarland",               nameEn: "Saarland",                 diyanetStateId: "861"),
        DitibFederalState(id: "th", name: "Thüringen",              nameEn: "Thuringia",                diyanetStateId: "862"),
        DitibFederalState(id: "sn", name: "Sachsen",                nameEn: "Saxony",                   diyanetStateId: "863"),
        DitibFederalState(id: "st", name: "Sachsen-Anhalt",         nameEn: "Saxony-Anhalt",            diyanetStateId: "864"),
        DitibFederalState(id: "sh", name: "Schleswig-Holstein",     nameEn: "Schleswig-Holstein",       diyanetStateId: "865"),
    ]
}

// MARK: - District (City) Search

struct DitibDistrict: Decodable, Identifiable {
    let id: String
    let name: String
    let nameEn: String?     // optional — some districts may omit this field
    let stateId: String?
    let countryId: String?
    let score: Double?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case nameEn = "name_en"
        case stateId = "state_id"
        case countryId = "country_id"
        case score
    }
}

// MARK: - Daily Prayer Time

struct DitibDailyData: Decodable {
    let date: String
    let times: DitibTimes
    let hijriDate: DitibHijriDate?

    enum CodingKeys: String, CodingKey {
        case date
        case times
        case hijriDate = "hijri_date"
    }
}

struct DitibTimes: Decodable {
    let imsak: String
    let gunes: String
    let ogle: String
    let ikindi: String
    let aksam: String
    let yatsi: String
}

struct DitibHijriDate: Decodable {
    let day: Int?
    let monthName: String?
    let year: Int?
    let fullDate: String?

    enum CodingKeys: String, CodingKey {
        case day
        case monthName = "month_name"
        case year
        case fullDate = "full_date"
    }
}
