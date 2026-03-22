//
//  L10n.swift
//  DeenApp
//
//  Zentrale Texte je nach App-Sprache (DE, EN, TR, DE/AR).
//

import SwiftUI

enum L10n {

    // MARK: - Begrüßung (nur arabischer Text, Schriftart wird animiert)
    static let greetingArabic = "السَّلَامُ عَلَيْكُمْ"

    // MARK: - Tabs
    static func tabStart(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Start"
        case .english: return "Home"
        case .turkish: return "Ana Sayfa"
        }
    }
    static func tabQuran(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Kur'an"
        case .english: return "Quran"
        case .turkish: return "Kur'an"
        }
    }
    static func tabLernen(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Lernen"
        case .english: return "Learn"
        case .turkish: return "Öğren"
        }
    }
    static func tabGebet(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Gebet"
        case .english: return "Prayer"
        case .turkish: return "Namaz"
        }
    }

    // MARK: - Dashboard
    static func nextPrayer(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "NÄCHSTES GEBET"
        case .english: return "NEXT PRAYER"
        case .turkish: return "SONRAKI NAMAZ"
        }
    }
    static func todayPrayerTimes(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "HEUTIGE GEBETSZEITEN"
        case .english: return "TODAY'S PRAYER TIMES"
        case .turkish: return "BUGÜNKÜ NAMAZ VAKİTLERİ"
        }
    }
    static func quranContinue(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Weiterlesen"
        case .english: return "Continue Reading"
        case .turkish: return "Okumaya Devam"
        }
    }
    static func vocabulary(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Vokabeln"
        case .english: return "Vocabulary"
        case .turkish: return "Kelime"
        }
    }
    static func flashcards(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Karteikarten"
        case .english: return "Flashcards"
        case .turkish: return "Kartlar"
        }
    }
    static func loadingPrayerTimes(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Gebetszeiten werden geladen…"
        case .english: return "Loading prayer times…"
        case .turkish: return "Namaz vakitleri yükleniyor…"
        }
    }
    static func oClock(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Uhr"
        case .english: return "o'clock"
        case .turkish: return ""
        }
    }

    // MARK: - Gebetsnamen (DE/AR: lateinisch, DE/TR: türkisch)
    static func prayerName(_ kind: PrayerKind, _ lang: AppLanguage) -> String {
        if lang.isIslamicTermsLatin { return kind.latinArabicName }
        if lang.isIslamicTermsTurkish { return kind.turkishName }
        switch lang {
        case .german, .germanArabic, .germanTurkish:
            return kind.germanName
        case .english:
            return kind.englishName
        case .turkish:
            return kind.turkishName
        }
    }

    // MARK: - Onboarding
    static func onboardingTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Willkommen bei DailyDee"
        case .english: return "Welcome to DailyDee"
        case .turkish: return "DailyDee'ye Hoş Geldiniz"
        }
    }
    static func onboardingNamePrompt(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Wie sollen wir dich nennen?"
        case .english: return "What should we call you?"
        case .turkish: return "Sana nasıl hitap edelim?"
        }
    }
    static func onboardingLanguagePrompt(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "App-Sprache"
        case .english: return "App language"
        case .turkish: return "Uygulama dili"
        }
    }
    static func onboardingContinue(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Weiter"
        case .english: return "Continue"
        case .turkish: return "Devam"
        }
    }

    // MARK: - Quran
    static func quranMushaf(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Mushaf"
        case .english: return "Mushaf"
        case .turkish: return "Mushaf"
        }
    }
    static func quranList(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Listenansicht"
        case .english: return "List view"
        case .turkish: return "Liste"
        }
    }
    static func quranFontSize(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Schriftgröße"
        case .english: return "Font size"
        case .turkish: return "Yazı boyutu"
        }
    }
    static func quranTranslation(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Übersetzung"
        case .english: return "Translation"
        case .turkish: return "Çeviri"
        }
    }
    static func quranArabicFont(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Arabische Schrift"
        case .english: return "Arabic font"
        case .turkish: return "Arapça yazı"
        }
    }
    static func quranNone(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Keine"
        case .english: return "None"
        case .turkish: return "Yok"
        }
    }

    // MARK: - Settings
    static func settingsTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Einstellungen"
        case .english: return "Settings"
        case .turkish: return "Ayarlar"
        }
    }
    static func settingsDone(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Fertig"
        case .english: return "Done"
        case .turkish: return "Tamam"
        }
    }
    static func settingsLocation(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Standort"
        case .english: return "Location"
        case .turkish: return "Konum"
        }
    }
    static func settingsName(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Name"
        case .english: return "Name"
        case .turkish: return "Ad"
        }
    }
    static func settingsNamePlaceholder(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "z. B. Berat"
        case .english: return "e.g. Berat"
        case .turkish: return "örn. Berat"
        }
    }
    static func settingsPrayerSource(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Gebetszeiten-Quelle"
        case .english: return "Prayer Times Source"
        case .turkish: return "Namaz Vakti Kaynağı"
        }
    }
    static func settingsCalculationMethod(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Zeitrechnungsmethode"
        case .english: return "Calculation Method"
        case .turkish: return "Hesaplama Yöntemi"
        }
    }
    static func quranPage(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Seite"
        case .english: return "Page"
        case .turkish: return "Sayfa"
        }
    }

    // MARK: - Daily Reading Goal

    static func quranDailyGoal(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "TAGESZIEL"
        case .english: return "DAILY GOAL"
        case .turkish: return "GÜNLÜK HEDEF"
        }
    }
    static func quranDailyPages(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Seiten"
        case .english: return "pages"
        case .turkish: return "sayfa"
        }
    }
    static func quranDailyGoalReached(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Ziel erreicht! Maşallah 🌟"
        case .english: return "Goal reached! MashaAllah 🌟"
        case .turkish: return "Hedef tamamlandı! Maşallah 🌟"
        }
    }
    static func quranWordByWord(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Wort-für-Wort"
        case .english: return "Word by Word"
        case .turkish: return "Kelime Kelime"
        }
    }

    // MARK: - Quran Tajweed
    static func quranReadingMode(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Lesemodus"
        case .english: return "Reading Mode"
        case .turkish: return "Okuma Modu"
        }
    }
    static func quranReadingModeDescription(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Weißer Hintergrund für bessere Lesbarkeit"
        case .english: return "White background for better legibility"
        case .turkish: return "Daha iyi okunabilirlik için beyaz arka plan"
        }
    }
    static func quranTajweed(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Tajweed-Farben"
        case .english: return "Tajweed Colors"
        case .turkish: return "Tecvid Renkleri"
        }
    }
    static func quranTransliteration(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Transliteration"
        case .english: return "Transliteration"
        case .turkish: return "Transliterasyon"
        }
    }
    static func quranJuz(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Juz"
        case .english: return "Juz"
        case .turkish: return "Cüz"
        }
    }
    static func quranSurahs(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Suren"
        case .english: return "Surahs"
        case .turkish: return "Sureler"
        }
    }

    // MARK: - Besondere Zeiten (Expandable Prayer Card)
    static func specialTimes(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "BESONDERE ZEITEN"
        case .english: return "SPECIAL TIMES"
        case .turkish: return "ÖZEL VAKİTLER"
        }
    }
    static func kerahatTimes(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Kerahat Vakitleri"
        case .english: return "Makruh Times"
        case .turkish: return "Kerahat Vakitleri"
        }
    }
    static func lastThirdNight(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Das letzte Drittel der Nacht"
        case .english: return "Last Third of the Night"
        case .turkish: return "Gecenin Son Üçte Biri"
        }
    }
    static func showDetails(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Besondere Zeiten"
        case .english: return "Special Times"
        case .turkish: return "Özel Vakitler"
        }
    }
}
