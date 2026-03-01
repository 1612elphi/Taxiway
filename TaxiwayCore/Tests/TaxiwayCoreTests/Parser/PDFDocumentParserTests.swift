import Testing
import Foundation
import CoreGraphics
@testable import TaxiwayCore

@Suite("PDFDocumentParser Tests")
struct PDFDocumentParserTests {

    let parser = PDFDocumentParser()

    @Test("Parse simple single-page PDF")
    func parseSimplePDF() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("simple.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        #expect(document.fileInfo.pageCount == 1)
        #expect(document.fileInfo.isEncrypted == false)
        #expect(document.fileInfo.fileSizeBytes > 0)
        #expect(document.fileInfo.fileName == "simple.pdf")
    }

    @Test("Parse multi-page PDF")
    func parseMultiPagePDF() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("multi.pdf")
        let sizes = [
            CGSize(width: 595.276, height: 841.89),
            CGSize(width: 612, height: 792),
            CGSize(width: 842, height: 595),
        ]
        #expect(TestPDFGenerator.createMultiPagePDF(at: pdfURL, pageSizes: sizes))

        let document = try parser.parse(url: pdfURL)

        #expect(document.fileInfo.pageCount == 3)
        #expect(document.pages.count == 3)
    }

    @Test("Parse nonexistent file throws fileNotFound")
    func parseNonexistentFile() throws {
        let fakeURL = URL(fileURLWithPath: "/tmp/nonexistent_\(UUID().uuidString).pdf")

        #expect(throws: ParsingError.fileNotFound(fakeURL)) {
            try parser.parse(url: fakeURL)
        }
    }

    @Test("Document info is populated")
    func documentInfoPopulated() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("info.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        // CGContext-created PDFs have a version
        #expect(!document.documentInfo.pdfVersion.isEmpty)
        // Linearized should be false for locally-created PDFs
        #expect(document.documentInfo.isLinearized == false)
    }

    @Test("File path is correctly captured")
    func filePathCaptured() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("path_test.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        #expect(document.fileInfo.filePath == pdfURL.path)
    }
}
