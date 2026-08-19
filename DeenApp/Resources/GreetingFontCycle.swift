//
//  GreetingFontCycle.swift
//  DeenApp
//
//  Cycles through registered Arabic fonts for the greeting animation in the header.
//
//  Font files (.ttf / .otf) must be in Resources/fonts/ and listed under
//  UIAppFonts in Info.plist.  Any name that UIKit cannot resolve at launch is
//  silently dropped from the cycle — preventing console spam and animation glitches.
//

import SwiftUI
import UIKit
import os

private let logger = Logger(subsystem: "d.DailyDee", category: "GreetingFontCycle")

enum GreetingFontCycle {

    /// Interval between font swaps in the greeting animation (seconds).
    static let interval: TimeInterval = 0.15

    // MARK: - Candidate Names (PostScript names preferred over family names)

    private static let candidateFontNames: [String] = [
        "Alkalami-Regular",
        "Almarai-Regular",
        "Amiri-Regular",
        "KFGQPCUthmanicScriptHAFS",   // PostScript name — more reliable than the file/family name
        "Handjet-Regular",
        "Kufam-Regular",
        "Mirza-Regular",
        "Parastoo-Regular",
        "ReemKufi-Regular",
        "Ruwudu-Regular",
    ]

    /// Fallback used when zero custom fonts resolve successfully.
    private static let systemFallback = "Geeza Pro"

    // MARK: - Valid Font List (built once at startup)

    /// Only the font names that UIKit can actually initialise — built lazily once.
    /// Invalid entries are filtered out silently; if the array would be empty the
    /// system Arabic font is used as the sole entry so the animation always runs.
    static let validFontNames: [String] = {
        let verified = candidateFontNames.filter { UIFont(name: $0, size: 10) != nil }
        if verified.isEmpty {
            logger.warning("None of the candidate fonts could be resolved. Check that font files are in the Xcode target and listed in UIAppFonts.")
            return [systemFallback]
        }
        return verified
    }()

    // MARK: - Public API

    /// Number of valid (resolvable) fonts in the cycle.
    static var count: Int { validFontNames.count }

    /// SwiftUI Font for the given cycle index.
    /// The index is automatically wrapped so out-of-range values are always safe.
    static func font(at index: Int, size: CGFloat = 34) -> Font {
        .custom(validFontNames[safeIndex(index)], size: size)
    }

    /// PostScript name at the given cycle index — use for `.id()` modifier bindings.
    static func fontName(at index: Int) -> String {
        validFontNames[safeIndex(index)]
    }

    // MARK: - Debug

    /// Loggt alle installierten Font-Familien und den Status jedes Kandidaten.
    /// Bei Bedarf manuell aufrufen, um Font-Registrierungsprobleme zu debuggen.
    static func dumpAllFontNames() {
        let families = UIFont.familyNames.sorted()
            .map { "\($0): \(UIFont.fontNames(forFamilyName: $0))" }
            .joined(separator: "\n")
        logger.debug("Installed font families:\n\(families)")
        for name in candidateFontNames {
            let ok = UIFont(name: name, size: 12) != nil
            logger.debug("\(ok ? "OK" : "MISSING") \(name)")
        }
        logger.debug("Valid fonts in cycle: \(count)/\(candidateFontNames.count)")
    }

    // MARK: - Private

    private static func safeIndex(_ index: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((index % count) + count) % count
    }
}
