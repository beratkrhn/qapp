//
//  AppState.swift
//  DeenApp
//
//  Globaler App-Zustand (z. B. ausgewählter Tab, Nutzername, Sprache, Standort, Onboarding).
//

import SwiftUI
import Combine
import WidgetKit

// MARK: - Quran PDF Source

enum QuranPDFSource: String, CaseIterable {
    case diyanet       = "diyanet"
    case kuranschrift2 = "kuranschrift2"
    case pc2web        = "pc2web"

    var displayName: String {
        switch self {
        case .diyanet:       return "Diyanet PDF"
        case .kuranschrift2: return "Quran-Schrift 2"
        case .pc2web:        return "Mushaf-Bilder"
        }
    }

    /// Bundle resource name of the underlying PDF file (without extension).
    /// Image-based sources have no PDF and return `nil`.
    var pdfResourceName: String? {
        switch self {
        case .diyanet:       return "kuranpdfdiyanet"
        case .kuranschrift2: return "kuranschrift2"
        case .pc2web:        return nil
        }
    }

    /// Short subtitle shown in the viewer's bottom bar.
    var bottomBarLabel: String {
        switch self {
        case .diyanet:       return "Diyanet Mushaf · PDF"
        case .kuranschrift2: return "Quran-Schrift 2 · PDF"
        case .pc2web:        return "Mushaf-Bilder · PC2"
        }
    }
}

private enum UserDefaultsKeys {
    static let onboardingCompleted = "dailydee.onboardingCompleted"
    static let userName = "dailydee.userName"
    static let appLanguage = "dailydee.appLanguage"
    static let selectedCity = "dailydee.selectedCity"
    static let calculationMethodLegacy = "dailydee.calculationMethod"
    static let prayerCalculation = "dailydee.prayerCalculation_v1"
    static let prayerTimeProvider = "dailydee.prayerTimeProvider"
    static let selectedDitibCity = "dailydee.selectedDitibCity"
    static let appearanceMode = "dailydee.appearanceMode"
    static let dailyReadPages = "dailydee.dailyReadPages"
    static let dailyGoalPages = "dailydee.dailyGoalPages"
    static let lastReadDate = "dailydee.lastReadDate"
    static let isTajweedEnabled = "dailydee.isTajweedEnabled"
    static let isReadingModeEnabled = "dailydee.isReadingModeEnabled"
    static let accentTheme = "dailydee.accentTheme"
    static let quranPDFSource = "dailydee.quranPDFSource"
    static let autoLocationEnabled = "dailydee.autoLocationEnabled"
    static let homeCity = "dailydee.homeCity_v1"
}

final class AppState: ObservableObject {
    @Published var selectedTab: MainTab = .start
    @Published var userName: String
    @Published var appLanguage: AppLanguage
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedCity: AppCity
    @Published var prayerCalculation: PrayerCalculationSettings {
        didSet { Self.persistPrayerCalculation(prayerCalculation) }
    }
    @Published var prayerTimeProvider: PrayerTimeProvider

