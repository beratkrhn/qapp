//
//  AppCity.swift
//  DeenApp
//
//  Auswählbare Städte und Berechnungsmethoden für Gebetszeiten.
//

import Foundation

// MARK: - Prayer-Time Provider

enum PrayerTimeProvider: String, CaseIterable, Identifiable {
    case ditib   = "ditib"
    case aladhan = "aladhan"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ditib:   return "DITIB (Diyanet)"
        case .aladhan: return "Aladhan API"
        }
    }
}

enum AppCity: String, CaseIterable, Identifiable {
    case berlin = "berlin"
    case augsburg = "augsburg"
    case stuttgart = "stuttgart"
    case guenzburg = "guenzburg"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .berlin: return "Berlin"
        case .augsburg: return "Augsburg"
        case .stuttgart: return "Stuttgart"
        case .guenzburg: return "Günzburg"
        }
    }

    var latitude: Double {
        switch self {
        case .berlin: return 52.5200
        case .augsburg: return 48.3705
        case .stuttgart: return 48.7758
        case .guenzburg: return 48.4525
        }
    }

    var longitude: Double {
        switch self {
        case .berlin: return 13.4050
        case .augsburg: return 10.8978
        case .stuttgart: return 9.1829
        case .guenzburg: return 10.2746
        }
    }

    /// Diyanet district ID used by the DITIB API (ezanvakti.imsakiyem.com).
    var ditibDistrictId: String {
        switch self {
        case .berlin:    return "11002"
        case .augsburg:  return "11036"
        case .stuttgart:  return "11027"
        case .guenzburg:  return "10112"
        }
    }
}
