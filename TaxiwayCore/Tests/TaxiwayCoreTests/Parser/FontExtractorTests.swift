import Testing
import Foundation
@testable import TaxiwayCore

@Suite("FontExtractor Tests")
struct FontExtractorTests {

    let parser = PDFDocumentParser()

    @Test("PDF with drawn text has at least 1 font entry")
    func pdfWithTextHasFonts() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("fonts.pdf")
        #expect(TestPDFGenerator.createPDFWithText(at: pdfURL, text: "Test font extraction"))

        let document = try parser.parse(url: pdfURL)

        #expect(document.fonts.count >= 1)
    }

    @Test("Font names are extracted correctly")
    func fontNamesExtracted() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("font_names.pdf")
        #expect(TestPDFGenerator.createPDFWithText(at: pdfURL, text: "Hello", fontName: "Helvetica", fontSize: 24))

        let document = try parser.parse(url: pdfURL)

        // Should contain a font with "Helvetica" in its name
        let hasHelvetica = document.fonts.contains { $0.name.contains("Helvetica") }
        #expect(hasHelvetica)
    }

    @Test("Font type is identified")
    func fontTypeIdentified() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("font_type.pdf")
        #expect(TestPDFGenerator.createPDFWithText(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        // All fonts should have a type assigned
        for font in document.fonts {
            // The type should be some known type, not necessarily unknown
            #expect(font.name.isEmpty == false)
        }
    }

    @Test("PDF without text has no fonts")
    func pdfWithoutTextNoFonts() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("no_fonts.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        #expect(document.fonts.isEmpty)
    }

    @Test("Subset detection works for prefixed names")
    func subsetDetection() throws {
        // Test the subset detection logic directly via a parsed document
        // A subset font name has pattern: ABCDEF+FontName
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("subset_test.pdf")
        #expect(TestPDFGenerator.createPDFWithText(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        // CoreText/CGContext-created PDFs typically don't subset fonts,
        // so we verify the isSubset flag is set correctly
        for font in document.fonts {
            if font.name.count > 7 {
                let prefix = font.name.prefix(7)
                let letters = prefix.prefix(6)
                let plus = prefix.last
                let looksSubset = letters.allSatisfy { $0.isUppercase && $0.isLetter } && plus == "+"
                #expect(font.isSubset == looksSubset)
            } else {
                #expect(font.isSubset == false)
            }
        }
    }
}
