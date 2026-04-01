//
//  DitibAPIService.swift
//  DeenApp
//
//  Async network service for the Diyanet/DITIB prayer-times API.
//  Base URL: https://ezanvakti.imsakiyem.com
//
//  Workflow:
//    1. Resolve a city name → DITIB district ID  (hardcoded map or live search)
//    2. Fetch daily prayer times for that district ID
//

import Foundation

actor DitibAPIService {

    static let shared = DitibAPIService()

    private let baseURL = "https://ezanvakti.imsakiyem.com/api"
    private let session: URLSession

    /// Germany's country ID on the Diyanet platform.
    private let germanyCountryId = "13"

    /// Hardcoded fallback mapping: AppCity rawValue → Diyanet district ID.
    /// Keeps the app functional even when the search endpoint is unreachable.
    private let knownDistrictIds: [String: String] = [
        "berlin":    "11002",
        "augsburg":  "11036",
        "stuttgart":  "11027",
        "guenzburg":  "10112"
    ]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Full Germany City List

    /// Attempts to load every DITIB district in Germany in one call.
    /// Endpoint: GET /api/locations/districts?country_id=13
    /// Throws `DitibError.httpError` if the endpoint doesn't exist (404),
    /// letting the caller fall back to search-as-you-type mode.
    func tryLoadAllGermanCities() async throws -> [DitibCity] {
        guard let url = URL(string: "\(baseURL)/locations/districts?country_id=\(germanyCountryId)") else {
            throw DitibError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw DitibError.httpError(statusCode: http.statusCode)
        }
        let decoded = try JSONDecoder().decode(DitibAPIResponse<DitibDistrict>.self, from: data)
        return decoded.data
            .filter { $0.countryId == germanyCountryId }
            .map { DitibCity(id: $0.id, name: $0.name, stateId: $0.stateId ?? "") }
            .sorted { $0.name < $1.name }
    }

    // MARK: - Cities for a Specific Diyanet State

    /// Loads all districts for a single Diyanet state ID.
    /// Endpoint: GET /api/locations/districts?state_id=<id>
    func loadCitiesForDiyanetState(stateId: String) async throws -> [DitibCity] {
        guard let url = URL(string: "\(baseURL)/locations/districts?state_id=\(stateId)") else {
            throw DitibError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw DitibError.httpError(statusCode: http.statusCode)
        }
        let decoded = try JSONDecoder().decode(DitibAPIResponse<DitibDistrict>.self, from: data)
        return decoded.data
            .map { DitibCity(id: $0.id, name: $0.name, stateId: $0.stateId ?? "") }
            .sorted { $0.name < $1.name }
    }

    // MARK: - City Search (Germany)

    /// Searches DITIB districts by name, filtered to Germany (country_id = 13).
    /// Uses the confirmed-working search endpoint. Minimum 2-character query.
    func searchCitiesInGermany(query: String) async throws -> [DitibCity] {
        guard query.count >= 2,
              let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/locations/search/districts?q=\(encoded)")
        else { throw DitibError.invalidURL }

        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw DitibError.httpError(statusCode: http.statusCode)
        }
        let decoded = try JSONDecoder().decode(DitibAPIResponse<DitibDistrict>.self, from: data)
        return decoded.data
            .filter { $0.countryId == germanyCountryId }
            .map { DitibCity(id: $0.id, name: $0.name, stateId: $0.stateId ?? "") }
    }

    // MARK: - Public API (legacy)

    /// Returns the Diyanet district ID for the given city key.
    /// Tries the hardcoded map first, then falls back to a live search.
    /// Returns the Berlin district ID as ultimate fallback.
    func resolveDistrictId(for cityKey: String) async -> String {
        if let known = knownDistrictIds[cityKey.lowercased()] {
            return known
        }
        if let searched = try? await searchDistrict(name: cityKey) {
            return searched
        }
        return knownDistrictIds["berlin"]!
    }

    /// Searches the Diyanet API for a district matching `name`.
    /// Returns the best-matching district ID, or `nil`.
    func searchDistrict(name: String) async throws -> String? {
        guard let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/locations/search/districts?q=\(encoded)")
        else { return nil }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(DitibAPIResponse<DitibDistrict>.self, from: data)

        // Prefer an exact (case-insensitive) match inside Germany; otherwise take the top result.
        let upperName = name.uppercased()
        let germanyMatches = response.data.filter { $0.countryId == germanyCountryId }
        if let exact = germanyMatches.first(where: { $0.name.uppercased() == upperName }) {
            return exact.id
        }
        return germanyMatches.first?.id ?? response.data.first?.id
    }

    /// Fetches today's prayer times for the given district ID.
    func fetchDailyPrayerTimes(districtId: String) async throws -> DitibTimes {
        guard let url = URL(string: "\(baseURL)/prayer-times/\(districtId)/daily") else {
            throw DitibError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw DitibError.httpError(statusCode: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(DitibAPIResponse<DitibDailyData>.self, from: data)
        guard let today = decoded.data.first else {
            throw DitibError.noDataForToday
        }
        return today.times
    }

    // MARK: - Error

    enum DitibError: LocalizedError {
        case invalidURL
        case httpError(statusCode: Int)
        case noDataForToday

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "DITIB: Ungültige URL"
            case .httpError(let code):
                return "DITIB: HTTP-Fehler \(code)"
            case .noDataForToday:
                return "DITIB: Keine Gebetszeiten für heute verfügbar"
            }
        }
    }
}
