//
//  PDFGenerator.swift
//  DeenApp
//
//  Mehrseitige PDF-Tabellen für exportierte Karteikarten (UIKit PDF).
//  Koordinaten: PDF-Standard (Ursprung unten links) — ohne Y-Spiegelung im CTM.
//

import UIKit

enum PDFGenerator {

    private static let pageWidth: CGFloat = 612
    private static let pageHeight: CGFloat = 792
    private static let margin: CGFloat = 48
    private static let rowPadding: CGFloat = 10
    private static let titleFont = UIFont.systemFont(ofSize: 22, weight: .semibold)
    private static let headerFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
    private static let bodyFont = UIFont.systemFont(ofSize: 14, weight: .regular)
    private static let arabicBodyFont = UIFont.systemFont(ofSize: 15, weight: .regular)

    private static let titleColor = UIColor(white: 0.1, alpha: 1)
    private static let headerFill = UIColor(white: 0.93, alpha: 1)
    private static let borderColor = UIColor(white: 0.75, alpha: 1)
    private static let zebra = UIColor(white: 0.98, alpha: 1)

    /// `y` / `height` beziehen sich auf **oben-nach-unten** (wie auf dem Bildschirm).
    /// PDF nutzt Ursprung unten links — hier konvertieren wir ohne `scale(1,-1)`.
    private static func rectTopDownToPDF(_ x: CGFloat, _ yFromTop: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        CGRect(x: x, y: pageHeight - yFromTop - height, width: width, height: height)
    }

    private static func lineTopDownVertical(x: CGFloat, yTop: CGFloat, height: CGFloat, context: CGContext) {
        let yBottomPDF = pageHeight - yTop - height
        let yTopPDF = pageHeight - yTop
        context.move(to: CGPoint(x: x, y: yBottomPDF))
        context.addLine(to: CGPoint(x: x, y: yTopPDF))
        context.strokePath()
    }

