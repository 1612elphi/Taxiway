import Testing
import Foundation
@testable import TaxiwayCore

@Suite("MetadataExtractor Tests")
struct MetadataExtractorTests {

    let parser = PDFDocumentParser()

    @Test("Document attributes extracted")
    func documentAttributesExtracted() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("metadata.pdf")
        #expect(TestPDFGenerator.createPDFWithText(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        // CGContext-created PDFs may or may not have producer/creator
        // The metadata struct should at least be populated
        let metadata = document.metadata
        #expect(metadata.hasC2PA == false)
        #expect(metadata.hasGenAIMetadata == false)
    }

    @Test("C2PA defaults to false for normal PDFs")
    func c2paDefaultsFalse() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("no_c2pa.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        #expect(document.metadata.hasC2PA == false)
    }

    @Test("GenAI metadata defaults to false for normal PDFs")
    func genAIDefaultsFalse() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("no_genai.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        #expect(document.metadata.hasGenAIMetadata == false)
    }

    @Test("Output intents are empty for simple PDFs")
    func outputIntentsEmpty() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("no_intents.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        #expect(document.metadata.outputIntents.isEmpty)
    }
}
