//
//  PrayerBasmalaPreview.swift
//  DeenApp
//
//  Gemeinsame Basmala-Beispieltexte für Gebet-Anzeige (Einstellungen + Tutorial).
//

import SwiftUI

enum PrayerBasmalaPreview {
    static let arabic = "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ"
    static let simplifiedLatin = "Bismillahirrahmanirrahim"
    static let dmgLatin = "Bi-smi llāhi r-raḥmāni r-raḥīmi"
    static let german = "Im Namen Allahs, des Allerbarmers, des Barmherzigen."
}

struct PrayerBasmalaPreviewSnippetView: View {
    enum Style {
        case arabic
        case simplifiedLatin
        case dmgLatin
        case german
    }

    let style: Style

    var body: some View {
        Group {
            switch style {
            case .arabic:
                Text(PrayerBasmalaPreview.arabic)
                    .font(QuranArabicFont.getHafsFont(size: 22))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .environment(\.layoutDirection, .rightToLeft)
            case .simplifiedLatin:
                Text(PrayerBasmalaPreview.simplifiedLatin)
                    .font(.system(size: 17))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            case .dmgLatin:
                Text(PrayerBasmalaPreview.dmgLatin)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            case .german:
                Text(PrayerBasmalaPreview.german)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .background(Theme.cardBackground.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
