//
//  TajweedParser.swift
//  DeenApp
//
//  Parses the bracket-format tajweed markup returned by the `quran-tajweed`
//  edition on api.alquran.cloud.
//
//  The API does NOT return HTML tags. It uses a custom bracket format:
//
//    [x[arabic text]           e.g.  [l[ل]
//    [x:123[arabic text]       e.g.  [f:99[ن ك]
//
//  Regex:   \[([a-z])(?::\d+)?\[(.*?)\]
//    Group 1 — single rule letter  (h, l, f, q, m, g, a, c, w, o, p, n, s …)
//    Group 2 — Arabic text to colour
//

import SwiftUI

struct TajweedParser {

    // MARK: - Regex

    private static let bracketPattern = #"\[([a-z])(?::\d+)?\[(.*?)\]"#

    // MARK: - Color Mapping — by rule letter

    private static func color(forLetter letter: String) -> Color {
        switch letter {
        case "a", "w", "n", "g": return Theme.tajweedIdghamGhunna   // İdgham Meal/Bila Günne + Ghunna
        case "i":                 return Theme.tajweedIdghamMutmath  // İdgham Mütecaniseyn etc.
        case "f":                 return Theme.tajweedIkhfa          // İhfa Hakiki
        case "m":                 return Theme.tajweedIkhfaShafawi   // Dudak İhfası (Mim + Ba)
        case "q":                 return Theme.tajweedQalqala        // Kalkale
        case "c":                 return Theme.tajweedIqlab          // İklab
        case "o":                 return Theme.tajweedIzhar          // İzhar
        case "p", "b":            return Theme.tajweedMaddLin        // Medd-i Lin
        case "h", "l", "s":      return Theme.tajweedSilent         // Sessiz / Hamza Vasl / Lam
        case "k", "t":            return Theme.tajweedMaddQasr       // Medd-i Muttasıl / Munfasıl
        case "u":                 return Theme.tajweedMaddLazim      // Medd-i Lazım
        case "j", "r", "v", "x": return Theme.tajweedMaddAriz       // Medd-i Arız / Tabii / Sıla / Zamir
        default:                  return Theme.tajweedDefault
        }
    }

    // MARK: - Strict Unicode Whitelist

    /// Whitelist of every scalar that is safe to display with the KFGQPC Hafs COLR font.
    /// Anything outside this set is silently dropped.
    ///
    /// Permitted scalars:
    ///   U+0020          Space
    ///   U+0621–U+063A   Core Arabic letters  (ء … غ)
    ///   U+0640          Arabic tatweel  (ـ)
    ///   U+0641–U+064A   More Arabic letters  (ف … ي)
    ///   U+064B–U+0656   Standard tashkeel / harakat  (tanwin, fatha, damma, kasra, shadda, sukun,
    ///                   maddah, hamza above/below, subscript alef)
    ///   U+0670          Dagger alif / superscript alef  (ٰ) — critical for Quran
    ///   U+0671          Alef wasla  (ٱ) — critical for Uthmanic Hafs
    ///   U+06E1–U+06E8   Uthmanic rendering marks (small high dotless, meem, seen, madda, waw,
    ///                   yeh, high yeh, high noon) — required by KFGQPC font for correct shaping
    ///   U+06EA–U+06ED   Uthmanic stop marks (empty centre stops, rounded stop, small low meem)
    ///                   — also required by KFGQPC font
    ///
    /// Explicitly excluded: waqf/pause marks (U+06D6–U+06E0), sajda circle (U+06E9),
    /// Arabic Extended-A (U+08D3–U+08FF), zero-width joiners, BOM, format controls, etc.
    private static let allowedScalarSet: CharacterSet = {
        var cs = CharacterSet()
        cs.insert(Unicode.Scalar(0x0020)!)                                            // space
        cs.insert(charactersIn: Unicode.Scalar(0x0621)!...Unicode.Scalar(0x063A)!)   // ء–غ
        cs.insert(Unicode.Scalar(0x0640)!)                                            // tatweel ـ
        cs.insert(charactersIn: Unicode.Scalar(0x0641)!...Unicode.Scalar(0x064A)!)   // ف–ي
        cs.insert(charactersIn: Unicode.Scalar(0x064B)!...Unicode.Scalar(0x0656)!)   // harakat + maddah/hamza/subscript
        cs.insert(Unicode.Scalar(0x0670)!)                                            // dagger alif ٰ
        cs.insert(Unicode.Scalar(0x0671)!)                                            // alef wasla ٱ
        // Uthmanic rendering marks — needed by KFGQPC Hafs font for correct glyph shaping
        cs.insert(charactersIn: Unicode.Scalar(0x06E1)!...Unicode.Scalar(0x06E8)!)   // ۡ–ۨ
        cs.insert(charactersIn: Unicode.Scalar(0x06EA)!...Unicode.Scalar(0x06ED)!)   // ۪–ۭ
        return cs
    }()

