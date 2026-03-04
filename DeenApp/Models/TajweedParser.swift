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
        case "n", "o", "p", "m": return Theme.tajweedMadd      // Madd (prolongation)
        case "f":                 return Theme.tajweedIkhfa     // Ikhfa (concealment)
        case "g":                 return Theme.tajweedGhunna    // Ghunna (nasalisation)
        case "a", "w", "i":      return Theme.tajweedIdgham    // Idgham (merging)
        case "q":                 return Theme.tajweedQalqala   // Qalqala (bouncing)
        case "c":                 return Theme.tajweedIkhfa     // Iqlab — mapped to Ikhfa color
        case "h", "l", "s":      return Theme.tajweedLam       // Hamza Wasl / Lam / Silent
        default:                  return Theme.tajweedDefault
        }
    }

    // MARK: - Strict Unicode Whitelist

    /// Whitelist of every scalar that is safe to display with the KFGQPC Hafs COLR font.
    /// Anything outside this set is silently dropped — this is intentionally aggressive.
    ///
    /// Permitted scalars:
    ///   U+0020          Space
    ///   U+0621–U+063A   Core Arabic letters  (ء … غ)
    ///   U+0640          Arabic tatweel  (ـ)
    ///   U+0641–U+064A   More Arabic letters  (ف … ي)
    ///   U+064B–U+0652   Standard tashkeel / harakat  (tanwin, fatha, damma, kasra, shadda, sukun)
    ///   U+0653          Maddah above  (ٓ)
    ///   U+0654          Hamza above  (ٔ)
    ///   U+0655          Hamza below  (ٕ)
    ///   U+0656          Subscript alef  (ٖ)
    ///   U+0670          Dagger alif / superscript alef  (ٰ) — critical for Quran
    ///   U+0671          Alef wasla  (ٱ) — critical for Uthmanic Hafs
    ///
    /// Everything else — annotation signs (U+06D6–U+06ED), Arabic Extended-A (U+08D3–U+08FF),
    /// zero-width joiners, BOM, format controls, etc. — is excluded and will not render.
    private static let allowedScalarSet: CharacterSet = {
        var cs = CharacterSet()
        cs.insert(Unicode.Scalar(0x0020)!)                                            // space
        cs.insert(charactersIn: Unicode.Scalar(0x0621)!...Unicode.Scalar(0x063A)!)   // ء–غ
        cs.insert(Unicode.Scalar(0x0640)!)                                            // tatweel ـ
        cs.insert(charactersIn: Unicode.Scalar(0x0641)!...Unicode.Scalar(0x064A)!)   // ف–ي
        cs.insert(charactersIn: Unicode.Scalar(0x064B)!...Unicode.Scalar(0x0652)!)   // harakat
        cs.insert(Unicode.Scalar(0x0653)!)                                            // maddah ٓ
        cs.insert(Unicode.Scalar(0x0654)!)                                            // hamza above ٔ
        cs.insert(Unicode.Scalar(0x0655)!)                                            // hamza below ٕ
        cs.insert(Unicode.Scalar(0x0656)!)                                            // subscript alef ٖ
        cs.insert(Unicode.Scalar(0x0670)!)                                            // dagger alif ٰ
        cs.insert(Unicode.Scalar(0x0671)!)                                            // alef wasla ٱ
        return cs
    }()

    /// Strict whitelist filter: retains only scalars in `allowedScalarSet`.
    /// Replaces the old blacklist approach — any scalar not explicitly permitted is dropped.
    private static func sanitize(_ text: String) -> String {
        String(text.unicodeScalars.filter { allowedScalarSet.contains($0) })
    }

    // MARK: - Debug Scalar Logger

#if DEBUG
    /// Logs every Unicode scalar value inside a tajweed segment so you can identify
    /// exactly which hidden codepoints the API is embedding (run once, then remove).
    ///
    /// Example output:
    ///   [TajweedParser] rule 'm' content: U+0645 U+0640 U+06DF  "مـ۟"
    private static func debugLogScalars(_ text: String, rule: String) {
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
    static func parse(_ text: String, fontSize: CGFloat, enabled: Bool) -> AttributedString {
        let hafsFont = QuranArabicFont.getHafsFont(size: fontSize)

        guard enabled else {
            var attr = AttributedString(stripAllTags(text))
            attr.font = hafsFont
            attr.foregroundColor = Theme.tajweedDefault
            return attr
        }

        guard let regex = try? NSRegularExpression(pattern: bracketPattern) else {
            return plainFallback(text, font: hafsFont)
        }

        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))

        guard !matches.isEmpty else {
            var plain = AttributedString(text)
            plain.font = hafsFont
            plain.foregroundColor = Theme.tajweedDefault
            return plain
        }

        var result = AttributedString()
        var cursor = 0

        for match in matches {
            if match.range.location > cursor {
                // Sanitize plain runs too: the KFGQPC Hafs COLR font renders annotation
                // marks (U+06D6–U+06ED) with built-in orange glyphs that override any
                // foreground colour we set — strip them here before building the segment.
                let rawSegment = sanitize(ns.substring(with: NSRange(location: cursor,
                                                                     length: match.range.location - cursor)))
                var seg = AttributedString(rawSegment)
                seg.font = hafsFont
                seg.foregroundColor = Theme.tajweedDefault
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
            seg.foregroundColor = Theme.tajweedDefault
            result.append(seg)
        }

        return result.characters.isEmpty ? plainFallback(text, font: hafsFont) : result
    }

    // MARK: - Plain-text Fallback

    private static func plainFallback(_ text: String, font: Font) -> AttributedString {
        var attr = AttributedString(stripAllTags(text))
        attr.font = font
        attr.foregroundColor = Theme.tajweedDefault
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
        paragraphStyle: NSParagraphStyle
    ) -> NSAttributedString {
        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .font:           bodyFont,
            .foregroundColor: UIColor.white,
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
        case "n", "o", "p", "m":
            return UIColor(red: 0xFF/255, green: 0x98/255, blue: 0x00/255, alpha: 1) // orange – Madd
        case "f":
            return UIColor(red: 0x42/255, green: 0xA5/255, blue: 0xF5/255, alpha: 1) // blue   – Ikhfa
        case "g":
            return UIColor(red: 0x4C/255, green: 0xAF/255, blue: 0x50/255, alpha: 1) // green  – Ghunna
        case "a", "w", "i":
            return UIColor(red: 0xB0/255, green: 0xBE/255, blue: 0xC5/255, alpha: 1) // gray   – Idgham
        case "q":
            return UIColor(red: 0xEF/255, green: 0x53/255, blue: 0x50/255, alpha: 1) // red    – Qalqala
        case "c":
            return UIColor(red: 0x42/255, green: 0xA5/255, blue: 0xF5/255, alpha: 1) // blue   – Iqlab (≈ Ikhfa)
        case "h", "l", "s":
            return UIColor(red: 0xAB/255, green: 0x47/255, blue: 0xBC/255, alpha: 1) // purple – Lam / Hamza Wasl / Silent
        default:
            return .white
        }
    }
}