    /// Erzeugt eine mehrseitige PDF-Tabelle und schreibt sie in ein Temp-File.
    static func generateLearnedWordsPDF(cards: [FlashcardCard]) throws -> URL {
        guard !cards.isEmpty else {
            throw PDFGeneratorError.noCards
        }

        let sorted = cards.sorted { $0.frequency > $1.frequency }
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            let cg = context.cgContext
            var cardIndex = 0
            var yFromTop: CGFloat = margin

            func beginPage() {
                context.beginPage()
            }

            func contentWidth() -> CGFloat {
                pageWidth - margin * 2
            }

            func columnWidths() -> (arabic: CGFloat, translation: CGFloat) {
                let w = contentWidth()
                return (w * 0.38, w * 0.62)
            }

            func drawTitle() {
                let title = "My Learned Quran Words" as NSString
                let attrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: titleColor]
                let size = title.boundingRect(
                    with: CGSize(width: contentWidth(), height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs,
                    context: nil
                ).size
                let h = size.height
                let rectPDF = rectTopDownToPDF(margin, yFromTop, contentWidth(), h)
                title.draw(in: rectPDF, withAttributes: attrs)
                yFromTop += h + 20
            }

            func tableHeaderHeight() -> CGFloat {
                let (cwA, cwT) = columnWidths()
                let h1 = "Arabic".boundingRect(
                    with: CGSize(width: cwA - rowPadding * 2, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: headerFont],
                    context: nil
                ).height
                let h2 = "Translation".boundingRect(
                    with: CGSize(width: cwT - rowPadding * 2, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: headerFont],
                    context: nil
                ).height
                return max(h1, h2) + rowPadding * 2
            }

            func drawTableHeader() {
                let (cwA, cwT) = columnWidths()
                let hh = tableHeaderHeight()
                let outerPDF = rectTopDownToPDF(margin, yFromTop, contentWidth(), hh)

                headerFill.setFill()
                cg.setFillColor(headerFill.cgColor)
                cg.fill(outerPDF)

                borderColor.setStroke()
                cg.setStrokeColor(borderColor.cgColor)
                cg.setLineWidth(0.5)
                cg.stroke(outerPDF)

                let colArabicPDF = rectTopDownToPDF(margin, yFromTop, cwA, hh)
                let colTransPDF = rectTopDownToPDF(margin + cwA, yFromTop, cwT, hh)

                ("Arabic" as NSString).draw(
                    in: colArabicPDF.insetBy(dx: rowPadding, dy: rowPadding),
                    withAttributes: [.font: headerFont, .foregroundColor: titleColor]
                )
                ("Translation" as NSString).draw(
                    in: colTransPDF.insetBy(dx: rowPadding, dy: rowPadding),
                    withAttributes: [.font: headerFont, .foregroundColor: titleColor]
                )

                let midX = margin + cwA
                borderColor.setStroke()
                cg.setStrokeColor(borderColor.cgColor)
                lineTopDownVertical(x: midX, yTop: yFromTop, height: hh, context: cg)

                yFromTop += hh
            }

            func rowHeight(for card: FlashcardCard) -> CGFloat {
                let (cwA, cwT) = columnWidths()
                let arAttrs: [NSAttributedString.Key: Any] = [.font: arabicBodyFont, .foregroundColor: titleColor]
                let enAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: titleColor]

                let hA = (card.arabic as NSString).boundingRect(
                    with: CGSize(width: cwA - rowPadding * 2, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: arAttrs,
                    context: nil
                ).height
                let hE = (card.meaningEN as NSString).boundingRect(
                    with: CGSize(width: cwT - rowPadding * 2, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: enAttrs,
                    context: nil
                ).height
                return max(hA, hE) + rowPadding * 2
            }

            func drawRow(_ card: FlashcardCard, rowYFromTop: CGFloat, rowH: CGFloat, zebraRow: Bool) {
                let (cwA, cwT) = columnWidths()
                let outerPDF = rectTopDownToPDF(margin, rowYFromTop, contentWidth(), rowH)

                if zebraRow {
                    cg.setFillColor(zebra.cgColor)
                    cg.fill(outerPDF)
                }

                cg.setStrokeColor(borderColor.cgColor)
                cg.setLineWidth(0.5)
                cg.stroke(outerPDF)

                let colArabicPDF = rectTopDownToPDF(margin, rowYFromTop, cwA, rowH)
                let colTransPDF = rectTopDownToPDF(margin + cwA, rowYFromTop, cwT, rowH)

                let paraArabic = NSMutableParagraphStyle()
                paraArabic.alignment = .right
                let arAttrs: [NSAttributedString.Key: Any] = [
                    .font: arabicBodyFont,
                    .foregroundColor: titleColor,
                    .paragraphStyle: paraArabic,
                ]
                (card.arabic as NSString).draw(
                    in: colArabicPDF.insetBy(dx: rowPadding, dy: rowPadding),
                    withAttributes: arAttrs
                )

                let paraEn = NSMutableParagraphStyle()
                paraEn.alignment = .left
                let enAttrs: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: titleColor,
                    .paragraphStyle: paraEn,
                ]
                (card.meaningEN as NSString).draw(
                    in: colTransPDF.insetBy(dx: rowPadding, dy: rowPadding),
                    withAttributes: enAttrs
                )

                let midX = margin + cwA
                cg.setStrokeColor(borderColor.cgColor)
                lineTopDownVertical(x: midX, yTop: rowYFromTop, height: rowH, context: cg)
            }

            let bottomLimitFromTop = pageHeight - margin

            beginPage()
            drawTitle()

            let headerH = tableHeaderHeight()
            if yFromTop + headerH > bottomLimitFromTop {
                beginPage()
                yFromTop = margin
            }
            drawTableHeader()

            var rowStripe = false
            while cardIndex < sorted.count {
                let card = sorted[cardIndex]
                let rh = rowHeight(for: card)

                if yFromTop + rh > bottomLimitFromTop {
                    beginPage()
                    yFromTop = margin
                    drawTableHeader()
                    rowStripe = false
                }

                drawRow(card, rowYFromTop: yFromTop, rowH: rh, zebraRow: rowStripe)
                yFromTop += rh
                rowStripe.toggle()
                cardIndex += 1
            }
        }

        let name = "LearnedQuranWords-\(Int(Date().timeIntervalSince1970)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }
}

enum PDFGeneratorError: Error {
    case noCards
}
