//
//  QuranTranslation.swift
//  DeenApp
//

import Foundation

enum QuranTranslationOption: String, CaseIterable, Identifiable {
    case none = "none"
    case german = "de"
    case english = "en"

    var id: String { rawValue }
}
