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
    static func tabFriends(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Freunde"
        case .english: return "Friends"
        case .turkish: return "Arkadaşlar"
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
    static func quranPDF(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "PDF"
        case .english: return "PDF"
        case .turkish: return "PDF"
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

    // MARK: - Reframe Salah picker (notification body style)

    /// Section title above the reframe picker in Settings.
    static func notificationReframeTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english:                                return "Notification style"
        case .turkish:                                return "Bildirim metni"
        default:                                      return "Benachrichtigungstext"
        }
    }

    /// One-line explanation shown beneath the reframe section title.
    static func notificationReframeSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "How should we reframe salah for you?"
        case .turkish: return "Namazı senin için nasıl çerçeveleyelim?"
        default:       return "Wie sollen wir das Gebet für dich beschreiben?"
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

    // MARK: - Konto & Freunde

    static func accountSection(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Konto & Freunde"
        case .english: return "Account & Friends"
        case .turkish: return "Hesap & Arkadaşlar"
        }
    }
    static func accountSubtitleGuest(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Optional – melde dich an, um Freunde hinzuzufügen."
        case .english: return "Optional — sign in to add friends."
        case .turkish: return "İsteğe bağlı — arkadaş eklemek için giriş yap."
        }
    }
    static func accountSubtitleSignedIn(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Angemeldet"
        case .english: return "Signed in"
        case .turkish: return "Giriş yapıldı"
        }
    }
    static func accountSignIn(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Anmelden"
        case .english: return "Sign in"
        case .turkish: return "Giriş yap"
        }
    }
    static func accountSignUp(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Konto erstellen"
        case .english: return "Create account"
        case .turkish: return "Hesap oluştur"
        }
    }
    static func accountSignOut(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Abmelden"
        case .english: return "Sign out"
        case .turkish: return "Çıkış yap"
        }
    }
    static func accountEmail(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "E-Mail"
        case .english: return "Email"
        case .turkish: return "E-posta"
        }
    }
    static func accountPassword(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Passwort"
        case .english: return "Password"
        case .turkish: return "Şifre"
        }
    }
    static func accountUsername(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Benutzername"
        case .english: return "Username"
        case .turkish: return "Kullanıcı adı"
        }
    }
    static func accountDisplayName(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Anzeigename (optional)"
        case .english: return "Display name (optional)"
        case .turkish: return "Görünen ad (isteğe bağlı)"
        }
    }
    static func accountUsernameHint(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "3–20 Zeichen, a–z, 0–9, _ oder ."
        case .english: return "3–20 chars, a–z, 0–9, _ or ."
        case .turkish: return "3–20 karakter, a–z, 0–9, _ veya ."
        }
    }
    static func accountSwitchToSignUp(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Noch kein Konto? Registrieren"
        case .english: return "No account yet? Sign up"
        case .turkish: return "Hesabın yok mu? Kayıt ol"
        }
    }
    static func accountSwitchToSignIn(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Bereits ein Konto? Anmelden"
        case .english: return "Already have an account? Sign in"
        case .turkish: return "Zaten hesabın var mı? Giriş yap"
        }
    }

    static func friendsTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Freunde"
        case .english: return "Friends"
        case .turkish: return "Arkadaşlar"
        }
    }
    static func friendsAdd(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Freund hinzufügen"
        case .english: return "Add friend"
        case .turkish: return "Arkadaş ekle"
        }
    }
    static func friendsSearchPlaceholder(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Benutzername eingeben…"
        case .english: return "Enter username…"
        case .turkish: return "Kullanıcı adı gir…"
        }
    }
    static func friendsNone(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Du hast noch keine Freunde hinzugefügt."
        case .english: return "You haven't added any friends yet."
        case .turkish: return "Henüz arkadaş eklemedin."
        }
    }
    static func friendsIncoming(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Eingehende Anfragen"
        case .english: return "Incoming requests"
        case .turkish: return "Gelen istekler"
        }
    }
    static func friendsOutgoing(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Gesendete Anfragen"
        case .english: return "Sent requests"
        case .turkish: return "Gönderilen istekler"
        }
    }
    static func friendsNoRequests(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Keine offenen Anfragen."
        case .english: return "No pending requests."
        case .turkish: return "Bekleyen istek yok."
        }
    }
    static func friendsAccept(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Annehmen"
        case .english: return "Accept"
        case .turkish: return "Kabul et"
        }
    }
    static func friendsReject(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Ablehnen"
        case .english: return "Reject"
        case .turkish: return "Reddet"
        }
    }
    static func friendsCancelRequest(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Zurückziehen"
        case .english: return "Cancel"
        case .turkish: return "Geri çek"
        }
    }
    static func friendsRemove(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Entfernen"
        case .english: return "Remove"
        case .turkish: return "Kaldır"
        }
    }
    static func friendsRequestSent(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Anfrage gesendet."
        case .english: return "Request sent."
        case .turkish: return "İstek gönderildi."
        }
    }

    // MARK: - Goals (Dashboard)

    static func goalsSectionTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Meine Ziele"
        case .english: return "My Goals"
        case .turkish: return "Hedeflerim"
        }
    }
    static func goalsSetFirst(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Setze dein erstes Ziel"
        case .english: return "Set your first goal"
        case .turkish: return "İlk hedefini belirle"
        }
    }
    static func goalsActiveCount(_ lang: AppLanguage, _ n: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish:
            return n == 1 ? "1 aktives Ziel" : "\(n) aktive Ziele"
        case .english:
            return n == 1 ? "1 active goal" : "\(n) active goals"
        case .turkish:
            return "\(n) aktif hedef"
        }
    }
    static func goalsMoreCount(_ lang: AppLanguage, _ n: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "+ \(n) weitere"
        case .english: return "+ \(n) more"
        case .turkish: return "+ \(n) daha"
        }
    }
    static func goalsAddTapHint(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Tippe, um ein Ziel anzulegen"
        case .english: return "Tap to add a goal"
        case .turkish: return "Hedef eklemek için dokun"
        }
    }
    static func goalsAddNew(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Neues Ziel"
        case .english: return "New Goal"
        case .turkish: return "Yeni Hedef"
        }
    }
    static func goalsEmptyTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Noch keine Ziele"
        case .english: return "No goals yet"
        case .turkish: return "Henüz hedef yok"
        }
    }
    static func goalsEmptyBody(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Lege ein Ziel an, um deinen Fortschritt zu verfolgen — und teile es mit deinen Freunden, wenn du magst."
        case .english: return "Add a goal to track your progress — and share it with your friends if you like."
        case .turkish: return "İlerlemeni takip etmek için bir hedef ekle — istersen arkadaşlarınla paylaş."
        }
    }
    static func goalsPickType(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Zielart"
        case .english: return "Goal type"
        case .turkish: return "Hedef türü"
        }
    }
    static func goalsConfigureTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Details"
        case .english: return "Details"
        case .turkish: return "Detaylar"
        }
    }
    static func goalsCreate(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Ziel anlegen"
        case .english: return "Create Goal"
        case .turkish: return "Hedef oluştur"
        }
    }
    static func goalsDetailTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Ziel"
        case .english: return "Goal"
        case .turkish: return "Hedef"
        }
    }
    static func goalsDelete(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Ziel löschen"
        case .english: return "Delete goal"
        case .turkish: return "Hedefi sil"
        }
    }
    static func goalsProgress(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Fortschritt"
        case .english: return "Progress"
        case .turkish: return "İlerleme"
        }
    }
    static func goalsShareWithFriends(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Mit Freunden teilen"
        case .english: return "Share with friends"
        case .turkish: return "Arkadaşlarla paylaş"
        }
    }
    static func goalsShareBlurb(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Deine Freunde sehen dann Titel und Fortschritt dieses Ziels."
        case .english: return "Friends will see the title and progress of this goal."
        case .turkish: return "Arkadaşların bu hedefin başlığını ve ilerlemesini görür."
        }
    }

    // MARK: - Goal type labels

    static func goalTypeKhatm(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Khatm bis Datum"
        case .english: return "Khatm by date"
        case .turkish: return "Hatim bitir"
        }
    }
    static func goalTypeKhatmBlurb(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Quran komplett bis zu einem bestimmten Tag lesen."
        case .english: return "Finish reading the whole Quran by a target date."
        case .turkish: return "Belirli bir tarihe kadar Kur'an'ı bitir."
        }
    }
    static func goalTypeDailyPages(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Tagesseiten"
        case .english: return "Daily pages"
        case .turkish: return "Günlük sayfa"
        }
    }
    static func goalTypeDailyPagesBlurb(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Jeden Tag eine feste Anzahl Seiten lesen."
        case .english: return "Read a set number of pages every day."
        case .turkish: return "Her gün belirli sayıda sayfa oku."
        }
    }
    static func goalTypeFivePrayers(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Fünf Pflichtgebete"
        case .english: return "Five daily prayers"
        case .turkish: return "Beş vakit namaz"
        }
    }
    static func goalTypeFivePrayersBlurb(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Jeden Tag alle fünf Pflichtgebete verrichten."
        case .english: return "Pray all five fard prayers every day."
        case .turkish: return "Her gün beş vakit namazı kıl."
        }
    }
    static func goalTypeSunnah(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Sunnah-Gebet"
        case .english: return "Sunnah prayer"
        case .turkish: return "Sünnet namazı"
        }
    }
    static func goalTypeSunnahBlurb(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Tahajjud, Witr oder Duha mit Wochenziel."
        case .english: return "Tahajjud, Witr or Duha with a weekly target."
        case .turkish: return "Teheccüd, Vitir veya Duha — haftalık hedef."
        }
    }

    // MARK: - Sunnah names

    static func goalSunnahTahajjud(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Tahajjud"
        case .english: return "Tahajjud"
        case .turkish: return "Teheccüd"
        }
    }
    static func goalSunnahWitr(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Witr"
        case .english: return "Witr"
        case .turkish: return "Vitir"
        }
    }
    static func goalSunnahDuha(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Duha"
        case .english: return "Duha"
        case .turkish: return "Duha"
        }
    }

    // MARK: - Goal units & detail rows

    static func goalsPagesUnit(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Seiten"
        case .english: return "pages"
        case .turkish: return "sayfa"
        }
    }
    static func goalsPrayersUnit(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Gebete"
        case .english: return "prayers"
        case .turkish: return "namaz"
        }
    }
    static func goalsThisWeekUnit(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "diese Woche"
        case .english: return "this week"
        case .turkish: return "bu hafta"
        }
    }
    static func goalsPerWeek(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "pro Woche"
        case .english: return "per week"
        case .turkish: return "haftada"
        }
    }
    static func goalsKhatmTargetDate(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Bis wann möchtest du das Khatm abschließen?"
        case .english: return "When do you want to finish the khatm?"
        case .turkish: return "Hatmi ne zamana bitirmek istiyorsun?"
        }
    }
    static func goalsKhatmReadSoFar(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Bisher gelesen"
        case .english: return "Read so far"
        case .turkish: return "Şimdiye kadar okunan"
        }
    }
    static func goalsKhatmDaysLeft(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Verbleibende Tage"
        case .english: return "Days remaining"
        case .turkish: return "Kalan gün"
        }
    }
    static func goalsKhatmPerDay(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Pro Tag benötigt"
        case .english: return "Pages per day needed"
        case .turkish: return "Günde gereken"
        }
    }
    static func goalsDailyPagesTarget(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Wie viele Seiten pro Tag?"
        case .english: return "How many pages per day?"
        case .turkish: return "Günde kaç sayfa?"
        }
    }
    static func goalsDailyReadToday(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Heute gelesen"
        case .english: return "Read today"
        case .turkish: return "Bugün okunan"
        }
    }
    static func goalsDailyTarget(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Tagesziel"
        case .english: return "Daily target"
        case .turkish: return "Günlük hedef"
        }
    }
    static func goalsFivePrayersBlurb(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Hake jedes Pflichtgebet ab, sobald du es verrichtet hast."
        case .english: return "Check off each fard prayer once you've completed it."
        case .turkish: return "Her farz namazı kıldıkça işaretle."
        }
    }
    static func goalsTickPrayersToday(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Heutige Gebete"
        case .english: return "Today's prayers"
        case .turkish: return "Bugünün namazları"
        }
    }
    static func goalsSunnahPick(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Welches Sunnah-Gebet?"
        case .english: return "Which sunnah prayer?"
        case .turkish: return "Hangi sünnet namazı?"
        }
    }
    static func goalsSunnahThisWeek(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Diese Woche"
        case .english: return "This week"
        case .turkish: return "Bu hafta"
        }
    }
    static func goalsSunnahLogToday(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Heute eintragen"
        case .english: return "Log for today"
        case .turkish: return "Bugüne kaydet"
        }
    }
    static func goalsSunnahLoggedToday(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Heute schon eingetragen"
        case .english: return "Logged for today"
        case .turkish: return "Bugün kaydedildi"
        }
    }

    // MARK: - Friends tab

    static func friendsTabTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Freunde"
        case .english: return "Friends"
        case .turkish: return "Arkadaşlar"
        }
    }
    static func friendsTabSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Geteilte Ziele auf einen Blick"
        case .english: return "Shared goals at a glance"
        case .turkish: return "Paylaşılan hedeflere göz at"
        }
    }
    static func friendsTabEmpty(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Noch keine Freunde — füge welche hinzu, um ihre Ziele zu sehen."
        case .english: return "No friends yet — add some to see their goals."
        case .turkish: return "Henüz arkadaşın yok — hedeflerini görmek için ekleyin."
        }
    }
    static func friendsTabNoSharedGoals(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Keine geteilten Ziele"
        case .english: return "No shared goals"
        case .turkish: return "Paylaşılan hedef yok"
        }
    }
    static func friendsTabSignInTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Melde dich an"
        case .english: return "Sign in"
        case .turkish: return "Oturum aç"
        }
    }
    static func friendsTabSignInBody(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Erstelle ein Konto oder melde dich an, um Freunde hinzuzufügen und Ziele zu teilen."
        case .english: return "Create an account or sign in to add friends and share goals."
        case .turkish: return "Arkadaş eklemek ve hedef paylaşmak için bir hesap oluştur veya giriş yap."
        }
    }
    static func friendsTabSignInButton(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Zum Konto"
        case .english: return "Go to account"
        case .turkish: return "Hesaba git"
        }
    }

    // MARK: - Common buttons (reused)

    static func commonDone(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Fertig"
        case .english: return "Done"
        case .turkish: return "Tamam"
        }
    }
    static func commonEdit(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Bearbeiten"
        case .english: return "Edit"
        case .turkish: return "Düzenle"
        }
    }
    static func commonRemove(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Entfernen"
        case .english: return "Remove"
        case .turkish: return "Kaldır"
        }
    }
    static func citySearchHint(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish:
            return "Stadt nicht dabei? Tippe oben in die Suchleiste — alle DITIB-Städte sind durchsuchbar."
        case .english:
            return "City not listed? Tap the search bar above — every DITIB city is searchable."
        case .turkish:
            return "Şehrin listede yok mu? Yukarıdaki arama çubuğuna dokun — tüm DİTİB şehirleri aranabilir."
        }
    }
    static func commonCancel(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Abbrechen"
        case .english: return "Cancel"
        case .turkish: return "İptal"
        }
    }
    static func commonSend(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Senden"
        case .english: return "Send"
        case .turkish: return "Gönder"
        }
    }

    // MARK: - Manual page adjustment & khatma mode

    static func goalsAdjustToday(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Heute manuell anpassen"
        case .english: return "Adjust today manually"
        case .turkish: return "Bugünü elle ayarla"
        }
    }
    static func goalsKhatmaModeOn(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Khatma-Modus aktiv"
        case .english: return "Khatma mode active"
        case .turkish: return "Hatim modu aktif"
        }
    }
    static func goalsKhatmaModeToggle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Khatma-Modus"
        case .english: return "Khatma mode"
        case .turkish: return "Hatim modu"
        }
    }
    static func goalsKhatmaBookmark(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Lesezeichen"
        case .english: return "Bookmark"
        case .turkish: return "Yer imi"
        }
    }
    static func goalsKhatmaResume(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Khatma fortsetzen"
        case .english: return "Resume khatma"
        case .turkish: return "Hatime devam et"
        }
    }

    // MARK: - Friend nudges

    static func nudgeButton(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Anstupsen"
        case .english: return "Nudge"
        case .turkish: return "Dürtükle"
        }
    }
    static func nudgePickMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Wähle eine Erinnerung"
        case .english: return "Choose a reminder"
        case .turkish: return "Bir hatırlatma seç"
        }
    }
    static func nudgeSent(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Anstupser gesendet"
        case .english: return "Nudge sent"
        case .turkish: return "Dürtü gönderildi"
        }
    }
    static func nudgeFailed(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Senden fehlgeschlagen"
        case .english: return "Sending failed"
        case .turkish: return "Gönderme başarısız"
        }
    }
    static func nudgeMsgPrayer(_ lang: AppLanguage, prayerName: String) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Hast du schon \(prayerName) gebetet?"
        case .english: return "Have you prayed \(prayerName) yet?"
        case .turkish: return "\(prayerName) namazını kıldın mı?"
        }
    }
    static func nudgeMsgPages(_ lang: AppLanguage, pages: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Hast du heute deine \(pages) Seiten schon gelesen?"
        case .english: return "Have you read your \(pages) pages today?"
        case .turkish: return "Bugün \(pages) sayfanı okudun mu?"
        }
    }
    static func nudgeMsgKhatma(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Vergiss heute deine Khatma nicht!"
        case .english: return "Don't forget your khatma today!"
        case .turkish: return "Bugün hatimini unutma!"
        }
    }
    static func nudgeMsgSunnah(_ lang: AppLanguage, prayerName: String) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Hast du heute \(prayerName) gebetet?"
        case .english: return "Have you prayed \(prayerName) today?"
        case .turkish: return "Bugün \(prayerName) namazını kıldın mı?"
        }
    }

    // MARK: - Notification preferences

    static func notificationsSectionTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Benachrichtigungen"
        case .english: return "Notifications"
        case .turkish: return "Bildirimler"
        }
    }
    static func nudgesReceiveToggle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Anstupser von Freunden empfangen"
        case .english: return "Receive nudges from friends"
        case .turkish: return "Arkadaş dürtülerini al"
        }
    }
    static func nudgesMaxPerDay(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Max. Anstupser pro Tag"
        case .english: return "Max nudges per day"
        case .turkish: return "Günlük maks. dürtü"
        }
    }
    static func nudgesMaxPerDayHint(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Begrenzt, wie viele Erinnerungen dich pro Tag erreichen."
        case .english: return "Caps how many reminders reach you each day."
        case .turkish: return "Günde sana ulaşacak hatırlatma sayısını sınırlar."
        }
    }

    // MARK: - Account: Passwort-Reset & Konto löschen

    static func authForgotPassword(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Passwort vergessen?"
        case .english: return "Forgot password?"
        case .turkish: return "Şifreni mi unuttun?"
        }
    }
    static func authResetEmailSent(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Wir haben dir eine E-Mail zum Zurücksetzen des Passworts geschickt."
        case .english: return "We've sent you a password-reset email."
        case .turkish: return "Sana şifre sıfırlama e-postası gönderdik."
        }
    }
    static func authResetNeedsEmail(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Gib zuerst deine E-Mail-Adresse ein."
        case .english: return "Enter your email address first."
        case .turkish: return "Önce e-posta adresini gir."
        }
    }
    static func accountDelete(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Konto löschen"
        case .english: return "Delete account"
        case .turkish: return "Hesabı sil"
        }
    }
    static func accountDeleteConfirmTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Konto wirklich löschen?"
        case .english: return "Really delete your account?"
        case .turkish: return "Hesap gerçekten silinsin mi?"
        }
    }
    static func accountDeleteConfirmMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Dein Profil, deine Freundschaften und geteilten Ziele werden dauerhaft entfernt. Das lässt sich nicht rückgängig machen."
        case .english: return "Your profile, friendships and shared goals will be removed permanently. This cannot be undone."
        case .turkish: return "Profilin, arkadaşlıkların ve paylaşılan hedeflerin kalıcı olarak silinecek. Bu geri alınamaz."
        }
    }

    // MARK: - Friend reminders (freie Erinnerungen ohne geteiltes Ziel)

    static func reminderComposerTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Erinnerung senden"
        case .english: return "Send a reminder"
        case .turkish: return "Hatırlatma gönder"
        }
    }
    static func reminderSectionPrayer(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Gebet"
        case .english: return "Prayer"
        case .turkish: return "Namaz"
        }
    }
    static func reminderSectionQuran(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Qur'an & Dhikr"
        case .english: return "Qur'an & dhikr"
        case .turkish: return "Kur'an ve zikir"
        }
    }
    static func reminderSectionCustom(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Eigene Nachricht"
        case .english: return "Custom message"
        case .turkish: return "Kendi mesajın"
        }
    }
    static func reminderCustomPlaceholder(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Schreib eine kurze Erinnerung …"
        case .english: return "Write a short reminder…"
        case .turkish: return "Kısa bir hatırlatma yaz…"
        }
    }
    static func reminderSend(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Senden"
        case .english: return "Send"
        case .turkish: return "Gönder"
        }
    }
    static func nudgeMsgQuranGeneric(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Hast du heute schon Qur'an gelesen?"
        case .english: return "Have you read Qur'an today?"
        case .turkish: return "Bugün Kur'an okudun mu?"
        }
    }
    static func nudgeMsgDhikr(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Vergiss dein Dhikr heute nicht 🤲"
        case .english: return "Don't forget your dhikr today 🤲"
        case .turkish: return "Bugün zikrini unutma 🤲"
        }
    }

    // MARK: - Hifz Tracker

    static func hifzTrackerTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Hifz-Tracker"
        case .english: return "Hifz Tracker"
        case .turkish: return "Hıfz Takibi"
        }
    }
    static func hifzTrackerSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Verfolge auswendig gelernte Suren und Wiederholungen"
        case .english: return "Track memorised surahs and revisions"
        case .turkish: return "Ezberlediğin sureleri ve tekrarları takip et"
        }
    }
    static func hifzAdd(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Hinzufügen"
        case .english: return "Add"
        case .turkish: return "Ekle"
        }
    }
    static func hifzAddTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Auswendig gelernt"
        case .english: return "Mark as memorised"
        case .turkish: return "Ezberlendi olarak işaretle"
        }
    }
    static func hifzSelectSurah(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Sure auswählen"
        case .english: return "Select Surah"
        case .turkish: return "Sure seç"
        }
    }
    static func hifzScope(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Umfang"
        case .english: return "Scope"
        case .turkish: return "Kapsam"
        }
    }
    static func hifzScopeFullSurah(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Ganze Sure"
        case .english: return "Full Surah"
        case .turkish: return "Tüm Sure"
        }
    }
    static func hifzScopeAyatRange(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Ayah-Bereich"
        case .english: return "Ayah range"
        case .turkish: return "Ayet aralığı"
        }
    }
    static func hifzScopePages(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Seiten"
        case .english: return "Pages"
        case .turkish: return "Sayfalar"
        }
    }
    static func hifzAyahFrom(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Von Ayah"
        case .english: return "From ayah"
        case .turkish: return "Başlangıç ayet"
        }
    }
    static func hifzAyahTo(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Bis Ayah"
        case .english: return "To ayah"
        case .turkish: return "Bitiş ayet"
        }
    }
    static func hifzPagesCount(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Anzahl Seiten"
        case .english: return "Number of pages"
        case .turkish: return "Sayfa sayısı"
        }
    }
    static func hifzSave(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Speichern"
        case .english: return "Save"
        case .turkish: return "Kaydet"
        }
    }
    static func hifzCancel(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Abbrechen"
        case .english: return "Cancel"
        case .turkish: return "İptal"
        }
    }
    static func hifzDelete(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Löschen"
        case .english: return "Delete"
        case .turkish: return "Sil"
        }
    }
    static func hifzMarkRevised(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Wiederholt"
        case .english: return "Revised"
        case .turkish: return "Tekrar edildi"
        }
    }
    static func hifzEmptyTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Noch keine Einträge"
        case .english: return "Nothing tracked yet"
        case .turkish: return "Henüz kayıt yok"
        }
    }
    static func hifzEmptyHint(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Tippe auf \"Hinzufügen\", um eine auswendig gelernte Sure zu erfassen."
        case .english: return "Tap \"Add\" to record a memorised surah."
        case .turkish: return "Ezberlediğin bir sureyi eklemek için \"Ekle\" düğmesine dokun."
        }
    }
    static func hifzLastRevised(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Zuletzt wiederholt"
        case .english: return "Last revised"
        case .turkish: return "Son tekrar"
        }
    }
    static func hifzJustNow(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "gerade eben"
        case .english: return "just now"
        case .turkish: return "az önce"
        }
    }
    static func hifzAgoMinutes(_ lang: AppLanguage, minutes: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "vor \(minutes) Min."
        case .english: return "\(minutes) min ago"
        case .turkish: return "\(minutes) dk önce"
        }
    }
    static func hifzAgoHours(_ lang: AppLanguage, hours: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "vor \(hours) Std."
        case .english: return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        case .turkish: return "\(hours) saat önce"
        }
    }
    static func hifzAgoDays(_ lang: AppLanguage, days: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return days == 1 ? "vor 1 Tag" : "vor \(days) Tagen"
        case .english: return days == 1 ? "1 day ago" : "\(days) days ago"
        case .turkish: return "\(days) gün önce"
        }
    }
    static func hifzOverdueBadge(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Wiederholung fällig"
        case .english: return "Revision due"
        case .turkish: return "Tekrar zamanı"
        }
    }
    static func hifzPortionFullSurah(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Ganze Sure"
        case .english: return "Full surah"
        case .turkish: return "Tüm sure"
        }
    }
    static func hifzPortionAyah(_ lang: AppLanguage, ayah: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Ayah \(ayah)"
        case .english: return "Ayah \(ayah)"
        case .turkish: return "Ayet \(ayah)"
        }
    }
    static func hifzPortionAyahRange(_ lang: AppLanguage, from: Int, to: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Ayah \(from)–\(to)"
        case .english: return "Ayah \(from)–\(to)"
        case .turkish: return "Ayet \(from)–\(to)"
        }
    }
    static func hifzPortionPages(_ lang: AppLanguage, count: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return count == 1 ? "1 Seite" : "\(count) Seiten"
        case .english: return count == 1 ? "1 page" : "\(count) pages"
        case .turkish: return "\(count) sayfa"
        }
    }
    static func hifzNotificationTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Zeit zu wiederholen"
        case .english: return "Time to revise"
        case .turkish: return "Tekrar zamanı"
        }
    }
    static func hifzNotificationBody(_ lang: AppLanguage, surahName: String) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish:
            return "Sure \(surahName) ist heute zur Wiederholung fällig."
        case .english:
            return "Surah \(surahName) is due for revision today."
        case .turkish:
            return "\(surahName) suresinin bugün tekrarı var."
        }
    }
    /// Body für Sammel-Notifications, wenn mehrere Suren am selben Tag fällig sind.
    /// `namesList` ist bereits auf max. N Namen gekürzt; `remainder` zählt die
    /// nicht aufgezählten weiteren Suren.
    static func hifzNotificationBodyMulti(_ lang: AppLanguage, count: Int, namesList: String, remainder: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish:
            if remainder > 0 {
                return "\(count) Suren stehen heute zur Wiederholung an: \(namesList) und \(remainder) weitere."
            } else {
                return "\(count) Suren stehen heute zur Wiederholung an: \(namesList)."
            }
        case .english:
            if remainder > 0 {
                return "\(count) surahs are due for revision today: \(namesList) and \(remainder) more."
            } else {
                return "\(count) surahs are due for revision today: \(namesList)."
            }
        case .turkish:
            if remainder > 0 {
                return "Bugün \(count) sure tekrar için bekliyor: \(namesList) ve \(remainder) daha."
            } else {
                return "Bugün \(count) sure tekrar için bekliyor: \(namesList)."
            }
        }
    }
    static func hifzLearnModeTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Hifz-Tracker"
        case .english: return "Hifz Tracker"
        case .turkish: return "Hıfz Takibi"
        }
    }
    static func hifzLearnModeSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Gelernte Suren + 3-Tage-Wiederholung"
        case .english: return "Memorised surahs + 3-day revision reminders"
        case .turkish: return "Ezberlenen sureler + 3 günlük tekrar hatırlatması"
        }
    }
    static func hifzBack(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Zurück"
        case .english: return "Back"
        case .turkish: return "Geri"
        }
    }
    static func hifzSelectedCount(_ lang: AppLanguage, count: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return count == 1 ? "1 Sure ausgewählt" : "\(count) Suren ausgewählt"
        case .english: return count == 1 ? "1 surah selected" : "\(count) surahs selected"
        case .turkish: return "\(count) sure seçildi"
        }
    }
    static func hifzMultiSelectHint(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish:
            return "Bei mehreren Suren wird jede als \"Ganze Sure\" gespeichert."
        case .english:
            return "When multiple surahs are selected, each is saved as a full surah."
        case .turkish:
            return "Birden fazla sure seçildiğinde her biri tüm sure olarak kaydedilir."
        }
    }
    static func hifzDone(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Fertig"
        case .english: return "Done"
        case .turkish: return "Tamam"
        }
    }
    static func hifzStatsTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Dein Fortschritt"
        case .english: return "Your Progress"
        case .turkish: return "İlerlemen"
        }
    }
    static func hifzStatsQuranProgress(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Quran auswendig"
        case .english: return "Quran memorised"
        case .turkish: return "Ezberlenen Kur'an"
        }
    }
    static func hifzStatsSurahsLabel(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Suren"
        case .english: return "Surahs"
        case .turkish: return "Sure"
        }
    }
    static func hifzStatsAyatLabel(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Ayat"
        case .english: return "Ayat"
        case .turkish: return "Ayet"
        }
    }
    static func hifzStatsEntriesLabel(_ lang: AppLanguage) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "Einträge"
        case .english: return "Entries"
        case .turkish: return "Kayıt"
        }
    }
    static func hifzStatsOverdue(_ lang: AppLanguage, count: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish: return "\(count) überfällig"
        case .english: return "\(count) overdue"
        case .turkish: return "\(count) gecikmiş"
        }
    }
    static func hifzStatsLongest(_ lang: AppLanguage, surahName: String, ayat: Int) -> String {
        switch lang {
        case .german, .germanArabic, .germanTurkish:
            return "Längste komplette Sure: \(surahName) (\(ayat) Ayat)"
        case .english:
            return "Longest complete surah: \(surahName) (\(ayat) ayat)"
        case .turkish:
            return "En uzun tam sure: \(surahName) (\(ayat) ayet)"
        }
    }
}
