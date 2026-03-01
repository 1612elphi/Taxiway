import Foundation
import PDFKit

/// Extracts annotation information from a PDF document.
struct AnnotationExtractor: Sendable {

    /// Extracts all annotations from the PDF document.
    static func extract(from pdfDoc: PDFDocument, warnings: inout [ParseWarning]) -> [AnnotationInfo] {
        var annotations: [AnnotationInfo] = []

        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i) else {
                continue
            }

            for annotation in page.annotations {
                let subtypeStr = annotation.type ?? "Unknown"
                let annotationType = mapAnnotationType(subtypeStr)

                let rect = annotation.bounds
                let annotBounds = AnnotationBounds(
                    x: rect.origin.x,
                    y: rect.origin.y,
                    width: rect.size.width,
                    height: rect.size.height
                )
                annotations.append(AnnotationInfo(
                    type: annotationType,
                    pageIndex: i,
                    subtype: subtypeStr,
                    bounds: annotBounds
                ))
            }
        }

        return annotations
    }

    private static func mapAnnotationType(_ subtype: String) -> AnnotationType {
        switch subtype {
        case "Link": return .link
        case "Widget": return .widget
        case "Text": return .text
        case "FreeText": return .freeText
        case "Highlight": return .highlight
        case "Underline": return .underline
        case "StrikeOut": return .strikeOut
        case "Stamp": return .stamp
        case "Ink": return .ink
        case "Popup": return .popup
        case "FileAttachment": return .fileAttachment
        default: return .other
        }
    }
}
