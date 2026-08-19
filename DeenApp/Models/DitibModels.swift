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
        // Tuple form: (name, optional Diyanet district id).
        // If the id is nil, the VM resolves it via the DITIB search endpoint on first
        // selection — keeps the catalogue browsable for cities whose IDs we haven't
        // baked in yet.
        func list(_ sid: String, _ entries: [(String, String?)]) -> [DitibHardcodedCity] {
            entries
                .map { DitibHardcodedCity(name: $0.0, stateId: sid, districtId: $0.1) }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        /// Overload for lists where every district id is known — saves callers
        /// from wrapping every literal in `Optional<String>`.
        func list(_ sid: String, _ entries: [(String, String)]) -> [DitibHardcodedCity] {
            list(sid, entries.map { ($0.0, Optional.some($0.1)) })
        }
        return [
            // Baden-Württemberg
            "850": list("850", [
                ("Aalen", "21169"), ("Achern", "10870"), ("Albstadt", "11086"),
                ("Backnang", "10050"), ("Baden-Baden", "10913"), ("Bietigheim-Bissingen", "10852"),
                ("Böblingen", "10572"), ("Bruchsal", "10953"), ("Buchen (Odenwald)", "10066"),
                ("Bühl", "18961"), ("Calw", "11111"), ("Crailsheim", "10076"),
                ("Donaueschingen", "10792"), ("Ehingen (Donau)", "10085"),
                ("Emmendingen", "10993"), ("Eppingen", "10088"), ("Esslingen am Neckar", "11121"),
                ("Ettlingen", "9980"), ("Filderstadt", "10093"), ("Freiburg im Breisgau", "11011"),
                ("Friedrichshafen", "11046"), ("Gaggenau", "9994"),
                ("Geislingen an der Steige", "10103"), ("Göppingen", "11044"),
                ("Heidelberg", "11033"), ("Heidenheim an der Brenz", "18951"),
                ("Heilbronn", "11051"), ("Herrenberg", "11080"), ("Karlsruhe", "11014"),
                ("Kehl", "11123"), ("Kirchheim unter Teck", "10395"), ("Konstanz", "11018"),
                ("Kornwestheim", "10402"), ("Lahr", "10173"), ("Leinfelden-Echterdingen", "10848"),
                ("Leonberg", "10422"), ("Lörrach", "10191"), ("Ludwigsburg", "11048"),
                ("Mannheim", "11021"), ("Mosbach", "10452"), ("Murrhardt", "10457"),
                ("Nagold", "10458"), ("Nürtingen", "10550"), ("Offenburg", "10557"),
                ("Öhringen", "10472"), ("Ostfildern", "10856"), ("Pforzheim", "11119"),
                ("Rastatt", "10255"), ("Ravensburg", "11045"), ("Reutlingen", "11042"),
                ("Rottenburg am Neckar", "11072"), ("Rottweil", "11053"),
                ("Schorndorf", "10495"), ("Schwäbisch Gmünd", "11049"),
                ("Schwäbisch Hall", "11050"), ("Schwetzingen", "10283"),
                ("Sigmaringen", "11047"), ("Sindelfingen", "10558"),
                ("Singen (Hohentwiel)", "10868"), ("Stuttgart", "11027"),
                ("Tauberbischofsheim", "10864"), ("Tettnang", "10812"), ("Tübingen", "11043"),
                ("Tuttlingen", "11083"), ("Überlingen", "10563"), ("Ulm", "11028"),
                ("Vaihingen an der Enz", "10517"),
                ("Villingen-Schwenningen", "10327"), ("Waiblingen", "11041"),
                ("Waldshut-Tiengen", "11082"), ("Wangen im Allgäu", "10580"),
                ("Weil am Rhein", "10341"), ("Weinheim", "10532"), ("Wertheim", "10536")
            ]),
            // Bayern
            "851": list("851", [
                ("Aichach", "21174"), ("Amberg", "10890"), ("Ansbach", "11106"),
                ("Aschaffenburg", "10894"), ("Augsburg", "11036"), ("Bamberg", "11067"),
                ("Bayreuth", "10584"), ("Burghausen", "10070"), ("Coburg", "10075"),
                ("Dachau", "10967"), ("Deggendorf", "10077"),
                ("Dillingen an der Donau", "10859"), ("Dingolfing", "10080"),
                ("Donauwörth", "11115"), ("Erding", "10818"), ("Erlangen", "10561"),
                ("Freising", "10096"), ("Fürstenfeldbruck", "10819"), ("Fürth", "11081"),
                ("Garmisch-Partenkirchen", "9997"), ("Geretsried", "21161"),
                ("Germering", "10009"), ("Gersthofen", "10105"), ("Günzburg", "10112"),
                ("Hof", "11085"), ("Ingolstadt", "11108"), ("Kaufbeuren", "10392"),
                ("Kempten (Allgäu)", "11104"), ("Kulmbach", "10404"),
                ("Landsberg am Lech", "10406"), ("Landshut", "10407"), ("Lichtenfels", "10424"),
                ("Lindau (Bodensee)", "10582"), ("Marktredwitz", "10439"),
                ("Memmingen", "10442"), ("Mindelheim", "10449"), ("Mühldorf am Inn", "21163"),
                ("München", "11022"), ("Neu-Ulm", "10559"), ("Neuburg an der Donau", "10562"),
                ("Neumarkt in der Oberpfalz", "10222"), ("Nürnberg", "11024"),
                ("Passau", "11034"), ("Regensburg", "11025"), ("Rosenheim", "10486"),
                ("Roth", "10270"), ("Schongau", "10494"), ("Schwabach", "10496"),
                ("Schweinfurt", "11107"), ("Selb", "10501"), ("Starnberg", "10824"),
                ("Straubing", "10508"), ("Sulzbach-Rosenberg", "10827"),
                ("Traunstein", "33284"), ("Vilsbiburg", "10518"),
                ("Waldkraiburg", "10523"), ("Wasserburg am Inn", "10527"),
                ("Weiden in der Oberpfalz", "10529"), ("Weilheim in Oberbayern", "10530"),
                ("Würzburg", "11029")
            ]),
            // Berlin
            "852": list("852", [
                ("Berlin", "11002")
            ]),
            // Brandenburg
            "853": list("853", [
                ("Bernau bei Berlin", nil), ("Brandenburg an der Havel", "10064"),
                ("Cottbus", "10605"), ("Eberswalde", "10083"),
                ("Falkensee", nil), ("Forst (Lausitz)", nil),
                ("Frankfurt (Oder)", "10639"), ("Fürstenwalde/Spree", nil),
                ("Hennigsdorf", nil), ("Königs Wusterhausen", nil),
                ("Lübbenau/Spreewald", nil), ("Luckenwalde", nil),
                ("Neuruppin", nil), ("Oranienburg", nil),
                ("Potsdam", nil), ("Schwedt/Oder", nil),
                ("Senftenberg", nil), ("Spremberg", nil),
                ("Strausberg", nil), ("Werder (Havel)", nil)
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
                ("Bad Hersfeld", nil), ("Bad Homburg vor der Höhe", "10905"),
                ("Bad Nauheim", nil), ("Bad Vilbel", nil),
                ("Bensheim", nil), ("Darmstadt", "11079"),
                ("Dietzenbach", nil), ("Dreieich", nil),
                ("Eschborn", nil), ("Frankfurt am Main", "11010"),
                ("Friedberg (Hessen)", nil), ("Friedrichsdorf", nil),
                ("Fulda", "11030"), ("Gelnhausen", nil),
                ("Gießen", "11032"), ("Hanau", "10040"),
                ("Hattersheim am Main", nil), ("Heppenheim (Bergstraße)", nil),
                ("Hofheim am Taunus", nil), ("Kassel", "11015"),
                ("Langen (Hessen)", nil), ("Limburg an der Lahn", nil),
                ("Maintal", nil), ("Marburg", "10578"),
                ("Mörfelden-Walldorf", nil), ("Neu-Isenburg", nil),
                ("Oberursel (Taunus)", nil), ("Offenbach am Main", "10569"),
                ("Rodgau", nil), ("Rüsselsheim am Main", "11074"),
                ("Viernheim", nil), ("Wetzlar", nil),
                ("Wiesbaden", "11056")
            ]),
            // Niedersachsen
            "857": list("857", [
                ("Achim", nil), ("Braunschweig", "16754"),
                ("Buxtehude", nil), ("Celle", "10074"),
                ("Cloppenburg", nil), ("Cuxhaven", nil),
                ("Delmenhorst", "10970"), ("Emden", nil),
                ("Garbsen", nil), ("Gifhorn", nil),
                ("Goslar", nil), ("Göttingen", "11105"),
                ("Hameln", nil), ("Hannover", "11013"),
                ("Helmstedt", nil), ("Hildesheim", "11054"),
                ("Langenhagen", nil), ("Lehrte", nil),
                ("Lingen (Ems)", nil), ("Lüneburg", "11101"),
                ("Melle", nil), ("Nordhorn", nil),
                ("Oldenburg (Oldenburg)", "10555"), ("Osnabrück", "11055"),
                ("Papenburg", nil), ("Peine", nil),
                ("Salzgitter", "11078"), ("Stade", nil),
                ("Stuhr", nil), ("Uelzen", nil),
                ("Vechta", nil), ("Verden (Aller)", nil),
                ("Wilhelmshaven", nil), ("Wolfenbüttel", nil),
                ("Wolfsburg", "10543")
            ]),
            // Mecklenburg-Vorpommern
            "858": list("858", [
                ("Anklam", nil), ("Bergen auf Rügen", nil),
                ("Greifswald", "10564"), ("Güstrow", nil),
                ("Neubrandenburg", nil), ("Parchim", nil),
                ("Pasewalk", nil), ("Rostock", "10551"),
                ("Schwerin", "33265"), ("Stralsund", nil),
                ("Wismar", nil)
            ]),
            // Nordrhein-Westfalen
            "859": list("859", [
                ("Aachen", "33305"), ("Ahaus", nil),
                ("Ahlen", nil), ("Arnsberg", nil),
                ("Bad Salzuflen", nil), ("Bergheim", "10920"),
                ("Bergisch Gladbach", nil), ("Bielefeld", "11003"),
                ("Bocholt", nil), ("Bochum", "11126"),
                ("Bonn", "11004"), ("Borken", nil),
                ("Bornheim", nil), ("Bottrop", "10942"),
                ("Brühl", nil), ("Castrop-Rauxel", nil),
                ("Coesfeld", nil), ("Detmold", nil),
                ("Dinslaken", nil), ("Dormagen", nil),
                ("Dortmund", "11006"), ("Duisburg", "11007"),
                ("Düren", "11122"), ("Düsseldorf", "11008"),
                ("Emmerich am Rhein", nil), ("Erftstadt", nil),
                ("Erkelenz", nil), ("Erkrath", nil),
                ("Essen", "11009"), ("Euskirchen", nil),
                ("Gelsenkirchen", "11037"), ("Geldern", nil),
                ("Gevelsberg", nil), ("Gladbeck", nil),
                ("Greven", nil), ("Gummersbach", nil),
                ("Gütersloh", "10026"), ("Hagen", "11077"),
                ("Hamm", "11127"), ("Hattingen", nil),
                ("Heinsberg", nil), ("Hennef (Sieg)", nil),
                ("Herford", nil), ("Herne", "10565"),
                ("Hilden", nil), ("Hückelhoven", nil),
                ("Hürth", nil), ("Ibbenbüren", nil),
                ("Iserlohn", "10149"), ("Kaarst", nil),
                ("Kamen", nil), ("Kempen", nil),
                ("Kerpen", nil), ("Kleve", nil),
                ("Königswinter", nil), ("Köln", "11019"),
                ("Krefeld", "11066"), ("Langenfeld (Rheinland)", nil),
                ("Lemgo", nil), ("Leverkusen", "10183"),
                ("Lippstadt", nil), ("Lüdenscheid", nil),
                ("Marl", nil), ("Meerbusch", nil),
                ("Menden (Sauerland)", nil), ("Meschede", nil),
                ("Mettmann", nil), ("Minden", nil),
                ("Moers", nil), ("Mönchengladbach", "11128"),
                ("Mülheim an der Ruhr", "11062"), ("Münster", "11023"),
                ("Nettetal", nil), ("Neuss", "10575"),
                ("Oberhausen", "16705"), ("Olpe", nil),
                ("Paderborn", "11064"), ("Pulheim", nil),
                ("Ratingen", nil), ("Recklinghausen", "10583"),
                ("Remscheid", "11076"), ("Rheine", nil),
                ("Sankt Augustin", nil), ("Schwelm", nil),
                ("Schwerte", nil), ("Selm", nil),
                ("Siegen", "11102"), ("Soest", nil),
                ("Solingen", "10291"), ("Stolberg (Rheinland)", nil),
                ("Troisdorf", nil), ("Unna", nil),
                ("Velbert", "10323"), ("Viersen", "10326"),
                ("Voerde (Niederrhein)", nil), ("Werl", nil),
                ("Wermelskirchen", nil), ("Wesel", nil),
                ("Willich", nil), ("Witten", nil),
                ("Wuppertal", "11031"), ("Würselen", nil)
            ]),
            // Rheinland-Pfalz
            "860": list("860", [
                ("Andernach", nil), ("Bad Dürkheim", nil),
                ("Bad Kreuznach", "10573"), ("Bad Neuenahr-Ahrweiler", nil),
                ("Bingen am Rhein", nil), ("Bitburg", nil),
                ("Cochem", nil), ("Frankenthal (Pfalz)", nil),
                ("Germersheim", nil), ("Idar-Oberstein", nil),
                ("Ingelheim am Rhein", nil), ("Kaiserslautern", "10581"),
                ("Koblenz", "11017"), ("Lahnstein", nil),
                ("Landau in der Pfalz", "10175"), ("Ludwigshafen am Rhein", "11094"),
                ("Mainz", "11020"), ("Mayen", nil),
                ("Montabaur", nil), ("Neustadt an der Weinstraße", "10227"),
                ("Neuwied", nil), ("Pirmasens", "10251"),
                ("Speyer", nil), ("Trier", "11125"),
                ("Wittlich", nil), ("Worms", "11088"),
                ("Zweibrücken", "10369")
            ]),
            // Saarland
            "861": list("861", [
                ("Homburg", "10137"), ("Lebach", nil),
                ("Merzig", "10206"), ("Neunkirchen", "10225"),
                ("Püttlingen", nil), ("Saarbrücken", "11026"),
                ("Saarlouis", "11068"), ("St. Ingbert", "10298"),
                ("Völklingen", nil)
            ]),
            // Thüringen
            "862": list("862", [
                ("Apolda", nil), ("Arnstadt", nil),
                ("Eisenach", nil), ("Erfurt", "10874"),
                ("Gera", "10008"), ("Gotha", nil),
                ("Greiz", nil), ("Ilmenau", nil),
                ("Jena", "10627"), ("Meiningen", nil),
                ("Mühlhausen/Thüringen", nil), ("Nordhausen", nil),
                ("Saalfeld/Saale", nil), ("Sömmerda", nil),
                ("Sondershausen", nil), ("Sonneberg", nil),
                ("Suhl", nil), ("Weimar", "11097")
            ]),
            // Sachsen
            "863": list("863", [
                ("Annaberg-Buchholz", nil), ("Aue-Bad Schlema", nil),
                ("Bautzen", nil), ("Chemnitz", "11099"),
                ("Döbeln", nil), ("Dresden", "11035"),
                ("Freiberg", nil), ("Freital", nil),
                ("Glauchau", nil), ("Görlitz", nil),
                ("Grimma", nil), ("Hoyerswerda", nil),
                ("Kamenz", nil), ("Leipzig", "11100"),
                ("Markkleeberg", nil), ("Meißen", nil),
                ("Pirna", nil), ("Plauen", nil),
                ("Radebeul", nil), ("Riesa", nil),
                ("Werdau", nil), ("Zittau", nil),
                ("Zwickau", "10547")
            ]),
            // Sachsen-Anhalt
            "864": list("864", [
                ("Aschersleben", nil), ("Bernburg (Saale)", nil),
                ("Bitterfeld-Wolfen", nil), ("Burg", nil),
                ("Dessau-Roßlau", "10693"), ("Halberstadt", nil),
                ("Halle (Saale)", "11089"), ("Köthen (Anhalt)", nil),
                ("Lutherstadt Eisleben", nil), ("Lutherstadt Wittenberg", nil),
                ("Magdeburg", "10875"), ("Merseburg", nil),
                ("Naumburg (Saale)", nil), ("Quedlinburg", nil),
                ("Sangerhausen", nil), ("Schönebeck (Elbe)", nil),
                ("Stendal", nil), ("Wernigerode", nil),
                ("Zeitz", nil)
            ]),
            // Schleswig-Holstein
            "865": list("865", [
                ("Ahrensburg", nil), ("Bad Oldesloe", nil),
                ("Bad Segeberg", nil), ("Eckernförde", nil),
                ("Elmshorn", nil), ("Eutin", nil),
                ("Flensburg", "11118"), ("Geesthacht", nil),
                ("Glinde", nil), ("Heide", nil),
                ("Husum", nil), ("Itzehoe", nil),
                ("Kaltenkirchen", nil), ("Kiel", "11016"),
                ("Lübeck", "11117"), ("Mölln", nil),
                ("Neumünster", nil), ("Norderstedt", nil),
                ("Pinneberg", nil), ("Plön", nil),
                ("Quickborn", nil), ("Rendsburg", nil),
                ("Schleswig", nil), ("Stockelsdorf", nil),
                ("Wedel", nil)
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
