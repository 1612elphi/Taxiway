import Testing
import Foundation
import CoreGraphics
@testable import TaxiwayCore

@Suite("PageGeometry Tests")
struct PageGeometryTests {

    let parser = PDFDocumentParser()

    @Test("Simple page has mediaBox matching page size")
    func mediaBoxMatchesPageSize() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pageSize = CGSize(width: 612, height: 792) // US Letter
        let pdfURL = tempDir.appendingPathComponent("geometry.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL, pageSize: pageSize))

        let document = try parser.parse(url: pdfURL)

        #expect(document.pages.count == 1)
        let page = document.pages[0]

        // MediaBox should match the page size
        #expect(abs(page.mediaBox.width - pageSize.width) < 1.0)
        #expect(abs(page.mediaBox.height - pageSize.height) < 1.0)
    }

    @Test("TrimBox returns nil when same as media (CGContext default)")
    func trimBoxNilWhenSameAsMedia() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("no_trim.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        let page = document.pages[0]
        // CGContext doesn't set a separate trim box, so it should be nil
        #expect(page.trimBox == nil)
    }

    @Test("Rotation extracted correctly")
    func rotationExtracted() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("rotation.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        // Default rotation is 0
        #expect(document.pages[0].rotation == 0)
    }

    @Test("Multi-page has correct indices")
    func multiPageIndices() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("multi_geo.pdf")
        let sizes = [
            CGSize(width: 595, height: 842),
            CGSize(width: 612, height: 792),
        ]
        #expect(TestPDFGenerator.createMultiPagePDF(at: pdfURL, pageSizes: sizes))

        let document = try parser.parse(url: pdfURL)

        #expect(document.pages[0].index == 0)
        #expect(document.pages[1].index == 1)
    }
}
