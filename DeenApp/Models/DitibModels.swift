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

// MARK: - Hardcoded City Entry

/// A city in the hardcoded DITIB catalogue. `districtId` is baked in where known;
/// when nil the ViewModel resolves it once via the Diyanet search endpoint on selection.
struct DitibHardcodedCity: Identifiable, Hashable {
    let name: String
    let stateId: String
    /// Diyanet district ID if known; `nil` → VM resolves via API search on first selection.
    let districtId: String?

    var id: String { districtId ?? "\(stateId)-\(name)" }
}

extension DitibFederalState {

    // MARK: - City catalogue per Bundesland

    var hardcodedCities: [DitibHardcodedCity] {
        DitibFederalState.cityCatalogue[diyanetStateId] ?? []
    }

    /// Comprehensive, hardcoded mapping of every German federal state (by Diyanet state_id)
    /// to the DITIB-supported cities within it.  District IDs are baked in where confirmed;
    /// all others are resolved via the Diyanet search endpoint the first time a user selects them.
    static let cityCatalogue: [String: [DitibHardcodedCity]] = {
        func list(_ sid: String, _ entries: [(String, String?)]) -> [DitibHardcodedCity] {
            entries
                .map { DitibHardcodedCity(name: $0.0, stateId: sid, districtId: $0.1) }
                .sorted { $0.name < $1.name }
        }
        return [
            // Baden-Württemberg
            "850": list("850", [
                ("Aalen", nil), ("Baden-Baden", nil), ("Böblingen", nil),
                ("Bruchsal", nil), ("Esslingen am Neckar", nil), ("Ettlingen", nil),
                ("Freiburg im Breisgau", nil), ("Göppingen", nil), ("Heidelberg", nil),
                ("Heilbronn", nil), ("Karlsruhe", nil), ("Konstanz", nil),
                ("Lahr", nil), ("Lörrach", nil), ("Ludwigsburg", nil),
                ("Mannheim", nil), ("Offenburg", nil), ("Pforzheim", nil),
                ("Ravensburg", nil), ("Reutlingen", nil), ("Sindelfingen", nil),
                ("Stuttgart", "11027"), ("Tübingen", nil), ("Ulm", nil),
                ("Villingen-Schwenningen", nil), ("Waiblingen", nil)
            ]),
            // Bayern
            "851": list("851", [
                ("Ansbach", nil), ("Aschaffenburg", nil), ("Augsburg", "11036"),
                ("Bamberg", nil), ("Bayreuth", nil), ("Coburg", nil),
                ("Dachau", nil), ("Erlangen", nil), ("Freising", nil),
                ("Fürth", nil), ("Gersthofen", nil), ("Günzburg", "10112"), ("Ingolstadt", nil),
                ("Kaufbeuren", nil), ("Kempten (Allgäu)", nil), ("Landsberg am Lech", nil),
                ("Landshut", nil), ("Memmingen", nil), ("München", nil),
                ("Neu-Ulm", nil), ("Nürnberg", nil), ("Passau", nil),
                ("Regensburg", nil), ("Rosenheim", nil), ("Schweinfurt", nil),
                ("Straubing", nil), ("Weiden in der Oberpfalz", nil), ("Würzburg", nil)
            ]),
            // Berlin
            "852": list("852", [
                ("Berlin", "11002")
            ]),
            // Brandenburg
            "853": list("853", [
                ("Brandenburg an der Havel", nil), ("Cottbus", nil),
                ("Frankfurt (Oder)", nil), ("Potsdam", nil)
            ]),
            // Bremen
            "854": list("854", [
                ("Bremen", nil), ("Bremerhaven", nil)
            ]),
            // Hamburg
            "855": list("855", [
                ("Hamburg", nil)
            ]),
            // Hessen
            "856": list("856", [
                ("Bad Homburg vor der Höhe", nil), ("Darmstadt", nil),
                ("Frankfurt am Main", nil), ("Fulda", nil), ("Gießen", nil),
                ("Hanau", nil), ("Kassel", nil), ("Maintal", nil),
                ("Marburg", nil), ("Offenbach am Main", nil),
                ("Rüsselsheim am Main", nil), ("Wiesbaden", nil)
            ]),
            // Niedersachsen
            "857": list("857", [
                ("Braunschweig", nil), ("Celle", nil), ("Delmenhorst", nil),
                ("Göttingen", nil), ("Hannover", nil), ("Hildesheim", nil),
                ("Lüneburg", nil), ("Oldenburg (Oldenburg)", nil),
                ("Osnabrück", nil), ("Salzgitter", nil), ("Wolfsburg", nil)
            ]),
            // Mecklenburg-Vorpommern
            "858": list("858", [
                ("Greifswald", nil), ("Neubrandenburg", nil),
                ("Rostock", nil), ("Schwerin", nil), ("Stralsund", nil)
            ]),
            // Nordrhein-Westfalen
            "859": list("859", [
                ("Aachen", nil), ("Bergheim", nil), ("Bielefeld", nil),
                ("Bochum", nil), ("Bonn", nil), ("Bottrop", nil),
                ("Dortmund", nil), ("Duisburg", nil), ("Düsseldorf", nil),
                ("Düren", nil), ("Essen", nil), ("Gelsenkirchen", nil),
                ("Gütersloh", nil), ("Hagen", nil), ("Hamm", nil),
                ("Herne", nil), ("Iserlohn", nil), ("Köln", nil),
                ("Krefeld", nil), ("Leverkusen", nil), ("Mönchengladbach", nil),
                ("Mülheim an der Ruhr", nil), ("Münster", nil),
                ("Neuss", nil), ("Oberhausen", nil), ("Paderborn", nil),
                ("Recklinghausen", nil), ("Remscheid", nil), ("Siegen", nil),
                ("Solingen", nil), ("Velbert", nil), ("Viersen", nil),
                ("Wuppertal", nil)
            ]),
            // Rheinland-Pfalz
            "860": list("860", [
                ("Bad Kreuznach", nil), ("Kaiserslautern", nil),
                ("Koblenz", nil), ("Landau in der Pfalz", nil),
                ("Ludwigshafen am Rhein", nil), ("Mainz", nil),
                ("Neustadt an der Weinstraße", nil), ("Pirmasens", nil),
                ("Trier", nil), ("Worms", nil), ("Zweibrücken", nil)
            ]),
            // Saarland
            "861": list("861", [
                ("Homburg", nil), ("Merzig", nil), ("Neunkirchen", nil),
                ("Saarbrücken", nil), ("Saarlouis", nil), ("St. Ingbert", nil)
            ]),
            // Thüringen
            "862": list("862", [
                ("Erfurt", nil), ("Gera", nil), ("Jena", nil), ("Weimar", nil)
            ]),
            // Sachsen
            "863": list("863", [
                ("Chemnitz", nil), ("Dresden", nil), ("Leipzig", nil), ("Zwickau", nil)
            ]),
            // Sachsen-Anhalt
            "864": list("864", [
                ("Dessau-Roßlau", nil), ("Halle (Saale)", nil), ("Magdeburg", nil)
            ]),
            // Schleswig-Holstein
            "865": list("865", [
                ("Flensburg", nil), ("Kiel", nil), ("Lübeck", nil), ("Neumünster", nil)
            ]),
        ]
    }()
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
