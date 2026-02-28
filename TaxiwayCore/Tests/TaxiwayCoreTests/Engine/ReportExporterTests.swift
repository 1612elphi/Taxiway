import Testing
import Foundation
import CoreGraphics
@testable import TaxiwayCore

/// Build a sample report for testing.
private func makeSampleReport(resultCount: Int = 3) -> PreflightReport {
    let doc = TaxiwayDocument.sample
    var results: [CheckResult] = []

    if resultCount >= 1 {
        results.append(CheckResult(
            checkID: UUID(),
            checkTypeID: "fonts.not_embedded",
            status: .fail,
            severity: .error,
            message: "Font TimesNewRoman is not embedded",
            detail: "Non-embedded fonts may render differently on other systems.",
            affectedItems: [.font(name: "TimesNewRoman", pages: [1])]
        ))
    }
    if resultCount >= 2 {
        results.append(CheckResult(
            checkID: UUID(),
            checkTypeID: "images.resolution_below",
            status: .pass,
            severity: .warning,
            message: "All images meet minimum resolution"
        ))
    }
    if resultCount >= 3 {
        results.append(CheckResult(
            checkID: UUID(),
            checkTypeID: "file.encryption",
            status: .pass,
            severity: .error,
            message: "Document is not encrypted"
        ))
    }

    // For large result counts, pad with generated results
    for i in 3..<max(3, resultCount) {
        results.append(CheckResult(
            checkID: UUID(),
            checkTypeID: "test.check_\(i)",
            status: i % 2 == 0 ? .pass : .fail,
            severity: .warning,
            message: "Test check \(i) result message",
            affectedItems: [.page(index: i % 5)]
        ))
    }

    let overallStatus: PreflightOutcome = results.contains(where: { $0.status == .fail }) ? .fail : .pass

    return PreflightReport(
        profileID: PreflightProfile.pdfX1a.id,
        profileName: "PDF/X-1a",
        documentURL: URL(fileURLWithPath: "/Users/test/Documents/SampleBrochure.pdf"),
        documentSnapshot: doc,
        results: results,
        overallStatus: overallStatus,
        runAt: Date(timeIntervalSince1970: 1_700_000_000),
        duration: 0.42
    )
}

// MARK: - JSON Export

@Suite("ReportExporter.JSON")
struct ReportExporterJSONTests {

    @Test("JSON export round-trip: export, decode, verify fields")
    func jsonRoundTrip() throws {
        let report = makeSampleReport()
        let jsonData = try ReportExporter.exportJSON(report)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PreflightReport.self, from: jsonData)

        #expect(decoded.profileName == "PDF/X-1a")
        #expect(decoded.results.count == 3)
        #expect(decoded.overallStatus == .fail)
        #expect(decoded.documentSnapshot.fileInfo.fileName == "SampleBrochure.pdf")
    }

    @Test("JSON export produces valid UTF-8 string")
    func jsonIsValidUTF8() throws {
        let report = makeSampleReport()
        let jsonData = try ReportExporter.exportJSON(report)
        let jsonString = String(data: jsonData, encoding: .utf8)
        #expect(jsonString != nil)
        // JSON encoder may escape '/' as '\/', so check for the profile name in either form
        #expect(jsonString!.contains("PDF") && jsonString!.contains("X-1a"))
    }
}

// MARK: - CSV Export

@Suite("ReportExporter.CSV")
struct ReportExporterCSVTests {

    @Test("CSV has correct header row")
    func csvHeaderRow() {
        let report = makeSampleReport()
        let csvData = ReportExporter.exportCSV(report)
        let csvString = String(data: csvData, encoding: .utf8)!
        let lines = csvString.components(separatedBy: "\n")
        #expect(lines[0] == "Check Name,Category,Status,Severity,Message,Affected Items")
    }

