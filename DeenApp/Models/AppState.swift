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
    static let calculationMethod = "dailydee.calculationMethod"
    static let dailyReadPages = "dailydee.dailyReadPages"
    static let dailyGoalPages = "dailydee.dailyGoalPages"
    static let lastReadDate = "dailydee.lastReadDate"
    static let isTajweedEnabled = "dailydee.isTajweedEnabled"
}

final class AppState: ObservableObject {
    @Published var selectedTab: MainTab = .start
    @Published var userName: String
    @Published var appLanguage: AppLanguage
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedCity: AppCity
    @Published var calculationMethod: CalculationMethod

    // MARK: - Tajweed
    @Published var isTajweedEnabled: Bool {
        didSet { UserDefaults.standard.set(isTajweedEnabled, forKey: UserDefaultsKeys.isTajweedEnabled) }
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
        calculationMethod: CalculationMethod = .ditib
    ) {
        self.userName = UserDefaults.standard.string(forKey: UserDefaultsKeys.userName) ?? userName
        let rawLang = UserDefaults.standard.string(forKey: UserDefaultsKeys.appLanguage)
        self.appLanguage = rawLang.flatMap(AppLanguage.init(rawValue:)) ?? appLanguage
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingCompleted)
        let rawCity = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedCity)
        self.selectedCity = rawCity.flatMap(AppCity.init(rawValue:)) ?? selectedCity
        if let rawInt = UserDefaults.standard.object(forKey: UserDefaultsKeys.calculationMethod) as? Int,
           let saved = CalculationMethod(rawValue: rawInt) {
            self.calculationMethod = saved
        } else {
            self.calculationMethod = calculationMethod
        }

        // Tajweed: defaults to true
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.isTajweedEnabled) != nil {
            self.isTajweedEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isTajweedEnabled)
        } else {
            self.isTajweedEnabled = true
        }

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

    func updateCalculationMethod(_ method: CalculationMethod) {
        calculationMethod = method
        UserDefaults.standard.set(method.rawValue, forKey: UserDefaultsKeys.calculationMethod)
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
