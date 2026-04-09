// DeenApp/Views/Components/JustifiedArabicText.swift
//
// Shared UITextView-based component for justified RTL Arabic text.
// Used by QuranView (Mushaf mode) and SurahRevealView.

import SwiftUI
import UIKit

struct JustifiedArabicText: UIViewRepresentable {
    let segments: [(text: String, isMarker: Bool, ayahID: Int)]
    let bodyFont: UIFont
    let markerFont: UIFont
    let tajweedEnabled: Bool
    let tajweedCache: [Int: String]
    let readingMode: Bool

    private var markerColor: UIColor { UIColor(ThemeColor.current.color) }
    private var defaultTextColor: UIColor { readingMode ? .black : .white }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        tv.attributedText = attributedString
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: fitted.height)
    }

    private var attributedString: NSAttributedString {
        let para = NSMutableParagraphStyle()
        para.alignment = .justified
        para.baseWritingDirection = .rightToLeft
        para.lineSpacing = 12

        let result = NSMutableAttributedString()
        for seg in segments {
            if seg.isMarker {
                result.append(NSAttributedString(string: seg.text, attributes: [
                    .font:            markerFont,
                    .foregroundColor: markerColor,
                    .paragraphStyle:  para,
                ]))
            } else if tajweedEnabled, let html = tajweedCache[seg.ayahID] {
                result.append(TajweedParser.nsAttributedString(
                    from: html, bodyFont: bodyFont, paragraphStyle: para,
                    defaultTextColor: defaultTextColor
                ))
            } else {
                let cleaned = TajweedParser.sanitizePlain(seg.text)
                result.append(NSAttributedString(string: cleaned, attributes: [
                    .font:            bodyFont,
                    .foregroundColor: defaultTextColor,
                    .paragraphStyle:  para,
                ]))
            }
        }
        return result
    }
}
