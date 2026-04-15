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
        case .german, .germanArabic, .germanTurkish: return "Akh-ira"
        case .english: return "Akh-ira"
        case .turkish: return "Akh-ira"
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

    // MARK: - Notifications
    static func notificationsTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Benachrichtigungen"
        case .english: return "Notifications"
        case .turkish: return "Bildirimler"
        }
    }
    static func notificationsToggleLabel(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Gebetszeit-Erinnerungen"
        case .english: return "Prayer time reminders"
        case .turkish: return "Namaz vakti hatırlatıcıları"
        }
    }
    static func notificationsDescription(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Erhalte eine Benachrichtigung vor und zum Beginn jeder Gebetszeit."
        case .english: return "Get notified before and at the start of each prayer time."
        case .turkish: return "Her namaz vaktinden önce ve başlangıcında bildirim al."
        }
    }

    static func notificationsMinutesBefore(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Vorankündigung"
        case .english: return "Notify before"
        case .turkish: return "Önceden bildir"
        }
    }

    static func notificationsMinutesUnit(_ lang: AppLanguage, minutes: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "\(minutes) Min."
        case .english: return "\(minutes) min"
        case .turkish: return "\(minutes) dk"
        }
    }
    static func notificationsOpenSettings(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "In iOS-Einstellungen aktivieren"
        case .english: return "Enable in iOS Settings"
        case .turkish: return "iOS Ayarlarında etkinleştir"
        }
    }
    static func notificationAtPrayer(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Zeit für das Gebet"
        case .english: return "Time to pray"
        case .turkish: return "Namaz vakti"
        }
    }
    static func notificationBefore(_ lang: AppLanguage, prayerName: String, minutes: Int = 15) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "In \(minutes) Min: \(prayerName)"
        case .english: return "In \(minutes) min: \(prayerName)"
        case .turkish: return "\(minutes) dk sonra: \(prayerName)"
        }
    }
    static func notificationGetReady(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Bereite dich aufs Gebet vor"
        case .english: return "Get ready to pray"
        case .turkish: return "Namaza hazırlan"
        }
    }

    // MARK: - Per-prayer notification quotes (at prayer time)

    /// Returns the hadith/Quran quote used as the notification body when a prayer begins.
    /// Returns nil for Shuruuq so the default "Time to pray" message is used.
    static func notificationPrayerQuote(_ kind: PrayerKind, _ lang: AppLanguage) -> String? {
        switch kind {
        case .shuruuq:
            return nil  // keep default message

        case .imsak:
            switch lang {
            case .german, .germanArabic, .germanTurkish:
                return #"„Es gibt kein Gebet, das den Heuchlern schwerer fällt als das Fajr- (und das Isha)-Gebet.""#
            case .english:
                return "No prayer weighs heavier on the hypocrites than Fajr (and Isha)."
            case .turkish:
                return "Münafiqlara Fajr (ve Yatsi) namazindan daha agir gelen hicbir namaz yoktur."
            }

        case .dhuhr:
            switch lang {
            case .german, .germanArabic, .germanTurkish:
                return #"„Dies ist eine Stunde, in der die Tore des Himmels geöffnet werden.""#
            case .english:
                return "This is an hour when the gates of heaven are opened."
            case .turkish:
                return "Bu, cennet kapilarinin acildigi bir vakittir."
            }

        case .asr:
            switch lang {
            case .german, .germanArabic, .germanTurkish:
                return #"„Haltet die Gebete ein, und (besonders) das mittlere Gebet, und steht demütig vor Allah.""#
            case .english:
                return "Maintain the prayers, especially the middle prayer, and stand before Allah with humility."
            case .turkish:
                return "Namazlara, ozellikle orta namaza devam edin ve Allah'a boyun egererek durun."
            }

        case .maghrib:
            switch lang {
            case .german, .germanArabic, .germanTurkish:
                return #"„Meine Ummah wird nicht aufhören, auf dem rechten Weg zu sein, solange sie das Maghrib-Gebet nicht verzögert.""#
            case .english:
                return "My Ummah will not cease to be upon goodness as long as they do not delay Maghrib."
            case .turkish:
                return "Ummetim Aksam namazini ertelemedigI surece hayir uzere olmaktan vazgecmeyecektir."
            }

        case .isha:
            switch lang {
            case .german, .germanArabic, .germanTurkish:
                return #"„Es gibt kein Gebet, das den Heuchlern schwerer fällt als das (Fajr- und das) Isha-Gebet.""#
            case .english:
                return "No prayer weighs heavier on the hypocrites than Fajr and Isha."
            case .turkish:
                return "Munafiqlara Fajr ve Yatsi namazindan daha agir gelen hicbir namaz yoktur."
            }
        }
    }

    // MARK: - Jumu'ah notification

    static func notificationJumuahTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Jumu'ah"
        case .english: return "Jumu'ah"
        case .turkish: return "Cuma Namazı"
        }
    }

    static func notificationJumuahBody(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish:
            return #"„O die ihr glaubt! Wenn zum Gebet gerufen wird am Freitag, dann eilt zum Gedenken Allahs und lasst das Verkaufen ruhen.""#
        case .english:
            return "O you who believe! When the call to prayer is made on Friday, hasten to the remembrance of Allah and leave off trading."
        case .turkish:
            return "Ey iman edenler! Cuma gunu namaz icin ezan okundugunda, Allah'i anmaya kosun ve alisverisi birakin."
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

    // MARK: - Qada / Kaza Tracker

    static func qadaTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german:        return "Qada-Tracker"
        case .english:       return "Qada Tracker"
        case .turkish:       return "Kaza Takipçisi"
        case .germanArabic:  return "Qada Tracker"
        case .germanTurkish: return "Kaza Tracker"
        }
    }

    static func qadaSetupPrompt(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Nachholgebete einrichten"
        case .english: return "Set up your missed prayers"
        case .turkish: return "Kaza namazlarını ayarla"
        }
    }

    static func qadaMissedLabel(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "ausstehend"
        case .english: return "outstanding"
        case .turkish: return "kaza"
        }
    }

    static func qadaStartDateQuestion(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Wann musstest du anfangen zu beten?"
        case .english: return "When did you need to start praying?"
        case .turkish: return "Ne zaman namaz kılmaya başlaman gerekti?"
        }
    }

    static func qadaHowManyPrayed(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Wie viele Gebete hast du von jedem Gebet seitdem gebetet?"
        case .english: return "How many of each prayer have you prayed since then?"
        case .turkish: return "O günden bu yana her namazdan kaçını kıldın?"
        }
    }

    static func qadaSinceDate(_ lang: AppLanguage, date: Date) -> String {
        let f = qadaDateFormatter(lang)
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Seit \(f.string(from: date))"
        case .english: return "Since \(f.string(from: date))"
        case .turkish: return "\(f.string(from: date)) tarihinden bu yana"
        }
    }

    static func qadaTotalLabel(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "AUSSTEHENDE GEBETE"
        case .english: return "OUTSTANDING PRAYERS"
        case .turkish: return "TOPLAM KAZA"
        }
    }

    static func qadaBack(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Zurück"
        case .english: return "Back"
        case .turkish: return "Geri"
        }
    }

    static func qadaCalculate(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Berechnen"
        case .english: return "Calculate"
        case .turkish: return "Hesapla"
        }
    }

    static func qadaReset(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Zurücksetzen"
        case .english: return "Reset"
        case .turkish: return "Sıfırla"
        }
    }

    static func qadaResetQuestion(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Kaza-Tracker wirklich zurücksetzen?"
        case .english: return "Reset Qada Tracker?"
        case .turkish: return "Kaza takipçisini sıfırla?"
        }
    }

    static func qadaEditHint(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Tippe auf eine Zahl, um sie direkt zu bearbeiten."
        case .english: return "Tap a number to edit it directly."
        case .turkish: return "Bir sayıya dokun ve doğrudan düzenle."
        }
    }

    private static func qadaDateFormatter(_ lang: AppLanguage) -> DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .long
        switch lang {
        case .german, .germanArabic, .germanTurkish: f.locale = Locale(identifier: "de_DE")
        case .english: f.locale = Locale(identifier: "en_US")
        case .turkish: f.locale = Locale(identifier: "tr_TR")
        }
        return f
    }
}
