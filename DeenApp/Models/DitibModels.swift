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
        func list(_ sid: String, _ entries: [(String, String)]) -> [DitibHardcodedCity] {
            entries
                .map { DitibHardcodedCity(name: $0.0, stateId: sid, districtId: $0.1) }
                .sorted { $0.name < $1.name }
        }
        return [
            // Baden-Württemberg
            "850": list("850", [
                ("Aalen", "21169"), ("Baden-Baden", "10913"), ("Böblingen", "10572"),
                ("Bruchsal", "10953"), ("Esslingen am Neckar", "11121"), ("Ettlingen", "9980"),
                ("Freiburg im Breisgau", "11011"), ("Göppingen", "11044"), ("Heidelberg", "11033"),
                ("Heilbronn", "11051"), ("Karlsruhe", "11014"), ("Konstanz", "11018"),
                ("Lahr", "10173"), ("Lörrach", "10191"), ("Ludwigsburg", "11048"),
                ("Mannheim", "11021"), ("Offenburg", "10557"), ("Pforzheim", "11119"),
                ("Ravensburg", "11045"), ("Reutlingen", "11042"), ("Sindelfingen", "10558"),
                ("Stuttgart", "11027"), ("Tübingen", "11043"), ("Ulm", "11028"),
                ("Villingen-Schwenningen", "10327"), ("Waiblingen", "11041")
            ]),
            // Bayern
            "851": list("851", [
                ("Ansbach", "11106"), ("Aschaffenburg", "10894"), ("Augsburg", "11036"),
                ("Bamberg", "11067"), ("Bayreuth", "10584"), ("Coburg", "10075"),
                ("Dachau", "10967"), ("Erlangen", "10561"), ("Freising", "10096"),
                ("Fürth", "11081"), ("Gersthofen", "10105"), ("Günzburg", "10112"),
                ("Ingolstadt", "11108"), ("Kaufbeuren", "10392"), ("Kempten (Allgäu)", "11104"),
                ("Landsberg am Lech", "10406"), ("Landshut", "10407"), ("Memmingen", "10442"),
                ("München", "11022"), ("Neu-Ulm", "10559"), ("Nürnberg", "11024"),
                ("Passau", "11034"), ("Regensburg", "11025"), ("Rosenheim", "10486"),
                ("Schweinfurt", "11107"), ("Straubing", "10508"),
                ("Weiden in der Oberpfalz", "10529"), ("Würzburg", "11029")
            ]),
            // Berlin
            "852": list("852", [
                ("Berlin", "11002")
            ]),
            // Brandenburg
            "853": list("853", [
                ("Brandenburg an der Havel", "10064"), ("Cottbus", "10605"),
                ("Frankfurt (Oder)", "10639")
            ]),
            // Bremen
            "854": list("854", [
                ("Bremen", "11005"), ("Bremerhaven", "11116")
            ]),
            // Hamburg
            "855": list("855", [
                ("Hamburg", "11012")
            ]),
            // Hessen
            "856": list("856", [
                ("Bad Homburg vor der Höhe", "10905"), ("Darmstadt", "11079"),
                ("Frankfurt am Main", "11010"), ("Fulda", "11030"), ("Gießen", "11032"),
                ("Hanau", "10040"), ("Kassel", "11015"), ("Marburg", "10578"),
                ("Offenbach am Main", "10569"), ("Rüsselsheim am Main", "11074"),
                ("Wiesbaden", "11056")
            ]),
            // Niedersachsen
            "857": list("857", [
                ("Braunschweig", "16754"), ("Celle", "10074"), ("Delmenhorst", "10970"),
                ("Göttingen", "11105"), ("Hannover", "11013"), ("Hildesheim", "11054"),
                ("Lüneburg", "11101"), ("Oldenburg (Oldenburg)", "10555"),
                ("Osnabrück", "11055"), ("Salzgitter", "11078"), ("Wolfsburg", "10543")
            ]),
            // Mecklenburg-Vorpommern
            "858": list("858", [
                ("Greifswald", "10564"), ("Rostock", "10551"), ("Schwerin", "33265")
            ]),
            // Nordrhein-Westfalen
            "859": list("859", [
                ("Aachen", "33305"), ("Bergheim", "10920"), ("Bielefeld", "11003"),
                ("Bochum", "11126"), ("Bonn", "11004"), ("Bottrop", "10942"),
                ("Dortmund", "11006"), ("Duisburg", "11007"), ("Düren", "11122"),
                ("Düsseldorf", "11008"), ("Essen", "11009"), ("Gelsenkirchen", "11037"),
                ("Gütersloh", "10026"), ("Hagen", "11077"), ("Hamm", "11127"),
                ("Herne", "10565"), ("Iserlohn", "10149"), ("Krefeld", "11066"),
                ("Köln", "11019"), ("Leverkusen", "10183"), ("Mönchengladbach", "11128"),
                ("Mülheim an der Ruhr", "11062"), ("Münster", "11023"),
                ("Neuss", "10575"), ("Oberhausen", "16705"), ("Paderborn", "11064"),
                ("Recklinghausen", "10583"), ("Remscheid", "11076"), ("Siegen", "11102"),
                ("Solingen", "10291"), ("Velbert", "10323"), ("Viersen", "10326"),
                ("Wuppertal", "11031")
            ]),
            // Rheinland-Pfalz
            "860": list("860", [
                ("Bad Kreuznach", "10573"), ("Kaiserslautern", "10581"),
                ("Koblenz", "11017"), ("Landau in der Pfalz", "10175"),
                ("Ludwigshafen am Rhein", "11094"), ("Mainz", "11020"),
                ("Neustadt an der Weinstraße", "10227"), ("Pirmasens", "10251"),
                ("Trier", "11125"), ("Worms", "11088"), ("Zweibrücken", "10369")
            ]),
            // Saarland
            "861": list("861", [
                ("Homburg", "10137"), ("Merzig", "10206"), ("Neunkirchen", "10225"),
                ("Saarbrücken", "11026"), ("Saarlouis", "11068"), ("St. Ingbert", "10298")
            ]),
            // Thüringen
            "862": list("862", [
                ("Erfurt", "10874"), ("Gera", "10008"), ("Jena", "10627"), ("Weimar", "11097")
            ]),
            // Sachsen
            "863": list("863", [
                ("Chemnitz", "11099"), ("Dresden", "11035"), ("Leipzig", "11100"),
                ("Zwickau", "10547")
            ]),
            // Sachsen-Anhalt
            "864": list("864", [
                ("Dessau-Roßlau", "10693"), ("Halle (Saale)", "11089"), ("Magdeburg", "10875")
            ]),
            // Schleswig-Holstein
            "865": list("865", [
                ("Flensburg", "11118"), ("Kiel", "11016"), ("Lübeck", "11117")
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
