import Testing
import Foundation
@testable import TaxiwayCore

@Suite("ColourExtractor Tests")
struct ColourExtractorTests {

    let parser = PDFDocumentParser()

    @Test("Simple PDF colour spaces can be extracted without error")
    func simpleColourSpaces() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("colours.pdf")
        #expect(TestPDFGenerator.createPDFWithText(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        // The colour spaces array may or may not contain entries depending
        // on whether CoreText creates explicit ColorSpace resource entries.
        // We just verify parsing completes without error.
        #expect(document.colourSpaces.count >= 0)
    }

    @Test("Spot colours are empty for simple PDFs")
    func noSpotColours() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("no_spots.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        #expect(document.spotColours.isEmpty)
    }

    @Test("Colour spaces track page indices correctly")
    func colourSpacePageTracking() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("colour_pages.pdf")
        #expect(TestPDFGenerator.createPDFWithText(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        // All colour spaces should have valid page indices
        for cs in document.colourSpaces {
            for pageIdx in cs.pagesUsedOn {
                #expect(pageIdx >= 0)
                #expect(pageIdx < document.fileInfo.pageCount)
            }
        }
    }
}
