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
import os

private let logger = Logger(subsystem: "d.DailyDee", category: "QuranArabicFont")

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
        logger.error("HAFS font not found in bundle: none of \(hafsFontCandidates) could be resolved. Verify Copy Bundle Resources + UIAppFonts in Info.plist.")
        return .system(size: size)
    }

    // MARK: - UIKit Font

    /// Returns the first resolvable candidate as a `UIFont`.
    /// Falls back to Geeza Pro (system Arabic) then `.systemFont` if all candidates fail.
    static func getHafsUIFont(size: CGFloat) -> UIFont {
        for name in hafsFontCandidates {
            if let f = UIFont(name: name, size: size) { return f }
        }
        logger.error("HAFS font not found in bundle: none of \(hafsFontCandidates) could be resolved. Verify Copy Bundle Resources + UIAppFonts in Info.plist.")
        return UIFont(name: "Geeza Pro", size: size) ?? .systemFont(ofSize: size)
    }
}
