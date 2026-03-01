import Testing
import Foundation
import CoreGraphics
@testable import TaxiwayCore

@Suite("Parser Integration Tests")
struct ParserIntegrationTests {

    let parser = PDFDocumentParser()

    @Test("End-to-end: PDF with text and image populates all fields")
    func endToEndParsing() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        // Create a PDF with text (which also creates font entries)
        let pdfURL = tempDir.appendingPathComponent("integration.pdf")
        #expect(TestPDFGenerator.createPDFWithText(at: pdfURL, text: "Integration Test", fontName: "Courier", fontSize: 18))

        let document = try parser.parse(url: pdfURL)

        // FileInfo
        #expect(document.fileInfo.fileName == "integration.pdf")
        #expect(document.fileInfo.pageCount == 1)
        #expect(document.fileInfo.fileSizeBytes > 0)
        #expect(document.fileInfo.isEncrypted == false)

        // DocumentInfo
        #expect(!document.documentInfo.pdfVersion.isEmpty)
        #expect(document.documentInfo.isLinearized == false)

        // Pages
        #expect(document.pages.count == 1)
        #expect(document.pages[0].index == 0)
        #expect(document.pages[0].mediaBox.width > 0)
        #expect(document.pages[0].mediaBox.height > 0)

        // Fonts - text PDF should have at least one font
        #expect(document.fonts.count >= 1)
        #expect(document.fonts[0].name.isEmpty == false)

        // Metadata
        #expect(document.metadata.hasC2PA == false)
        #expect(document.metadata.hasGenAIMetadata == false)

        // Annotations should be empty
        #expect(document.annotations.isEmpty)

        // Spot colours should be empty
        #expect(document.spotColours.isEmpty)
    }

    @Test("Full preflight engine against parsed document")
    func preflightAgainstParsed() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("preflight.pdf")
        #expect(TestPDFGenerator.createPDFWithText(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        // Create a simple profile with a page count check
        let entry = try CheckEntry(
            typeID: "pages.count",
            enabled: true,
            parameters: PageCountCheck.Parameters(operator: .moreThan, value: 0),
            severityOverride: .warning
        )
        let profile = PreflightProfile(
            name: "Test Profile",
            description: "Integration test profile",
            checks: [entry]
        )

        let engine = PreflightEngine()
        let report = try engine.run(profile: profile, on: document, documentURL: pdfURL)

        #expect(report.results.count == 1)
    }

    @Test("Multi-page PDF with different sizes parsed correctly")
    func multiPageIntegration() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("multi_integration.pdf")
        let sizes = [
            CGSize(width: 595.276, height: 841.89),  // A4
            CGSize(width: 612, height: 792),           // US Letter
        ]
        #expect(TestPDFGenerator.createMultiPagePDF(at: pdfURL, pageSizes: sizes))

        let document = try parser.parse(url: pdfURL)

        #expect(document.fileInfo.pageCount == 2)
        #expect(document.pages.count == 2)

        // First page should be approximately A4
        #expect(abs(document.pages[0].mediaBox.width - 595.276) < 1.0)

        // Second page should be approximately US Letter
        #expect(abs(document.pages[1].mediaBox.width - 612) < 1.0)
    }

    @Test("Parse warnings array is populated (not nil)")
    func parseWarningsPopulated() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("warnings.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        // Parse warnings should be an empty array (not nil) for a valid PDF
        #expect(document.parseWarnings.isEmpty)
    }
}
