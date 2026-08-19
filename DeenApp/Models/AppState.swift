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
    static let isTajweedEnabled = "dailydee.isTajweedEnabled"
    static let isReadingModeEnabled = "dailydee.isReadingModeEnabled"
    static let accentTheme = "dailydee.accentTheme"
    static let quranPDFSource = "dailydee.quranPDFSource"
    static let autoLocationEnabled = "dailydee.autoLocationEnabled"
    static let homeCity = "dailydee.homeCity_v1"
    static let khatmaModeEnabled = "dailydee.khatmaModeEnabled"
    static let nudgesReceiveEnabled = "dailydee.nudgesReceiveEnabled"
    static let maxNudgesPerDay = "dailydee.maxNudgesPerDay"
}

final class AppState: ObservableObject {
    private var accountSub: AnyCancellable?

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

    // MARK: - Khatma mode (focus mode in the Quran view that tracks the active
    //         khatm goal and bookmarks the last viewed page).
    @Published var khatmaModeEnabled: Bool {
        didSet { UserDefaults.standard.set(khatmaModeEnabled, forKey: UserDefaultsKeys.khatmaModeEnabled) }
    }

    // MARK: - Notification preferences (friend nudges)
    @Published var nudgesReceiveEnabled: Bool {
        didSet {
            UserDefaults.standard.set(nudgesReceiveEnabled, forKey: UserDefaultsKeys.nudgesReceiveEnabled)
            mirrorNudgePreferences()
        }
    }
    @Published var maxNudgesPerDay: Int {
        didSet {
            UserDefaults.standard.set(maxNudgesPerDay, forKey: UserDefaultsKeys.maxNudgesPerDay)
            mirrorNudgePreferences()
        }
    }

    /// Spiegelt die aktuelle Nudge-Empfangs-Einstellung nach Firestore, wenn
    /// der Nutzer eingeloggt ist (damit die Cloud Function sie auswerten kann).
    private func mirrorNudgePreferences() {
        guard let uid = AuthService.shared.currentUid else { return }
        Task { @MainActor in
            NotificationPreferencesService.shared.publish(
                receive: nudgesReceiveEnabled,
                maxPerDay: maxNudgesPerDay,
                uid: uid
            )
        }
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

        // Khatma mode: defaults to false; user opts in from QuranView toolbar.
        self.khatmaModeEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.khatmaModeEnabled)

        // Nudges: receiving defaults to on, cap defaults to 3 per day.
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.nudgesReceiveEnabled) != nil {
            self.nudgesReceiveEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.nudgesReceiveEnabled)
        } else {
            self.nudgesReceiveEnabled = true
        }
        let storedCap = UserDefaults.standard.integer(forKey: UserDefaultsKeys.maxNudgesPerDay)
        self.maxNudgesPerDay = storedCap > 0 ? storedCap : 3

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

        // Legacy "Tagesziel" keys (dailyGoalPages / dailyReadPages) have been
        // superseded by the goals system in GoalsViewModel. We drop them on
        // first launch of the new build so old values don't linger.
        UserDefaults.standard.removeObject(forKey: "dailydee.dailyGoalPages")
        UserDefaults.standard.removeObject(forKey: "dailydee.dailyReadPages")

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

        // Sync initial app language to App Group so the Daily Verse widget can
        // pick the right translation. Updates flow through updateLanguage(_:).
        UserDefaults(suiteName: "group.d.DailyDee")?.set(self.appLanguage.rawValue, forKey: UserDefaultsKeys.appLanguage)

        // Nudge-Empfangs-Einstellungen und App-Sprache einmal pushen, wenn
        // der Nutzer (de-)authentifiziert. Vorher fehlt der uid; die Sprache
        // braucht die Cloud Function für lokalisierte Freundes-Pushes.
        accountSub = AuthService.shared.currentAccountSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] account in
                guard let self, account != nil else { return }
                self.mirrorNudgePreferences()
                AuthService.shared.publishLanguage(self.appLanguage)
            }
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
        // Mirror to App Group so the Daily Verse widget picks the right translation.
        UserDefaults(suiteName: "group.d.DailyDee")?.set(language.rawValue, forKey: UserDefaultsKeys.appLanguage)
        WidgetCenter.shared.reloadAllTimelines()
        // Notify PrayerTimeManager so it can re-sync widget prayer names.
        NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
        // Cloud Function lokalisiert Freundes-Pushes über das Profilfeld.
        AuthService.shared.publishLanguage(language)
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

// MARK: - Notification Names

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("dailydee.appLanguageDidChange")
}

enum MainTab: Int, CaseIterable {
    case start = 0
    case quran
    case lernen
    case gebet
    case friends

    func title(lang: AppLanguage) -> String {
        switch self {
        case .start:   return L10n.tabStart(lang)
        case .quran:   return L10n.tabQuran(lang)
        case .lernen:  return L10n.tabLernen(lang)
        case .gebet:   return L10n.tabGebet(lang)
        case .friends: return L10n.tabFriends(lang)
        }
    }

    var iconName: String {
        switch self {
        case .start:   return "house.fill"
        case .quran:   return "book.fill"
        case .lernen:  return "graduationcap.fill"
        case .gebet:   return "heart.fill"
        case .friends: return "person.2.fill"
        }
    }
}
