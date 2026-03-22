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

// MARK: - District (City) Search

struct DitibDistrict: Decodable, Identifiable {
    let id: String
    let name: String
    let nameEn: String
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
