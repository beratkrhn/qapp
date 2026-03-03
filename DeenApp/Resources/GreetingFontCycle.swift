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

enum GreetingFontCycle {

    /// Interval between font swaps in the greeting animation (seconds).
    static let interval: TimeInterval = 0.3

    // MARK: - Candidate Names (PostScript names preferred over family names)

    private static let candidateFontNames: [String] = [
        "Alkalami-Regular",
        "Almarai-Bold",
        "Amiri-Bold",
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
            print(
                "⚠️ GreetingFontCycle: None of the candidate fonts could be resolved. " +
                "Check that font files are in the Xcode target and listed in UIAppFonts."
            )
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

    /// Dumps all installed font families and the status of every candidate name.
    /// Call once from `.onAppear` to diagnose font registration issues.
    static func dumpAllFontNames() {
        print("═══════════════════════════════════════")
        print("   INSTALLED FONT FAMILIES (all)")
        print("═══════════════════════════════════════")
        UIFont.familyNames.sorted().forEach { family in
            print("  \(family): \(UIFont.fontNames(forFamilyName: family))")
        }
        print("═══════════════════════════════════════")
        print("  GreetingFontCycle — candidate status:")
        for name in candidateFontNames {
            let ok = UIFont(name: name, size: 12) != nil
            print("    \(ok ? "✅" : "❌") \(name)")
        }
        print("  Valid fonts in cycle: \(count)/\(candidateFontNames.count)")
        print("═══════════════════════════════════════")
    }

    // MARK: - Private

    private static func safeIndex(_ index: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((index % count) + count) % count
    }
}
