//
//  AppCity.swift
//  DeenApp
//
//  Auswählbare Städte und Berechnungsmethoden für Gebetszeiten.
//

import Foundation

// MARK: - Berechnungsmethoden (Aladhan API &method=)

enum CalculationMethod: Int, CaseIterable, Identifiable {
    case ditib   = 13   // Diyanet İşleri Başkanlığı (DITIB) – Standard DE
    case mwl     = 3    // Muslim World League
    case isna    = 2    // Islamic Society of North America
    case egypt   = 5    // Egyptian General Authority of Survey
    case karachi = 1    // University of Islamic Sciences, Karachi

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .ditib:    return "DITIB (Diyanet)"
        case .mwl:      return "Muslim World League"
        case .isna:     return "ISNA"
        case .egypt:    return "Ägyptische Behörde"
        case .karachi:  return "Karachi"
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
}
