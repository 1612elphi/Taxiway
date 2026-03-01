import Foundation
import CoreGraphics
import CoreText

/// Errors that can occur during report export.
public enum ExportError: Error, Equatable {
    case cannotCreatePDF
}

/// Exports a `PreflightReport` in JSON, CSV, or PDF format.
public enum ReportExporter {

    /// Lock for CoreText/CoreGraphics operations which are not thread-safe.
    private static let pdfLock = NSLock()

    // MARK: - JSON

    /// Full JSON export of the report.
    public static func exportJSON(_ report: PreflightReport) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(report)
    }

    // MARK: - CSV

    /// CSV table of check results.
    public static func exportCSV(_ report: PreflightReport) -> Data {
        var csv = "Check Name,Category,Status,Severity,Message,Affected Items\n"
        for result in report.results {
            let name = csvEscape(result.checkTypeID)
            let category = categoryFromTypeID(result.checkTypeID)
            let status = result.status.rawValue
            let severity = severityString(result.severity)
            let message = csvEscape(result.message)
            let affected = csvEscape(affectedItemsDescription(result.affectedItems))
            csv += "\(name),\(category),\(status),\(severity),\(message),\(affected)\n"
        }
        return Data(csv.utf8)
    }

    // MARK: - PDF

    /// PDF summary report using CoreGraphics.
    /// Uses a lock internally because CoreText is not thread-safe.
    public static func exportPDF(_ report: PreflightReport) throws -> Data {
        pdfLock.lock()
        defer { pdfLock.unlock() }

        let pageWidth: CGFloat = 595   // A4
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 50
        let lineHeight: CGFloat = 15

        // Use a temporary file to avoid NSMutableData/CGDataConsumer lifetime issues
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let context = CGContext(tempURL as CFURL, mediaBox: &mediaBox, nil) else {
            throw ExportError.cannotCreatePDF
        }

        // Start first page
        context.beginPage(mediaBox: &mediaBox)
        var y = pageHeight - margin

        // Title
        drawText("Taxiway Preflight Report", at: CGPoint(x: margin, y: y), font: "Helvetica-Bold", size: 18, context: context)
        y -= 30

        // Status
        let statusText = report.overallStatus == .pass ? "PASS" : "FAIL"
        drawText("Status: \(statusText)", at: CGPoint(x: margin, y: y), font: "Helvetica", size: 10, context: context)
        y -= 20

        // File info
        if let url = report.documentURL {
            drawText("File: \(url.lastPathComponent)", at: CGPoint(x: margin, y: y), font: "Helvetica", size: 10, context: context)
            y -= lineHeight
        }
        drawText("Profile: \(report.profileName)", at: CGPoint(x: margin, y: y), font: "Helvetica", size: 10, context: context)
        y -= lineHeight

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        drawText("Date: \(dateFormatter.string(from: report.runAt))", at: CGPoint(x: margin, y: y), font: "Helvetica", size: 10, context: context)
        y -= 30

        // Results header
        drawText("Results:", at: CGPoint(x: margin, y: y), font: "Helvetica-Bold", size: 12, context: context)
        y -= 20

        for result in report.results {
            // Start a new page if we're running out of space
            if y < margin + 20 {
                context.endPage()
                context.beginPage(mediaBox: &mediaBox)
                y = pageHeight - margin
            }
            let prefix: String
            switch result.status {
            case .pass: prefix = "[PASS]"
            case .fail: prefix = "[FAIL]"
            case .warning: prefix = "[WARN]"
            case .skipped: prefix = "[SKIP]"
            }
            drawText("\(prefix) \(result.checkTypeID): \(result.message)",
                     at: CGPoint(x: margin, y: y), font: "Helvetica", size: 10, context: context)
            y -= lineHeight
        }

        context.endPage()
        context.closePDF()

        return try Data(contentsOf: tempURL)
    }

    // MARK: - Helpers

    /// Draw a single line of text at the given position.
    private static func drawText(_ text: String, at point: CGPoint, font fontName: String, size: CGFloat, context: CGContext) {
        let font = CTFontCreateWithName(fontName as CFString, size, nil)
        let attributes: [String: Any] = [kCTFontAttributeName as String: font]
        let attrString = CFAttributedStringCreate(kCFAllocatorDefault, text as CFString, attributes as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrString)
        context.textPosition = point
        CTLineDraw(line, context)
    }

    /// Escape a string for CSV output.
    static func csvEscape(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"" + string.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return string
    }

    /// Build a human-readable description of affected items.
    static func affectedItemsDescription(_ items: [AffectedItem]) -> String {
        items.map { item in
            switch item {
            case .document:
                return "Document"
            case .page(let index):
                return "Page \(index + 1)"
            case .font(let name, _):
                return "Font: \(name)"
            case .image(let id, let page, _):
                return "Image \(id) (page \(page + 1))"
            case .colourSpace(let name, _):
                return "Colour space: \(name)"
            case .annotation(let type, let page, _):
                return "\(type) (page \(page + 1))"
            case .textFrame(let id, let page, _):
                return "Text frame \(id) (page \(page + 1))"
            }
        }.joined(separator: "; ")
    }

    /// Map a severity value to a display string.
    static func severityString(_ severity: CheckSeverity) -> String {
        switch severity {
        case .error: return "Error"
        case .warning: return "Warning"
        case .info: return "Info"
        }
    }

    /// Derive a category name from a check type ID (e.g. "file.sizeMax" -> "file").
    private static func categoryFromTypeID(_ typeID: String) -> String {
        if let dotIndex = typeID.firstIndex(of: ".") {
            return String(typeID[typeID.startIndex..<dotIndex])
        }
        return typeID
    }
}