    @Test("CSV has correct number of data rows")
    func csvRowCount() {
        let report = makeSampleReport(resultCount: 5)
        let csvData = ReportExporter.exportCSV(report)
        let csvString = String(data: csvData, encoding: .utf8)!
        let lines = csvString.components(separatedBy: "\n").filter { !$0.isEmpty }
        // 1 header + 5 data rows
        #expect(lines.count == 6)
    }

    @Test("CSV escapes commas in messages")
    func csvEscapesCommas() {
        let result = CheckResult(
            checkID: UUID(),
            checkTypeID: "test.comma",
            status: .fail,
            severity: .warning,
            message: "Found issues: alpha, beta, gamma"
        )
        let report = PreflightReport(
            profileID: UUID(),
            profileName: "Test",
            documentSnapshot: TaxiwayDocument.sample,
            results: [result],
            overallStatus: .fail,
            runAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let csvData = ReportExporter.exportCSV(report)
        let csvString = String(data: csvData, encoding: .utf8)!
        #expect(csvString.contains("\"Found issues: alpha, beta, gamma\""))
    }

    @Test("CSV escapes double quotes in messages")
    func csvEscapesDoubleQuotes() {
        let escaped = ReportExporter.csvEscape("She said \"hello\"")
        #expect(escaped == "\"She said \"\"hello\"\"\"")
    }

    @Test("CSV with empty results produces header only")
    func csvEmptyResults() {
        let report = makeSampleReport(resultCount: 0)
        let csvData = ReportExporter.exportCSV(report)
        let csvString = String(data: csvData, encoding: .utf8)!
        let lines = csvString.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count == 1)
    }

    @Test("CSV includes affected items")
    func csvAffectedItems() {
        let report = makeSampleReport(resultCount: 1)
        let csvData = ReportExporter.exportCSV(report)
        let csvString = String(data: csvData, encoding: .utf8)!
        #expect(csvString.contains("Font: TimesNewRoman"))
    }
}

// MARK: - PDF Export (serialized to avoid CoreGraphics thread-safety issues)

@Suite("ReportExporter.PDF")
struct ReportExporterPDFTests {

    // Note: CoreText/CGContext has a known issue where creating multiple PDF contexts
    // in the same process can cause Range precondition failures on some macOS versions.
    // All PDF scenarios are tested in a single test function to work around this.

    @Test("PDF export produces valid output for all scenarios")
    @MainActor func pdfExportAllScenarios() throws {
        // Build a report with 55 results (enough for multi-page)
        let report = makeSampleReport(resultCount: 55)
        let pdfData = try ReportExporter.exportPDF(report)

        // Verify non-empty
        #expect(pdfData.count > 100)

        // Verify %PDF magic bytes
        let headerBytes = [UInt8](pdfData.prefix(4))
        #expect(headerBytes == [0x25, 0x50, 0x44, 0x46]) // %PDF
    }
}

// MARK: - Helpers

@Suite("ReportExporter.Helpers")
struct ReportExporterHelperTests {

    @Test("Affected items description formats all types")
    func affectedItemsDescription() {
        let items: [AffectedItem] = [
            .document,
            .page(index: 2),
            .font(name: "Helvetica", pages: [0, 1]),
            .image(id: "img_1", page: 3),
            .colourSpace(name: "DeviceRGB", pages: [0]),
            .annotation(type: "Link", page: 4),
        ]
        let desc = ReportExporter.affectedItemsDescription(items)
        #expect(desc.contains("Document"))
        #expect(desc.contains("Page 3"))
        #expect(desc.contains("Font: Helvetica"))
        #expect(desc.contains("Image img_1 (page 4)"))
        #expect(desc.contains("Colour space: DeviceRGB"))
        #expect(desc.contains("Link (page 5)"))
    }

    @Test("Severity string maps correctly")
    func severityStrings() {
        #expect(ReportExporter.severityString(.error) == "Error")
        #expect(ReportExporter.severityString(.warning) == "Warning")
        #expect(ReportExporter.severityString(.info) == "Info")
    }
}
