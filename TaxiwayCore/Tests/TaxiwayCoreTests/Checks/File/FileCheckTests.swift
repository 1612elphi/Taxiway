import Testing
import Foundation
@testable import TaxiwayCore

// MARK: - FileSizeMinCheck

@Suite("FileSizeMinCheck")
struct FileSizeMinCheckTests {

    @Test("Passes when file is above minimum")
    func passAboveMinimum() {
        // Sample is 5 MB, minimum is 1 MB
        let check = FileSizeMinCheck(parameters: .init(minSizeMB: 1.0))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("OK"))
    }

    @Test("Fails when file is below minimum")
    func failBelowMinimum() {
        // Sample is 5 MB, minimum is 10 MB
        let check = FileSizeMinCheck(parameters: .init(minSizeMB: 10.0))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.message.contains("below"))
        #expect(result.affectedItems == [.document])
    }

    @Test("Passes when file is exactly at minimum")
    func passExactMinimum() {
        // Sample is exactly 5 MB
        let check = FileSizeMinCheck(parameters: .init(minSizeMB: 5.0))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Fails for tiny empty document")
    func failEmptyDocument() {
        // Empty doc is 1024 bytes ≈ 0.001 MB, minimum is 1 MB
        let check = FileSizeMinCheck(parameters: .init(minSizeMB: 1.0))
        let result = check.run(on: .empty)

        #expect(result.status == .fail)
        #expect(result.detail != nil)
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = FileSizeMinCheck(parameters: .init(minSizeMB: 1.0))
        #expect(check.defaultSeverity == .warning)
    }
}

// MARK: - EncryptionCheck

@Suite("EncryptionCheck")
struct EncryptionCheckTests {

    @Test("Passes when expecting unencrypted and file is unencrypted")
    func passNotEncrypted() {
        // Sample is not encrypted
        let check = EncryptionCheck(parameters: .init(expected: false))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("not encrypted"))
    }

    @Test("Fails when expecting encrypted but file is not")
    func failExpectedEncrypted() {
        let check = EncryptionCheck(parameters: .init(expected: true))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.message.contains("not encrypted"))
        #expect(result.affectedItems == [.document])
    }

    @Test("Passes when expecting encrypted and file is encrypted")
    func passEncrypted() {
        let doc = TaxiwayDocument.sample.withFileInfo { info in
            FileInfo(fileName: info.fileName, filePath: info.filePath,
                     fileSizeBytes: info.fileSizeBytes, isEncrypted: true, pageCount: info.pageCount)
        }
        let check = EncryptionCheck(parameters: .init(expected: true))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
        #expect(result.message.contains("encrypted"))
    }

    @Test("Fails when expecting unencrypted but file is encrypted")
    func failUnexpectedEncryption() {
        let doc = TaxiwayDocument.sample.withFileInfo { info in
            FileInfo(fileName: info.fileName, filePath: info.filePath,
                     fileSizeBytes: info.fileSizeBytes, isEncrypted: true, pageCount: info.pageCount)
        }
        let check = EncryptionCheck(parameters: .init(expected: false))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.message.contains("encrypted"))
    }

    @Test("Default severity is error")
    func defaultSeverity() {
        let check = EncryptionCheck(parameters: .init(expected: false))
        #expect(check.defaultSeverity == .error)
    }
}

// MARK: - InteractiveElementsCheck

@Suite("InteractiveElementsCheck")
struct InteractiveElementsCheckTests {

    @Test("Passes when no widget annotations exist")
    func passNoWidgets() {
        // Sample has no annotations
        let check = InteractiveElementsCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("No interactive"))
    }

    @Test("Fails when widget annotations exist")
    func failWithWidgets() {
        let doc = TaxiwayDocument.sample.withAnnotations([
            AnnotationInfo(type: .widget, pageIndex: 0),
            AnnotationInfo(type: .widget, pageIndex: 1),
        ])
        let check = InteractiveElementsCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.message.contains("2"))
        #expect(result.affectedItems.count == 2)
    }

    @Test("Passes when only non-widget annotations exist")
    func passNonWidgetAnnotations() {
        let doc = TaxiwayDocument.sample.withAnnotations([
            AnnotationInfo(type: .link, pageIndex: 0),
            AnnotationInfo(type: .text, pageIndex: 1),
        ])
        let check = InteractiveElementsCheck()
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Passes on empty document")
    func passEmptyDocument() {
        let check = InteractiveElementsCheck()
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = InteractiveElementsCheck()
        #expect(check.defaultSeverity == .warning)
    }
}

