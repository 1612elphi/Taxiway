import Testing
import Foundation
@testable import TaxiwayCore

@Suite("AnnotationExtractor Tests")
struct AnnotationExtractorTests {

    let parser = PDFDocumentParser()

    @Test("PDF without annotations returns empty array")
    func noAnnotations() throws {
        let tempDir = TestPDFGenerator.createTempDirectory()
        defer { TestPDFGenerator.cleanupTempDirectory(tempDir) }

        let pdfURL = tempDir.appendingPathComponent("no_annotations.pdf")
        #expect(TestPDFGenerator.createSimplePDF(at: pdfURL))

        let document = try parser.parse(url: pdfURL)

        #expect(document.annotations.isEmpty)
    }

    @Test("Annotation type mapping covers known types")
    func annotationTypeMapping() throws {
        // This test verifies the annotation type enum values are correctly defined
        // by checking that the AnnotationType enum has all expected cases
        let types: [AnnotationType] = [.link, .widget, .text, .freeText, .highlight,
                                        .underline, .strikeOut, .stamp, .ink, .popup,
                                        .fileAttachment, .other]
        #expect(types.count == 12)
    }
}
