import Testing
import Foundation
@testable import TaxiwayCore

// MARK: - PDFVersionCheck

@Suite("PDFVersionCheck")
struct PDFVersionCheckTests {

    @Test("Passes when version matches with .is operator")
    func passVersionIs() {
        // Sample is PDF 1.7
        let check = PDFVersionCheck(parameters: .init(operator: .is, version: "1.7"))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("1.7"))
    }

    @Test("Fails when version does not match with .is operator")
    func failVersionIs() {
        let check = PDFVersionCheck(parameters: .init(operator: .is, version: "2.0"))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.detail!.contains("2.0"))
        #expect(result.detail!.contains("1.7"))
        #expect(result.affectedItems == [.document])
    }

    @Test("Passes when version differs with .isNot operator")
    func passVersionIsNot() {
        let check = PDFVersionCheck(parameters: .init(operator: .isNot, version: "1.4"))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Fails when version matches with .isNot operator")
    func failVersionIsNot() {
        let check = PDFVersionCheck(parameters: .init(operator: .isNot, version: "1.7"))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
    }

    @Test("Works with empty document (PDF 1.4)")
    func emptyDocument() {
        let check = PDFVersionCheck(parameters: .init(operator: .is, version: "1.4"))
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("Default severity is error")
    func defaultSeverity() {
        let check = PDFVersionCheck(parameters: .init(operator: .is, version: "1.7"))
        #expect(check.defaultSeverity == .error)
    }
}

// MARK: - PDFConformanceCheck

@Suite("PDFConformanceCheck")
struct PDFConformanceCheckTests {

    @Test("Passes for PDF/X standard when GTS_PDFX output intent present")
    func passPDFXConformance() {
        // Sample has GTS_PDFX output intent
        let check = PDFConformanceCheck(parameters: .init(standard: .x1a))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("PDF/X-1a"))
    }

    @Test("Fails when no output intents exist")
    func failNoOutputIntents() {
        let check = PDFConformanceCheck(parameters: .init(standard: .x1a))
        let result = check.run(on: .empty)

        #expect(result.status == .fail)
        #expect(result.message.contains("No output intents"))
        #expect(result.affectedItems == [.document])
    }

    @Test("Fails for PDF/A when only PDF/X output intent exists")
    func failPDFAWithPDFXIntent() {
        // Sample has GTS_PDFX, not GTS_PDFA1
        let check = PDFConformanceCheck(parameters: .init(standard: .a1b))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.detail!.contains("GTS_PDFA1"))
        #expect(result.detail!.contains("GTS_PDFX"))
    }

    @Test("Passes for PDF/A when GTS_PDFA1 output intent present")
    func passPDFAConformance() {
        let doc = TaxiwayDocument.sample.withMetadata { meta in
            DocumentMetadata(
                title: meta.title, author: meta.author, subject: meta.subject, keywords: meta.keywords,
                creationDate: meta.creationDate, modificationDate: meta.modificationDate, trapped: meta.trapped,
                outputIntents: [
                    OutputIntent(subtype: "GTS_PDFA1", outputCondition: nil,
                                 outputConditionIdentifier: "sRGB", registryName: nil)
                ],
                xmpRaw: meta.xmpRaw, hasC2PA: meta.hasC2PA, hasGenAIMetadata: meta.hasGenAIMetadata
            )
        }
        let check = PDFConformanceCheck(parameters: .init(standard: .a2b))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("All PDF/X standards share the same expected subtype")
    func pdfxSubtypes() {
        #expect(PDFStandard.x1a.expectedSubtype == "GTS_PDFX")
        #expect(PDFStandard.x3.expectedSubtype == "GTS_PDFX")
        #expect(PDFStandard.x4.expectedSubtype == "GTS_PDFX")
    }

    @Test("All PDF/A standards share the same expected subtype")
    func pdfaSubtypes() {
        #expect(PDFStandard.a1b.expectedSubtype == "GTS_PDFA1")
        #expect(PDFStandard.a2b.expectedSubtype == "GTS_PDFA1")
        #expect(PDFStandard.a3b.expectedSubtype == "GTS_PDFA1")
    }

    @Test("Default severity is error")
    func defaultSeverity() {
        let check = PDFConformanceCheck(parameters: .init(standard: .x1a))
        #expect(check.defaultSeverity == .error)
    }
}

// MARK: - LinearizedCheck

@Suite("LinearizedCheck")
struct LinearizedCheckTests {

