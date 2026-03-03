//
//  TajweedParser.swift
//  DeenApp
//
//  Dedicated Tajweed HTML parser.
//  The `quran-tajweed` edition on api.alquran.cloud returns Arabic text
//  wrapped in HTML-like markup.  Three tag formats are supported, tried in order:
//
//    1. <tajweed class="rule_name">text</tajweed>   — KFGQPC quran-tajweed edition
//    2. <ghunna>text</ghunna>, <qalqala>…</qalqala> — named semantic tags
//    3. <font color="#rrggbb">text</font>            — inline colour tags
//
//  All tags are stripped from the final output; only the foreground colour
//  and the Uthmanic Hafs font are embedded in the returned AttributedString.
//

import SwiftUI

struct TajweedParser {

    // MARK: - Color Mapping — by CSS class name

    private static func color(forClass className: String) -> Color {
        switch className.trimmingCharacters(in: .whitespaces) {
        case "ham_wasl", "lpieces-shf", "slnt":
            return Theme.tajweedLam
        case "madda_normal", "madda_permissible",
             "madda_necessary", "madda_obligatory":
            return Theme.tajweedMadd
        case "ikhf_shf", "ikhf", "ikhfa":
            return Theme.tajweedIkhfa
        case "ghunnah", "ghn", "ghunna":
            return Theme.tajweedGhunna
        case "idgham_shf", "idgh_ghn", "idgh_w_ghn",
             "idgh_wo_ghn", "idgham":
            return Theme.tajweedIdgham
        case "qlq", "qalqpieces-shala", "qalqala":
            return Theme.tajweedQalqala
        default:
            return Theme.tajweedDefault
        }
    }

    // MARK: - Color Mapping — by tag name

    private static func color(forTag tagName: String) -> Color {
        switch tagName.lowercased().trimmingCharacters(in: .whitespaces) {
        case "ghunna", "ghn", "ghunnah":   return Theme.tajweedGhunna
        case "qalqala", "qlq":             return Theme.tajweedQalqala
        case "madd", "madda":              return Theme.tajweedMadd
        case "ikhfa", "ikhf":             return Theme.tajweedIkhfa
        case "idgham":                     return Theme.tajweedIdgham
        case "lam", "ham_wasl", "wasl":    return Theme.tajweedLam
        default:                           return Theme.tajweedDefault
        }
    }

    // MARK: - Color Mapping — by hex string

    private static func color(forHex hex: String) -> Color {
        let stripped = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard stripped.count == 6 || stripped.count == 3 else {
            return Theme.tajweedDefault
        }
        return Color(hex: stripped)
    }

    // MARK: - Tag Stripper