    /// The dynamically selected DITIB city (replaces the static `AppCity` enum for location).
    /// Persisted as JSON. `nil` means no city has been manually picked yet.
    @Published var selectedDitibCity: DitibCity? {
        didSet {
            guard let city = selectedDitibCity,
                  let data = try? JSONEncoder().encode(city) else { return }
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.selectedDitibCity)
            SharedPrayerData.saveCity(city.name)
        }
    }

    /// Light / Dark / System — steuert `preferredColorScheme` in der App.
    @Published var appearanceMode: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: UserDefaultsKeys.appearanceMode) }
    }

    // MARK: - Tajweed
    @Published var isTajweedEnabled: Bool {
        didSet { UserDefaults.standard.set(isTajweedEnabled, forKey: UserDefaultsKeys.isTajweedEnabled) }
    }

    // MARK: - Reading Mode (white background, black text)
    @Published var isReadingModeEnabled: Bool {
        didSet { UserDefaults.standard.set(isReadingModeEnabled, forKey: UserDefaultsKeys.isReadingModeEnabled) }
    }

    // MARK: - Quran PDF Source (Diyanet PDF vs. pc2-web page images)
    @Published var quranPDFSource: QuranPDFSource {
        didSet { UserDefaults.standard.set(quranPDFSource.rawValue, forKey: UserDefaultsKeys.quranPDFSource) }
    }

    // MARK: - Accent Theme
    @Published var accentTheme: ThemeColor {
        didSet {
            UserDefaults.standard.set(accentTheme.rawValue, forKey: UserDefaultsKeys.accentTheme)
            // Sync to App Group so the widget extension can read the current theme
            UserDefaults(suiteName: "group.d.DailyDee")?.set(accentTheme.rawValue, forKey: UserDefaultsKeys.accentTheme)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Auto-Location (GPS-based city follow)
    @Published var autoLocationEnabled: Bool {
        didSet { UserDefaults.standard.set(autoLocationEnabled, forKey: UserDefaultsKeys.autoLocationEnabled) }
    }

    // MARK: - Heimatstadt (used by the Seferi-distance calculation)
    @Published var homeCity: HomeCity? {
        didSet {
            if let city = homeCity, let data = try? JSONEncoder().encode(city) {
                UserDefaults.standard.set(data, forKey: UserDefaultsKeys.homeCity)
            } else if homeCity == nil {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.homeCity)
            }
        }
    }

    // MARK: - Daily Reading Tracker
    @Published var dailyReadPages: Int {
        didSet { UserDefaults.standard.set(dailyReadPages, forKey: UserDefaultsKeys.dailyReadPages) }
    }
    @Published var dailyGoalPages: Int {
        didSet { UserDefaults.standard.set(dailyGoalPages, forKey: UserDefaultsKeys.dailyGoalPages) }
    }

    init(
        userName: String = "Berat",
        appLanguage: AppLanguage = .german,
        hasCompletedOnboarding: Bool = false,
        selectedCity: AppCity = .berlin,
        prayerCalculation: PrayerCalculationSettings = .preset(.ditib),
        prayerTimeProvider: PrayerTimeProvider = .ditib
    ) {
        self.userName = UserDefaults.standard.string(forKey: UserDefaultsKeys.userName) ?? userName
        let rawLang = UserDefaults.standard.string(forKey: UserDefaultsKeys.appLanguage)
        self.appLanguage = rawLang.flatMap(AppLanguage.init(rawValue:)) ?? appLanguage
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingCompleted)
        let rawCity = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedCity)
        self.selectedCity = rawCity.flatMap(AppCity.init(rawValue:)) ?? selectedCity
        self.prayerCalculation = Self.loadPrayerCalculation(default: prayerCalculation)
        let rawProvider = UserDefaults.standard.string(forKey: UserDefaultsKeys.prayerTimeProvider)
        self.prayerTimeProvider = rawProvider.flatMap(PrayerTimeProvider.init(rawValue:)) ?? prayerTimeProvider

        // Tajweed: defaults to true
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.isTajweedEnabled) != nil {
            self.isTajweedEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isTajweedEnabled)
        } else {
            self.isTajweedEnabled = true
        }

        // Reading mode: defaults to false (dark theme)
        self.isReadingModeEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isReadingModeEnabled)

        // Auto-location: defaults to false; user opts in from Settings.
        self.autoLocationEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.autoLocationEnabled)

        // Heimatstadt: optional, only set once the user picks one.
        if let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.homeCity),
           let decoded = try? JSONDecoder().decode(HomeCity.self, from: data) {
            self.homeCity = decoded
        } else {
            self.homeCity = nil
        }

        // Quran PDF source: defaults to Diyanet PDF
        let rawPDFSource = UserDefaults.standard.string(forKey: UserDefaultsKeys.quranPDFSource)
        self.quranPDFSource = rawPDFSource.flatMap(QuranPDFSource.init(rawValue:)) ?? .diyanet

        // Accent theme: defaults to Emerald Green. Legacy / removed values
        // (slate_blue, dark_gray, etc.) get migrated to the default so the
        // didSet writes the new raw value back to UserDefaults.
        let rawTheme = UserDefaults.standard.string(forKey: UserDefaultsKeys.accentTheme)
        let migratedRaw: String?
        switch rawTheme {
        case "slate_blue", "soft_gray", "white", "dark_gray":
            migratedRaw = ThemeColor.emeraldGreen.rawValue
            UserDefaults.standard.set(migratedRaw, forKey: UserDefaultsKeys.accentTheme)
        default:
            migratedRaw = rawTheme
        }
        let resolvedTheme = migratedRaw.flatMap(ThemeColor.init(rawValue:)) ?? .emeraldGreen
        self.accentTheme = resolvedTheme
        // Sync initial theme to App Group for widget
        UserDefaults(suiteName: "group.d.DailyDee")?.set(resolvedTheme.rawValue, forKey: UserDefaultsKeys.accentTheme)

        let rawAppearance = UserDefaults.standard.string(forKey: UserDefaultsKeys.appearanceMode)
        self.appearanceMode = rawAppearance.flatMap(AppearanceMode.init(rawValue:)) ?? .system

        // Daily reading: reset if last read was not today
        let savedGoal = UserDefaults.standard.integer(forKey: UserDefaultsKeys.dailyGoalPages)
        self.dailyGoalPages = savedGoal > 0 ? savedGoal : 5

        let savedPages = UserDefaults.standard.integer(forKey: UserDefaultsKeys.dailyReadPages)
        let savedDateTS = UserDefaults.standard.double(forKey: UserDefaultsKeys.lastReadDate)
        let savedDate = savedDateTS > 0 ? Date(timeIntervalSince1970: savedDateTS) : nil
        if let date = savedDate, Calendar.current.isDateInToday(date) {
            self.dailyReadPages = savedPages
        } else {
            self.dailyReadPages = 0
            UserDefaults.standard.set(0, forKey: UserDefaultsKeys.dailyReadPages)
        }

        // Load dynamically persisted DITIB city
        if let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.selectedDitibCity),
           let ditibCity = try? JSONDecoder().decode(DitibCity.self, from: data) {
            self.selectedDitibCity = ditibCity
        } else {
            self.selectedDitibCity = nil
        }

        // Sync city to App Group so widgets always know the current city
        let cityName = self.selectedDitibCity?.name ?? self.selectedCity.displayName
        SharedPrayerData.saveCity(cityName)
    }

    // MARK: - Daily Reading Actions

    func incrementDailyPages() {
        let savedDateTS = UserDefaults.standard.double(forKey: UserDefaultsKeys.lastReadDate)
        let savedDate = savedDateTS > 0 ? Date(timeIntervalSince1970: savedDateTS) : nil
        if let date = savedDate, !Calendar.current.isDateInToday(date) {
            dailyReadPages = 0
        }
        dailyReadPages += 1
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: UserDefaultsKeys.lastReadDate)
    }

    func completeOnboarding(name: String, language: AppLanguage) {
        userName = name.isEmpty ? "Berat" : name
        appLanguage = language
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingCompleted)
        UserDefaults.standard.set(self.userName, forKey: UserDefaultsKeys.userName)
        UserDefaults.standard.set(appLanguage.rawValue, forKey: UserDefaultsKeys.appLanguage)
    }

    func updateName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        userName = trimmed
        UserDefaults.standard.set(trimmed, forKey: UserDefaultsKeys.userName)
    }

    func updateLanguage(_ language: AppLanguage) {
        appLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: UserDefaultsKeys.appLanguage)
        // Notify PrayerTimeManager so it can re-sync widget prayer names.
        NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
    }

    func updateCity(_ city: AppCity) {
        selectedCity = city
        UserDefaults.standard.set(city.rawValue, forKey: UserDefaultsKeys.selectedCity)
        SharedPrayerData.saveCity(city.displayName)
    }

    /// Persists a dynamically selected DITIB city and syncs the display name.
    func updateDitibCity(_ city: DitibCity) {
        selectedDitibCity = city
    }

    /// Persists the user's home city used by the Seferi-distance calculation.
    func updateHomeCity(_ city: HomeCity?) {
        homeCity = city
    }

    /// Reactive display name: DITIB city if set, otherwise the legacy static city.
    var currentCityName: String {
        selectedDitibCity?.name ?? selectedCity.displayName
    }

    func updatePrayerCalculation(_ settings: PrayerCalculationSettings) {
        prayerCalculation = settings
    }

    func updateAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
    }

    var preferredSwiftUIColorScheme: ColorScheme? {
        appearanceMode.preferredColorScheme
    }

    private static func persistPrayerCalculation(_ settings: PrayerCalculationSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: UserDefaultsKeys.prayerCalculation)
    }

    private static func loadPrayerCalculation(default: PrayerCalculationSettings) -> PrayerCalculationSettings {
        if let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.prayerCalculation),
           let decoded = try? JSONDecoder().decode(PrayerCalculationSettings.self, from: data) {
            return decoded
        }
        if let legacy = UserDefaults.standard.object(forKey: UserDefaultsKeys.calculationMethodLegacy) as? Int {
            let preset: AladhanPresetCalculation
            switch legacy {
            case 99: preset = .fazilet
            default: preset = .ditib
            }
            let migrated: PrayerCalculationSettings = .preset(preset)
            persistPrayerCalculation(migrated)
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.calculationMethodLegacy)
            return migrated
        }
        return `default`
    }

    func updatePrayerTimeProvider(_ provider: PrayerTimeProvider) {
        prayerTimeProvider = provider
        UserDefaults.standard.set(provider.rawValue, forKey: UserDefaultsKeys.prayerTimeProvider)
    }

    func updateAccentTheme(_ theme: ThemeColor) {
        accentTheme = theme
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Hell"
        case .dark: return "Dunkel"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("dailydee.appLanguageDidChange")
}

enum MainTab: Int, CaseIterable {
    case start = 0
    case quran
    case lernen
    case gebet

    func title(lang: AppLanguage) -> String {
        switch self {
        case .start: return L10n.tabStart(lang)
        case .quran: return L10n.tabQuran(lang)
        case .lernen: return L10n.tabLernen(lang)
        case .gebet: return L10n.tabGebet(lang)
        }
    }

    var iconName: String {
        switch self {
        case .start:  return "house.fill"
        case .quran:  return "book.fill"
        case .lernen: return "graduationcap.fill"
        case .gebet:  return "heart.fill"
        }
    }
}