    /// Strict whitelist filter: retains only scalars in `allowedScalarSet`.
    /// Drops waqf/decoration marks (U+06D6–U+06E0, U+06E9) while preserving
    /// standard harakat and the Uthmanic marks that KFGQPC Hafs requires.
    static func sanitizePlain(_ text: String) -> String {
        String(text.unicodeScalars.filter { allowedScalarSet.contains($0) })
    }

    private static func sanitize(_ text: String) -> String { sanitizePlain(text) }

    // MARK: - Debug Scalar Logger

#if DEBUG
    /// Set to `true` to re-enable per-segment scalar logging for debugging.
    static var logEnabled = false

    private static func debugLogScalars(_ text: String, rule: String) {
        guard logEnabled else { return }
        let hexList = text.unicodeScalars
            .map { String(format: "U+%04X", $0.value) }
            .joined(separator: " ")
        print("[TajweedParser] rule '\(rule)' scalars: \(hexList)  text: \"\(text)\"")
    }
#endif

    // MARK: - Tag Stripper

    /// Removes all bracket-format tajweed markers from `text`,
    /// leaving only the bare Arabic inner text nodes, then sanitizes artifacts.
    static func stripAllTags(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: bracketPattern) else { return sanitize(text) }
        let ns = text as NSString
        var result = ""
        var cursor = 0
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        for match in matches {
            if match.range.location > cursor {
                result += ns.substring(with: NSRange(location: cursor,
                                                     length: match.range.location - cursor))
            }
            result += ns.substring(with: match.range(at: 2))
            cursor = match.range.location + match.range.length
        }
        if cursor < ns.length { result += ns.substring(from: cursor) }
        return sanitize(result)
    }

    // MARK: - Main Entry Point (SwiftUI AttributedString)

    /// Parses a bracket-format tajweed string into a coloured, font-attributed SwiftUI
    /// `AttributedString`.
    ///
    /// - Parameters:
    ///   - text:     Raw string from the `quran-tajweed` API edition.
    ///   - fontSize: Point size applied to every character.
    ///   - enabled:  When `false` the text is returned plain (brackets stripped, default colour).
    static func parse(_ text: String, fontSize: CGFloat, enabled: Bool, defaultColor: Color = Theme.tajweedDefault) -> AttributedString {
        let hafsFont = QuranArabicFont.getHafsFont(size: fontSize)

        guard enabled else {
            var attr = AttributedString(stripAllTags(text))
            attr.font = hafsFont
            attr.foregroundColor = defaultColor
            return attr
        }

        guard let regex = try? NSRegularExpression(pattern: bracketPattern) else {
            return plainFallback(text, font: hafsFont, defaultColor: defaultColor)
        }

        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))

        guard !matches.isEmpty else {
            var plain = AttributedString(text)
            plain.font = hafsFont
            plain.foregroundColor = defaultColor
            return plain
        }

        var result = AttributedString()
        var cursor = 0

        for match in matches {
            if match.range.location > cursor {
                let rawSegment = sanitize(ns.substring(with: NSRange(location: cursor,
                                                                     length: match.range.location - cursor)))
                var seg = AttributedString(rawSegment)
                seg.font = hafsFont
                seg.foregroundColor = defaultColor
                result.append(seg)
            }

            let letter  = ns.substring(with: match.range(at: 1))
            let rawInner = ns.substring(with: match.range(at: 2))
#if DEBUG
            if ["m", "n", "o", "p"].contains(letter) { debugLogScalars(rawInner, rule: letter) }
#endif
            let inner  = sanitize(rawInner)
            var seg = AttributedString(inner)
            seg.font = hafsFont
            seg.foregroundColor = color(forLetter: letter)
            result.append(seg)

            cursor = match.range.location + match.range.length
        }

        if cursor < ns.length {
            var seg = AttributedString(sanitize(ns.substring(from: cursor)))
            seg.font = hafsFont
            seg.foregroundColor = defaultColor
            result.append(seg)
        }

        return result.characters.isEmpty ? plainFallback(text, font: hafsFont, defaultColor: defaultColor) : result
    }

    // MARK: - Plain-text Fallback

    private static func plainFallback(_ text: String, font: Font, defaultColor: Color = Theme.tajweedDefault) -> AttributedString {
        var attr = AttributedString(stripAllTags(text))
        attr.font = font
        attr.foregroundColor = defaultColor
        return attr
    }

    // MARK: - UIKit Output (NSAttributedString for JustifiedArabicText / UITextView)

    /// Parses a bracket-format tajweed string into an `NSAttributedString`.
    /// Used by the `JustifiedArabicText` `UIViewRepresentable` inside `QuranView`.
    ///
    /// - Parameters:
    ///   - text:           Raw tagged string from the API.
    ///   - bodyFont:       `UIFont` applied to all characters.
    ///   - paragraphStyle: Shared `NSParagraphStyle` (alignment, direction, line-spacing).
    static func nsAttributedString(
        from text: String,
        bodyFont: UIFont,
        paragraphStyle: NSParagraphStyle,
        defaultTextColor: UIColor = .white
    ) -> NSAttributedString {
        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .font:           bodyFont,
            .foregroundColor: defaultTextColor,
            .paragraphStyle: paragraphStyle,
        ]

        guard let regex = try? NSRegularExpression(pattern: bracketPattern) else {
            return NSAttributedString(string: stripAllTags(text), attributes: defaultAttrs)
        }

        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))

        guard !matches.isEmpty else {
            return NSAttributedString(string: text, attributes: defaultAttrs)
        }

        let result = NSMutableAttributedString()
        var cursor = 0

        for match in matches {
            if match.range.location > cursor {
                // Sanitize plain runs: the KFGQPC Hafs COLR font overrides foreground
                // colour for annotation marks, so strip them from every segment.
                let before = sanitize(ns.substring(with: NSRange(location: cursor,
                                                                  length: match.range.location - cursor)))
                result.append(NSAttributedString(string: before, attributes: defaultAttrs))
            }

            let letter     = ns.substring(with: match.range(at: 1))
            let rawContent = ns.substring(with: match.range(at: 2))
#if DEBUG
            if ["m", "n", "o", "p"].contains(letter) { debugLogScalars(rawContent, rule: letter) }
#endif
            let content = sanitize(rawContent)
            var attrs   = defaultAttrs
            attrs[.foregroundColor] = uiColor(forLetter: letter)
            result.append(NSAttributedString(string: content, attributes: attrs))

            cursor = match.range.location + match.range.length
        }

        if cursor < ns.length {
            result.append(NSAttributedString(string: sanitize(ns.substring(from: cursor)),
                                             attributes: defaultAttrs))
        }

        return result.length > 0
            ? result
            : NSAttributedString(string: stripAllTags(text), attributes: defaultAttrs)
    }

    // MARK: - UIColor Mapping (mirrors Theme tajweed colors)

    private static func uiColor(forLetter letter: String) -> UIColor {
        switch letter {
        case "a", "w", "n", "g":
            return UIColor(red: 0xC8/255, green: 0x47/255, blue: 0x82/255, alpha: 1) // deep pink  – İdgham Meal/Bila Günne + Ghunna
        case "i":
            return UIColor(red: 0x83/255, green: 0x61/255, blue: 0x55/255, alpha: 1) // brown      – İdgham Mütecaniseyn etc.
        case "f":
            return UIColor(red: 0x6B/255, green: 0xA6/255, blue: 0x6E/255, alpha: 1) // green      – İhfa Hakiki
        case "m":
            return UIColor(red: 0xAF/255, green: 0xBC/255, blue: 0x5D/255, alpha: 1) // yellow-green – Dudak İhfası
        case "q":
            return UIColor(red: 0xA7/255, green: 0x8C/255, blue: 0x5F/255, alpha: 1) // tan        – Kalkale
        case "c":
            return UIColor(red: 0x46/255, green: 0x75/255, blue: 0xB2/255, alpha: 1) // steel blue – İklab
        case "j", "r", "v", "x":
            return UIColor(red: 0x01/255, green: 0x84/255, blue: 0xD7/255, alpha: 1) // bright blue – Medd Arız/Tabii/Sıla/Zamir
        case "o":
            return UIColor(red: 0x32/255, green: 0x6E/255, blue: 0x5A/255, alpha: 1) // deep teal  – İzhar
        case "p", "b":
            return UIColor(red: 0xB5/255, green: 0x86/255, blue: 0x40/255, alpha: 1) // warm gold  – Medd-i Lin
        case "h", "l", "s":
            return UIColor(red: 0x90/255, green: 0xA4/255, blue: 0xAE/255, alpha: 1) // gray       – Sessiz / Hamza Vasl / Lam
        case "k", "t":
            return UIColor(red: 0xBE/255, green: 0x4B/255, blue: 0x58/255, alpha: 1) // rose       – Medd-i Muttasıl / Munfasıl
        case "u":
            return UIColor(red: 0x9B/255, green: 0x4C/255, blue: 0x3A/255, alpha: 1) // dark red   – Medd-i Lazım
        default:
            return .white
        }
    }
}
