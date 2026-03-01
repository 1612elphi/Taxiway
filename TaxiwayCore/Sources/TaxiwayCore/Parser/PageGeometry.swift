import Foundation
import CoreGraphics
import PDFKit

/// Extracts page geometry (boxes, rotation) from a PDF document.
struct PageGeometry: Sendable {
    /// Extracts page information from all pages in the PDF document.
    static func extract(from pdfDoc: PDFDocument, warnings: inout [ParseWarning]) -> [PageInfo] {
        var pages: [PageInfo] = []

        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i) else {
                warnings.append(ParseWarning(domain: "PageGeometry", message: "Could not access page at index \(i)", pageIndex: i))
                continue
            }

            let mediaBox = page.bounds(for: .mediaBox)
            let trimBox = extractBox(page: page, boxType: .trimBox, mediaBox: mediaBox)
            let bleedBox = extractBox(page: page, boxType: .bleedBox, mediaBox: mediaBox)
            let artBox = extractBox(page: page, boxType: .artBox, mediaBox: mediaBox)
            let rotation = page.rotation

            pages.append(PageInfo(
                index: i,
                mediaBox: mediaBox,
                trimBox: trimBox,
                bleedBox: bleedBox,
                artBox: artBox,
                rotation: rotation
            ))
        }

        return pages
    }

    /// Returns the box rect if it differs from the media box, otherwise nil.
    /// PDFKit returns the media box when a specific box type is not explicitly set.
    private static func extractBox(page: PDFPage, boxType: PDFDisplayBox, mediaBox: CGRect) -> CGRect? {
        let box = page.bounds(for: boxType)
        // If the box matches the media box, it likely wasn't explicitly set
        if boxesAreEqual(box, mediaBox) {
            return nil
        }
        return box
    }

    private static func boxesAreEqual(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.origin.x - b.origin.x) < 0.01 &&
        abs(a.origin.y - b.origin.y) < 0.01 &&
        abs(a.size.width - b.size.width) < 0.01 &&
        abs(a.size.height - b.size.height) < 0.01
    }
}
