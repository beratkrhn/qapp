//
//  NotificationReframe.swift
//  DeenApp
//
//  User-selectable phrasing for the body of a prayer-time notification.
//  Inspired by the "Reframe Salah" onboarding step in similar apps —
//  lets the user choose between hadith quotes (default) or a punchy,
//  motivational reminder tone.
//

import Foundation

enum NotificationReframe: String, CaseIterable, Identifiable, Codable {
    /// Per-prayer hadith / Qur'an quotes (the original DailyDee behaviour).
    case hadithQuotes      = "hadith"
    /// "Meeting with Allah due now!"
    case meetingWithAllah  = "meeting"
    /// "Come to Prayer, Come to Success!"  (Hayya 'ala-s-Salah)
    case hayyaAlasSalah    = "hayya"
    /// "1:1 with Allah"
    case oneOnOneWithAllah = "oneOnOne"
    /// "It's time to pray"
    case timeToPray        = "timeToPray"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .hadithQuotes:      return "book.closed.fill"
        case .meetingWithAllah:  return "calendar"
        case .hayyaAlasSalah:    return "hand.raised.fill"
        case .oneOnOneWithAllah: return "person.line.dotted.person.fill"
        case .timeToPray:        return "alarm.fill"
        }
    }

    /// Short, user-facing title used in the settings picker.
    func title(_ lang: AppLanguage) -> String {
        switch self {
        case .hadithQuotes:
            switch lang {
            case .english:                                return "Hadith quotes"
            case .turkish:                                return "Hadis alıntıları"
            default:                                      return "Hadith-Zitate"
            }
        case .meetingWithAllah:
            switch lang {
            case .english:                                return "Meeting with Allah"
            case .turkish:                                return "Allah ile randevu"
            default:                                      return "Termin mit Allah"
            }
        case .hayyaAlasSalah:
            switch lang {
            case .english:                                return "Come to Prayer"
            case .turkish:                                return "Haydi namaza"
            default:                                      return "Komm zum Gebet"
            }
        case .oneOnOneWithAllah:
            switch lang {
            case .english:                                return "1:1 with Allah"
            case .turkish:                                return "Allah ile bire bir"
            default:                                      return "1:1 mit Allah"
            }
        case .timeToPray:
            switch lang {
            case .english:                                return "It's time to pray"
            case .turkish:                                return "Namaz vakti"
            default:                                      return "Zeit zum Beten"
            }
        }
    }

    /// Returns the notification body text to use when the prayer begins.
    /// `kind` is only consulted for `.hadithQuotes`, which rotates per prayer.
    func body(for kind: PrayerKind, language: AppLanguage) -> String {
        switch self {
        case .hadithQuotes:
            // Preserve the original behaviour: per-prayer quote, with a
            // generic fallback for prayers that don't define one (Shuruuq).
            return L10n.notificationPrayerQuote(kind, language)
                ?? L10n.notificationAtPrayer(language)

        case .meetingWithAllah:
            switch language {
            case .english:                                return "Meeting with Allah due now!"
            case .turkish:                                return "Allah ile randevu vakti!"
            default:                                      return "Termin mit Allah – jetzt!"
            }
        case .hayyaAlasSalah:
            switch language {
            case .english:                                return "Come to Prayer, Come to Success!"
            case .turkish:                                return "Haydi namaza, haydi felaha!"
            default:                                      return "Komm zum Gebet, komm zum Erfolg!"
            }
        case .oneOnOneWithAllah:
            switch language {
            case .english:                                return "1:1 with Allah"
            case .turkish:                                return "Allah ile bire bir"
            default:                                      return "1:1 mit Allah"
            }
        case .timeToPray:
            switch language {
            case .english:                                return "It's time to pray"
            case .turkish:                                return "Namaz vakti"
            default:                                      return "Zeit zum Beten"
            }
        }
    }
}