    /// Removes all HTML-like tags from `text`, leaving only the inner text nodes.
    static func stripAllTags(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    // MARK: - Main Entry Point

    /// Parses a tagged HTML string into a coloured, font-attributed SwiftUI AttributedString.
    ///
    /// - Parameters:
    ///   - html:      Raw HTML string from the `quran-tajweed` API edition.
    ///   - fontSize:  Point size to apply to every character.
    ///   - enabled:   When `false` the text is returned plain (tags stripped, default colour).
    static func parse(_ html: String, fontSize: CGFloat, enabled: Bool) -> AttributedString {
        let hafsFont = QuranArabicFont.getHafsFont(size: fontSize)

        guard enabled else {
            var attr = AttributedString(stripAllTags(html))
            attr.font = hafsFont
            attr.foregroundColor = Theme.tajweedDefault
            return attr
        }

        // Priority 1 — <tajweed class="…">…</tajweed>
        if html.contains("<tajweed") {
            return parseClassTags(html, font: hafsFont)
        }

        // Priority 2 — named semantic tags: <ghunna>…</ghunna>, <qalqala>…</qalqala>, etc.
        let semanticTags = ["ghunna", "ghn", "ghunnah", "qalqala", "qlq",
                            "madd", "madda", "ikhfa", "ikhf", "idgham", "lam", "wasl"]
        if semanticTags.contains(where: { html.contains("<\($0)") }) {
            return parseSemanticTags(html, font: hafsFont, tagNames: semanticTags)
        }

        // Priority 3 — <font color="…">…</font>
        if html.contains("<font") {
            return parseFontColorTags(html, font: hafsFont)
        }

        // No markup — strip any residual tags and return plain coloured text.
        var plain = AttributedString(stripAllTags(html))
        plain.font = hafsFont
        plain.foregroundColor = Theme.tajweedDefault
        return plain
    }

    // MARK: - Format 1: <tajweed class="rule_name">…</tajweed>

    private static func parseClassTags(_ html: String, font: Font) -> AttributedString {
        guard let regex = try? NSRegularExpression(
            pattern: #"<tajweed\s+class="([^"]*)">(.*?)</tajweed>"#,
            options: .dotMatchesLineSeparators
        ) else {
            return plainFallback(html, font: font)
        }
        return buildAttributedString(
            from: html as NSString,
            matches: regex.matches(in: html, range: NSRange(location: 0, length: html.utf16.count)),
            colorForGroup1: { color(forClass: $0) },
            defaultFont: font
        )
    }

    // MARK: - Format 2: <ghunna>…</ghunna> (named semantic tags)

    private static func parseSemanticTags(
        _ html: String,
        font: Font,
        tagNames: [String]
    ) -> AttributedString {
        let alternation = tagNames.joined(separator: "|")
        let pattern = "<(\(alternation))(?:\\s[^>]*)?>([\\s\\S]*?)</\\1>"

        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.dotMatchesLineSeparators, .caseInsensitive]
        ) else {
            return plainFallback(html, font: font)
        }
        return buildAttributedString(
            from: html as NSString,
            matches: regex.matches(in: html, range: NSRange(location: 0, length: html.utf16.count)),
            colorForGroup1: { color(forTag: $0) },
            defaultFont: font
        )
    }

    // MARK: - Format 3: <font color="#rrggbb">…</font>

    private static func parseFontColorTags(_ html: String, font: Font) -> AttributedString {
        guard let regex = try? NSRegularExpression(
            pattern: #"<font\s+color="([^"]*)">(.*?)</font>"#,
            options: .dotMatchesLineSeparators
        ) else {
            return plainFallback(html, font: font)
        }
        return buildAttributedString(
            from: html as NSString,
            matches: regex.matches(in: html, range: NSRange(location: 0, length: html.utf16.count)),
            colorForGroup1: { color(forHex: $0) },
            defaultFont: font
        )
    }

    // MARK: - Shared Attributed-String Builder

    private static func buildAttributedString(
        from input: NSString,
        matches: [NSTextCheckingResult],
        colorForGroup1: (String) -> Color,
        defaultFont: Font
    ) -> AttributedString {
        var result = AttributedString()
        var cursor = 0

        for match in matches {
            // Text before this match
            let matchStart = match.range.location
            if matchStart > cursor {
                let range = NSRange(location: cursor, length: matchStart - cursor)
                var seg = AttributedString(stripAllTags(input.substring(with: range)))
                seg.font = defaultFont
                seg.foregroundColor = Theme.tajweedDefault
                result.append(seg)
            }

            // Tagged segment
            let group1Text = input.substring(with: match.range(at: 1))
            let innerText  = input.substring(with: match.range(at: 2))
            var seg = AttributedString(stripAllTags(innerText))
            seg.font = defaultFont
            seg.foregroundColor = colorForGroup1(group1Text)
            result.append(seg)

            cursor = match.range.location + match.range.length
        }

        // Trailing text after the last match
        if cursor < input.length {
            var seg = AttributedString(stripAllTags(input.substring(from: cursor)))
            seg.font = defaultFont
            seg.foregroundColor = Theme.tajweedDefault
            result.append(seg)
        }

        // If the builder produced nothing meaningful, fall back to plain text
        return result.characters.isEmpty ? plainFallback(input as String, font: defaultFont) : result
    }

    // MARK: - Plain-text Fallback

    private static func plainFallback(_ html: String, font: Font) -> AttributedString {
        var attr = AttributedString(stripAllTags(html))
        attr.font = font
        attr.foregroundColor = Theme.tajweedDefault
        return attr
    }

    // MARK: - UIKit Output (NSAttributedString for JustifiedArabicText / UITextView)

    /// Parses a single tajweed-tagged HTML string into an `NSAttributedString`.
    /// Handles `<tajweed class="…">…</tajweed>` only (the format returned by
    /// the `quran-tajweed` API edition).  Any other markup is stripped.
    ///
    /// - Parameters:
    ///   - html:             Raw tagged HTML from the API.
    ///   - bodyFont:         `UIFont` to apply to all characters.
    ///   - paragraphStyle:   `NSParagraphStyle` (alignment, direction, line-spacing)
    ///                       shared across the full page attributed string.
    static func nsAttributedString(
        from html: String,
        bodyFont: UIFont,
        paragraphStyle: NSParagraphStyle
    ) -> NSAttributedString {
        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle,
        ]

        guard html.contains("<tajweed"),
              let regex = try? NSRegularExpression(
                pattern: #"<tajweed\s+class="([^"]*)">(.*?)</tajweed>"#,
                options: .dotMatchesLineSeparators
              )
        else {
            return NSAttributedString(string: stripAllTags(html), attributes: defaultAttrs)
        }

        let input   = html as NSString
        let result  = NSMutableAttributedString()
        var cursor  = 0
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: input.length))

        for match in matches {
            let matchStart = match.range.location
            if matchStart > cursor {
                let before = input.substring(with: NSRange(location: cursor, length: matchStart - cursor))
                result.append(NSAttributedString(string: stripAllTags(before), attributes: defaultAttrs))
            }

            let className = input.substring(with: match.range(at: 1))
            let content   = input.substring(with: match.range(at: 2))
            var attrs     = defaultAttrs
            attrs[.foregroundColor] = uiColor(forClass: className)
            result.append(NSAttributedString(string: stripAllTags(content), attributes: attrs))

            cursor = match.range.location + match.range.length
        }

        if cursor < input.length {
            result.append(NSAttributedString(string: stripAllTags(input.substring(from: cursor)),
                                             attributes: defaultAttrs))
        }

        return result.length > 0
            ? result
            : NSAttributedString(string: stripAllTags(html), attributes: defaultAttrs)
    }

    // MARK: - UIColor Mapping (mirrors Theme tajweed colors)

    private static func uiColor(forClass className: String) -> UIColor {
        switch className.trimmingCharacters(in: .whitespaces) {
        case "ham_wasl", "lpieces-shf", "slnt":
            return UIColor(red: 0xAB/255, green: 0x47/255, blue: 0xBC/255, alpha: 1) // purple  – Lam
        case "madda_normal", "madda_permissible",
             "madda_necessary", "madda_obligatory":
            return UIColor(red: 0xFF/255, green: 0x98/255, blue: 0x00/255, alpha: 1) // orange  – Madd
        case "ikhf_shf", "ikhf", "ikhfa":
            return UIColor(red: 0x42/255, green: 0xA5/255, blue: 0xF5/255, alpha: 1) // blue    – Ikhfa
        case "ghunnah", "ghn", "ghunna":
            return UIColor(red: 0x4C/255, green: 0xAF/255, blue: 0x50/255, alpha: 1) // green   – Ghunna
        case "idgham_shf", "idgh_ghn", "idgh_w_ghn",
             "idgh_wo_ghn", "idgham":
            return UIColor(red: 0xB0/255, green: 0xBE/255, blue: 0xC5/255, alpha: 1) // gray    – Idgham
        case "qlq", "qalqpieces-shala", "qalqala":
            return UIColor(red: 0xEF/255, green: 0x53/255, blue: 0x50/255, alpha: 1) // red     – Qalqala
        default:
            return .white
        }
    }
}
