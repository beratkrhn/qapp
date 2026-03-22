//
//  AladhanResponse.swift
//  DeenApp
//
//  API-Modelle für api.aladhan.com
//

import Foundation

struct AladhanResponse: Decodable {
    let code: Int
    let status: String
    let data: AladhanData
}

struct AladhanData: Decodable {
    let timings: AladhanTimings
    let date: AladhanDate
    let meta: AladhanMeta?
}

struct AladhanTimings: Decodable {
<<<<<<< HEAD
    let imsak: String
    let fajr: String
    let sunrise: String
=======
    let fajr: String
    let sunrise: String?
>>>>>>> origin/claude/adoring-banach
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String

    enum CodingKeys: String, CodingKey {
<<<<<<< HEAD
        case imsak = "Imsak"
=======
>>>>>>> origin/claude/adoring-banach
        case fajr = "Fajr"
        case sunrise = "Sunrise"
        case dhuhr = "Dhuhr"
        case asr = "Asr"
        case maghrib = "Maghrib"
        case isha = "Isha"
    }
}

struct AladhanDate: Decodable {
    let readable: String?
    let gregorian: AladhanGregorian?
}

struct AladhanGregorian: Decodable {
    let date: String?
}

struct AladhanMeta: Decodable {
    let timezone: String?
    let latitude: Double?
    let longitude: Double?
}
