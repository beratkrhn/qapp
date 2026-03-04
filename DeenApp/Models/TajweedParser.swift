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

    // MARK: - Quranic Annotation Mark Filter

    /// Scalar ranges that produce visible artifacts (orange/gold circles, phantom glyphs)
    /// when the KFGQPC Hafs COLR font renders them inside a coloured attributed-string span.
    ///
    /// Stripped ranges:
    ///   U+0600–U+0605   Arabic number sign / footnote marker / poetic verse sign
    ///   U+0610–U+061A   Arabic Extended signs (small high marks)
    ///   U+06D6–U+06ED   Quranic Annotation Signs (Waqf marks, end-of-ayah ۝, rounded zero ۟, etc.)
    ///   U+08D3–U+08FF   Arabic Extended-A supplement (small high marks that render as circles)
    ///   U+FD3E–U+FD3F   Ornate Arabic parentheses
    ///   U+200B–U+200F   Zero-width / directional control characters
    ///   U+200C/200D     Zero-width non-joiner / joiner
    ///   U+FEFF          BOM / Zero Width No-Break Space
    private static let annotationMarkSet: CharacterSet = {
        var cs = CharacterSet()
        cs.insert(charactersIn: Unicode.Scalar(0x0600)!...Unicode.Scalar(0x0605)!)
        cs.insert(charactersIn: Unicode.Scalar(0x0610)!...Unicode.Scalar(0x061A)!)
        cs.insert(charactersIn: Unicode.Scalar(0x06D6)!...Unicode.Scalar(0x06ED)!)
        cs.insert(charactersIn: Unicode.Scalar(0x08D3)!...Unicode.Scalar(0x08FF)!)
        cs.insert(charactersIn: Unicode.Scalar(0xFD3E)!...Unicode.Scalar(0xFD3F)!)
        cs.insert(charactersIn: Unicode.Scalar(0x200B)!...Unicode.Scalar(0x200F)!)
        cs.insert(Unicode.Scalar(0x200C)!)
        cs.insert(Unicode.Scalar(0x200D)!)
        cs.insert(Unicode.Scalar(0xFEFF)!)
        return cs
    }()

    /// Strips Quranic annotation marks from a string that is about to receive a tajweed colour.
    private static func sanitize(_ text: String) -> String {
        String(text.unicodeScalars.filter { !annotationMarkSet.contains($0) })
    }

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

            let letter = ns.substring(with: match.range(at: 1))
            let inner  = sanitize(ns.substring(with: match.range(at: 2)))
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

            let letter  = ns.substring(with: match.range(at: 1))
            let content = sanitize(ns.substring(with: match.range(at: 2)))
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
