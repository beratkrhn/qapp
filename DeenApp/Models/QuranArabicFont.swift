//
//  QuranArabicFont.swift
//  DeenApp
//
//  Arabische Schriftarten für die Quran-Ansicht.
//
//  The OTF file "KFGQPC Uthmanic Script HAFS Regular.otf" must be:
//    • added to the Xcode target (Copy Bundle Resources phase), and
//    • listed under UIAppFonts in Info.plist.
//
//  iOS may register it under any of several internal names depending on the
//  font's embedded metadata.  `getHafsFont` and `getHafsUIFont` try each
//  known candidate and emit a loud console error if none resolves.
//

import SwiftUI
import UIKit

enum QuranArabicFont: String, CaseIterable, Identifiable {
    /// KFGQPC Uthmanic Script HAFS Regular.otf
    case uthmanicHafs = "KFGQPCUthmanicScriptHAFS"

    var id: String { rawValue }
    var displayName: String { "Uthmanic Hafs (KFGQPC)" }

    /// Returns the best available SwiftUI Font for this face at `size`.
    func font(size: CGFloat) -> Font {
        Self.getHafsFont(size: size)
    }

    // MARK: - Known PostScript-name candidates

    /// Ordered list of names iOS might register the KFGQPC OTF under.
    /// UIFont(name:size:) is tried for each; the first that succeeds is used.
    static let hafsFontCandidates: [String] = [
        "KFGQPCUthmanicScriptHAFS",                  // compact PostScript name
        "KFGQPC Uthmanic Script HAFS Regular",        // full-name / family+style
        "KFGQPC-Uthmanic-Script-HAFS",               // hyphenated PostScript variant
    ]

    // MARK: - SwiftUI Font

    /// Returns the first resolvable candidate as a SwiftUI `Font`.
    /// Prints a loud console error and falls back to `.system` if all candidates fail.
    static func getHafsFont(size: CGFloat) -> Font {
        for name in hafsFontCandidates {
            if UIFont(name: name, size: size) != nil {
                return .custom(name, size: size)
            }
        }
        print(
            "⛔️ [HAFS FONT NOT FOUND IN BUNDLE] " +
            "None of \(hafsFontCandidates) could be resolved by UIKit. " +
            "Verify that 'KFGQPC Uthmanic Script HAFS Regular.otf' is present in the " +
            "Xcode target's Copy Bundle Resources phase and listed under " +
            "UIAppFonts in Info.plist."
        )
        return .system(size: size)
    }

    // MARK: - UIKit Font

    /// Returns the first resolvable candidate as a `UIFont`.
    /// Falls back to Geeza Pro (system Arabic) then `.systemFont` if all candidates fail.
    static func getHafsUIFont(size: CGFloat) -> UIFont {
        for name in hafsFontCandidates {
            if let f = UIFont(name: name, size: size) { return f }
        }
        print(
            "⛔️ [HAFS FONT NOT FOUND IN BUNDLE] " +
            "None of \(hafsFontCandidates) could be resolved by UIKit. " +
            "Verify that 'KFGQPC Uthmanic Script HAFS Regular.otf' is present in the " +
            "Xcode target's Copy Bundle Resources phase and listed under " +
            "UIAppFonts in Info.plist."
        )
        return UIFont(name: "Geeza Pro", size: size) ?? .systemFont(ofSize: size)
    }
}
