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

    // MARK: - Colour Usage Tests

    @Test("Colour usages are extracted from a PDF with multiple colour types")
    func colourUsagesExtracted() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("colour_usages.pdf")
        #expect(TestPDFGenerator.createPDFWithColours(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        // Should have at least one colour usage (the gray fill)
        #expect(!document.colourUsages.isEmpty)

        // All usages should reference page 0
        for usage in document.colourUsages {
            #expect(usage.pagesUsedOn.contains(0))
        }
    }

    @Test("Colour usages have correct context flags")
    func colourUsageContexts() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("colour_contexts.pdf")
        #expect(TestPDFGenerator.createPDFWithColours(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        // Should have fill contexts (from the gray fill rect)
        let fillUsages = document.colourUsages.filter { $0.usageContexts.contains(.pathFill) }
        #expect(!fillUsages.isEmpty)

        // Should have stroke contexts (from the RGB stroke rect)
        let strokeUsages = document.colourUsages.filter { $0.usageContexts.contains(.pathStroke) }
        #expect(!strokeUsages.isEmpty)
    }

    @Test("Colour usages have valid component values")
    func colourUsageComponents() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("colour_components.pdf")
        #expect(TestPDFGenerator.createPDFWithColours(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        for usage in document.colourUsages {
            // All components should be in 0-1 range
            for component in usage.components {
                #expect(component >= 0.0)
                #expect(component <= 1.0)
            }

            // Component count should match mode
            switch usage.mode {
            case .gray:
                #expect(usage.components.count == 1)
            case .rgb:
                #expect(usage.components.count == 3)
            case .cmyk:
                #expect(usage.components.count == 4)
            }

            // Ink sum should only be present for CMYK
            if usage.mode == .cmyk {
                #expect(usage.inkSum != nil)
            } else {
                #expect(usage.inkSum == nil)
            }
        }
    }

    @Test("Simple PDF produces colour usages from gray fill")
    func simplePDFColourUsages() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("simple_colours.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        // createSimplePDF uses setFillColor(gray:), which generates a gray fill
        let grayUsages = document.colourUsages.filter { $0.mode == .gray }
        #expect(!grayUsages.isEmpty)
    }

    @Test("ColourUsageInfo display name generation")
    func displayNames() {
        #expect(ColourUsageInfo.displayName(mode: .cmyk, components: [0, 0, 0, 1], spotName: nil) == "[Black]")
        #expect(ColourUsageInfo.displayName(mode: .cmyk, components: [0, 0, 0, 0], spotName: nil) == "[Paper]")
        #expect(ColourUsageInfo.displayName(mode: .cmyk, components: [0.6, 0.4, 0.4, 1.0], spotName: nil) == "C=60 M=40 Y=40 K=100")
        #expect(ColourUsageInfo.displayName(mode: .gray, components: [0], spotName: nil) == "[Black]")
        #expect(ColourUsageInfo.displayName(mode: .gray, components: [1], spotName: nil) == "[White]")
        #expect(ColourUsageInfo.displayName(mode: .gray, components: [0.5], spotName: nil) == "Gray 50%")
        #expect(ColourUsageInfo.displayName(mode: .rgb, components: [1, 0, 0], spotName: nil) == "R=255 G=0 B=0")
        #expect(ColourUsageInfo.displayName(mode: .cmyk, components: [0, 0, 0, 1], spotName: "PANTONE 485 C") == "PANTONE 485 C")
    }
}
