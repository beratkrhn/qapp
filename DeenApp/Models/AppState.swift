//
//  AppState.swift
//  DeenApp
//
//  Globaler App-Zustand (z. B. ausgewählter Tab, Nutzername, Sprache, Standort, Onboarding).
//

import SwiftUI
import Combine

private enum UserDefaultsKeys {
    static let onboardingCompleted = "dailydee.onboardingCompleted"
    static let userName = "dailydee.userName"
    static let appLanguage = "dailydee.appLanguage"
    static let selectedCity = "dailydee.selectedCity"
    static let calculationMethodLegacy = "dailydee.calculationMethod"
    static let prayerCalculation = "dailydee.prayerCalculation_v1"
    static let prayerTimeProvider = "dailydee.prayerTimeProvider"
    static let appearanceMode = "dailydee.appearanceMode"
    static let dailyReadPages = "dailydee.dailyReadPages"
    static let dailyGoalPages = "dailydee.dailyGoalPages"
    static let lastReadDate = "dailydee.lastReadDate"
    static let isTajweedEnabled = "dailydee.isTajweedEnabled"
    static let isReadingModeEnabled = "dailydee.isReadingModeEnabled"
    static let accentTheme = "dailydee.accentTheme"
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

    // MARK: - Accent Theme
    /// Writing this triggers a view rebuild in any observer, at which point
    /// `Theme.accent` (a computed var reading UserDefaults) returns the new color.
    @Published var accentTheme: ThemeColor {
        didSet { UserDefaults.standard.set(accentTheme.rawValue, forKey: UserDefaultsKeys.accentTheme) }
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

        // Accent theme: defaults to Emerald Green (entferntes slate_blue → Smaragd + Persistenz bereinigen)
        let rawTheme = UserDefaults.standard.string(forKey: UserDefaultsKeys.accentTheme)
        if rawTheme == "slate_blue" {
            UserDefaults.standard.set(ThemeColor.emeraldGreen.rawValue, forKey: UserDefaultsKeys.accentTheme)
        }
        let resolvedTheme = UserDefaults.standard.string(forKey: UserDefaultsKeys.accentTheme).flatMap(ThemeColor.init(rawValue:)) ?? .emeraldGreen
        self.accentTheme = resolvedTheme

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
    }

    // MARK: - Daily Reading Actions

    /// Inkrementiert den Tageszähler um 1 und setzt ihn bei Tageswechsel zurück.
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
    }

    func updateCity(_ city: AppCity) {
        selectedCity = city
        UserDefaults.standard.set(city.rawValue, forKey: UserDefaultsKeys.selectedCity)
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
            case 13: preset = .ditib
            case 3: preset = .mwl
            case 2: preset = .isna
            case 5: preset = .egypt
            case 1: preset = .karachi
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
        case .start: return "house.fill"
        case .quran: return "book.fill"
        case .lernen: return "graduationcap.fill"
        case .gebet: return "heart.fill"
        }
    }
}
