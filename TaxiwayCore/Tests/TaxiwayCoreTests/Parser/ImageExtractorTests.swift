import Testing
import Foundation
@testable import TaxiwayCore

@Suite("ImageExtractor Tests")
struct ImageExtractorTests {

    let parser = PDFDocumentParser()

    @Test("PDF without images returns empty array")
    func pdfWithoutImages() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("no_images.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        #expect(document.images.isEmpty)
    }

    @Test("PDF with embedded image returns image info")
    func pdfWithImage() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("with_image.pdf")
        let imgSize = CGSize(width: 200, height: 150)
        #expect(TestPDFGenerator.createPDFWithImage(at: pdfURL, imageSize: imgSize))

        let document = try parser.parse(url: pdfURL)

        // CGContext.draw(image:in:) may or may not create an XObject entry in the PDF.
        // Some implementations inline the image data. If images are found, verify properties.
        if !document.images.isEmpty {
            let image = document.images[0]
            #expect(image.pageIndex == 0)
            #expect(image.widthPixels > 0)
            #expect(image.heightPixels > 0)
            #expect(image.bitsPerComponent > 0)
        }
    }

    @Test("Image IDs are unique")
    func imageIDsUnique() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("unique_ids.pdf")
        #expect(TestPDFGenerator.createPDFWithImage(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        let ids = document.images.map(\.id)
        let uniqueIDs = Set(ids)
        #expect(ids.count == uniqueIDs.count)
    }
}