    @Test("Passes when expecting not linearized and document is not")
    func passNotLinearized() {
        // Sample is not linearized
        let check = LinearizedCheck(parameters: .init(expected: false))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("not linearized"))
    }

    @Test("Fails when expecting linearized but document is not")
    func failExpectedLinearized() {
        let check = LinearizedCheck(parameters: .init(expected: true))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.message.contains("not linearized"))
        #expect(result.affectedItems == [.document])
    }

    @Test("Passes when expecting linearized and document is")
    func passLinearized() {
        let doc = TaxiwayDocument.sample.withDocumentInfo { info in
            DocumentInfo(pdfVersion: info.pdfVersion, producer: info.producer, creator: info.creator,
                         isLinearized: true, isTagged: info.isTagged, hasLayers: info.hasLayers)
        }
        let check = LinearizedCheck(parameters: .init(expected: true))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Fails when expecting not linearized but document is")
    func failUnexpectedLinearized() {
        let doc = TaxiwayDocument.sample.withDocumentInfo { info in
            DocumentInfo(pdfVersion: info.pdfVersion, producer: info.producer, creator: info.creator,
                         isLinearized: true, isTagged: info.isTagged, hasLayers: info.hasLayers)
        }
        let check = LinearizedCheck(parameters: .init(expected: false))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
    }

    @Test("Default severity is info")
    func defaultSeverity() {
        let check = LinearizedCheck(parameters: .init(expected: true))
        #expect(check.defaultSeverity == .info)
    }
}

// MARK: - TaggedCheck

@Suite("TaggedCheck")
struct TaggedCheckTests {

    @Test("Passes when expecting tagged and document is tagged")
    func passTagged() {
        // Sample is tagged
        let check = TaggedCheck(parameters: .init(expected: true))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("tagged"))
    }

    @Test("Fails when expecting tagged but document is not")
    func failExpectedTagged() {
        // Empty doc is not tagged
        let check = TaggedCheck(parameters: .init(expected: true))
        let result = check.run(on: .empty)

        #expect(result.status == .fail)
        #expect(result.message.contains("not tagged"))
        #expect(result.affectedItems == [.document])
    }

    @Test("Passes when expecting not tagged and document is not")
    func passNotTagged() {
        let check = TaggedCheck(parameters: .init(expected: false))
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("Fails when expecting not tagged but document is")
    func failUnexpectedTagged() {
        let check = TaggedCheck(parameters: .init(expected: false))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
    }

    @Test("Default severity is info")
    func defaultSeverity() {
        let check = TaggedCheck(parameters: .init(expected: true))
        #expect(check.defaultSeverity == .info)
    }
}

// MARK: - LayersPresentCheck

@Suite("LayersPresentCheck")
struct LayersPresentCheckTests {

    @Test("Passes when document has no layers")
    func passNoLayers() {
        // Sample has no layers
        let check = LayersPresentCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("not contain layers"))
    }

    @Test("Fails when document has layers")
    func failHasLayers() {
        let doc = TaxiwayDocument.sample.withDocumentInfo { info in
            DocumentInfo(pdfVersion: info.pdfVersion, producer: info.producer, creator: info.creator,
                         isLinearized: info.isLinearized, isTagged: info.isTagged, hasLayers: true)
        }
        let check = LayersPresentCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.message.contains("contains layers"))
        #expect(result.affectedItems == [.document])
    }

    @Test("Passes on empty document (no layers)")
    func passEmptyDocument() {
        let check = LayersPresentCheck()
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("Default severity is info")
    func defaultSeverity() {
        let check = LayersPresentCheck()
        #expect(check.defaultSeverity == .info)
    }
}

// MARK: - AnnotationsPresentCheck

@Suite("AnnotationsPresentCheck")
struct AnnotationsPresentCheckTests {

    @Test("Passes when no annotations exist")
    func passNoAnnotations() {
        // Sample has no annotations
        let check = AnnotationsPresentCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("No annotations"))
    }

    @Test("Fails when annotations exist")
    func failWithAnnotations() {
        let doc = TaxiwayDocument.sample.withAnnotations([
            AnnotationInfo(type: .link, pageIndex: 0),
            AnnotationInfo(type: .text, pageIndex: 1),
        ])
        let check = AnnotationsPresentCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.message.contains("2"))
        #expect(result.affectedItems.count == 2)
    }

    @Test("Passes on empty document")
    func passEmptyDocument() {
        let check = AnnotationsPresentCheck()
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("Reports correct detail summary with multiple annotation types")
    func detailSummary() {
        let doc = TaxiwayDocument.sample.withAnnotations([
            AnnotationInfo(type: .link, pageIndex: 0),
            AnnotationInfo(type: .link, pageIndex: 1),
            AnnotationInfo(type: .highlight, pageIndex: 0),
        ])
        let check = AnnotationsPresentCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.message.contains("3"))
        #expect(result.detail != nil)
        #expect(result.detail!.contains("Link"))
        #expect(result.detail!.contains("Highlight"))
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = AnnotationsPresentCheck()
        #expect(check.defaultSeverity == .warning)
    }
}