// MARK: - MetadataFieldPresentCheck

@Suite("MetadataFieldPresentCheck")
struct MetadataFieldPresentCheckTests {

    @Test("Passes when title is present")
    func passTitlePresent() {
        let check = MetadataFieldPresentCheck(parameters: .init(fieldName: "title"))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("title"))
    }

    @Test("Fails when title is missing")
    func failTitleMissing() {
        let check = MetadataFieldPresentCheck(parameters: .init(fieldName: "title"))
        let result = check.run(on: .empty)

        #expect(result.status == .fail)
        #expect(result.message.contains("title"))
        #expect(result.affectedItems == [.document])
    }

    @Test("Passes for author field on sample")
    func passAuthorPresent() {
        let check = MetadataFieldPresentCheck(parameters: .init(fieldName: "author"))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Fails for producer field on empty document")
    func failProducerMissing() {
        let check = MetadataFieldPresentCheck(parameters: .init(fieldName: "producer"))
        let result = check.run(on: .empty)

        #expect(result.status == .fail)
    }

    @Test("Passes for producer field on sample document")
    func passProducerPresent() {
        let check = MetadataFieldPresentCheck(parameters: .init(fieldName: "producer"))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Case-insensitive field name lookup")
    func caseInsensitive() {
        let check = MetadataFieldPresentCheck(parameters: .init(fieldName: "TITLE"))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Unknown field name fails")
    func unknownField() {
        let check = MetadataFieldPresentCheck(parameters: .init(fieldName: "nonexistent"))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
    }

    @Test("Default severity is info")
    func defaultSeverity() {
        let check = MetadataFieldPresentCheck(parameters: .init(fieldName: "title"))
        #expect(check.defaultSeverity == .info)
    }
}

// MARK: - MetadataFieldMatchesCheck

@Suite("MetadataFieldMatchesCheck")
struct MetadataFieldMatchesCheckTests {

    @Test("Passes when title matches expected value")
    func passTitleMatches() {
        let check = MetadataFieldMatchesCheck(parameters: .init(fieldName: "title", expectedValue: "Sample Brochure"))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("matches"))
    }

    @Test("Fails when title does not match")
    func failTitleMismatch() {
        let check = MetadataFieldMatchesCheck(parameters: .init(fieldName: "title", expectedValue: "Wrong Title"))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.message.contains("does not match"))
        #expect(result.detail!.contains("Wrong Title"))
        #expect(result.detail!.contains("Sample Brochure"))
        #expect(result.affectedItems == [.document])
    }

    @Test("Fails when field is missing entirely")
    func failFieldMissing() {
        let check = MetadataFieldMatchesCheck(parameters: .init(fieldName: "title", expectedValue: "Something"))
        let result = check.run(on: .empty)

        #expect(result.status == .fail)
        #expect(result.message.contains("missing"))
    }

    @Test("Matches author field")
    func passAuthorMatches() {
        let check = MetadataFieldMatchesCheck(parameters: .init(fieldName: "author", expectedValue: "Test Author"))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Matches producer field from documentInfo")
    func passProducerMatches() {
        let check = MetadataFieldMatchesCheck(parameters: .init(fieldName: "producer", expectedValue: "Adobe InDesign CC 2024"))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Unknown field name fails")
    func unknownField() {
        let check = MetadataFieldMatchesCheck(parameters: .init(fieldName: "nonexistent", expectedValue: "value"))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = MetadataFieldMatchesCheck(parameters: .init(fieldName: "title", expectedValue: "x"))
        #expect(check.defaultSeverity == .warning)
    }
}
