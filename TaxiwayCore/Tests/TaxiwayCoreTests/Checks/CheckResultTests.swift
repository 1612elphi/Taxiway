import Testing
import Foundation
@testable import TaxiwayCore

@Suite("CheckResult & Supporting Types")
struct CheckResultTests {

    // MARK: - CheckSeverity

    @Test("CheckSeverity ordering: error < warning < info")
    func severityOrdering() {
        #expect(CheckSeverity.error < CheckSeverity.warning)
        #expect(CheckSeverity.warning < CheckSeverity.info)
        #expect(CheckSeverity.error < CheckSeverity.info)
    }

    @Test("CheckSeverity Comparable: sorted array matches expected order")
    func severitySorting() {
        let unsorted: [CheckSeverity] = [.info, .error, .warning]
        let sorted = unsorted.sorted()
        #expect(sorted == [.error, .warning, .info])
    }

    @Test("CheckSeverity is not equal across different cases")
    func severityInequality() {
        #expect(CheckSeverity.error != CheckSeverity.warning)
        #expect(CheckSeverity.warning != CheckSeverity.info)
    }

    @Test("CheckSeverity Codable round-trip")
    func severityCodable() throws {
        for severity in CheckSeverity.allCases {
            let data = try JSONEncoder().encode(severity)
            let decoded = try JSONDecoder().decode(CheckSeverity.self, from: data)
            #expect(decoded == severity)
        }
    }

    @Test("CheckSeverity has exactly 3 cases")
    func severityCaseCount() {
        #expect(CheckSeverity.allCases.count == 3)
    }

    // MARK: - CheckStatus

    @Test("CheckStatus all 4 cases encode/decode correctly")
    func statusCodable() throws {
        let allStatuses: [CheckStatus] = [.pass, .fail, .warning, .skipped]
        for status in allStatuses {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(CheckStatus.self, from: data)
            #expect(decoded == status)
        }
    }

    @Test("CheckStatus raw values are lowercase strings")
    func statusRawValues() {
        #expect(CheckStatus.pass.rawValue == "pass")
        #expect(CheckStatus.fail.rawValue == "fail")
        #expect(CheckStatus.warning.rawValue == "warning")
        #expect(CheckStatus.skipped.rawValue == "skipped")
    }

    // MARK: - CheckCategory

    @Test("CheckCategory has exactly 8 cases")
    func categoryCaseCount() {
        #expect(CheckCategory.allCases.count == 8)
    }

    @Test("CheckCategory contains all expected cases")
    func categoryExpectedCases() {
        let expected: Set<CheckCategory> = [.file, .pdf, .pages, .marks, .colour, .fonts, .images, .lines]
        let actual = Set(CheckCategory.allCases)
        #expect(actual == expected)
    }

    @Test("CheckCategory Codable round-trip")
    func categoryCodable() throws {
        for category in CheckCategory.allCases {
            let data = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(CheckCategory.self, from: data)
            #expect(decoded == category)
        }
    }

    // MARK: - AffectedItem

    @Test("AffectedItem.document encodes/decodes")
    func affectedItemDocument() throws {
        let item = AffectedItem.document
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(AffectedItem.self, from: data)
        #expect(decoded == item)
    }

    @Test("AffectedItem.page encodes/decodes with index")
    func affectedItemPage() throws {
        let item = AffectedItem.page(index: 3)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(AffectedItem.self, from: data)
        #expect(decoded == item)
    }

    @Test("AffectedItem.font encodes/decodes with name and pages")
    func affectedItemFont() throws {
        let item = AffectedItem.font(name: "Helvetica", pages: [0, 1, 5])
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(AffectedItem.self, from: data)
        #expect(decoded == item)
    }

    @Test("AffectedItem.image encodes/decodes")
    func affectedItemImage() throws {
        let item = AffectedItem.image(id: "img_0_1", page: 0)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(AffectedItem.self, from: data)
        #expect(decoded == item)
    }

    @Test("AffectedItem.colourSpace encodes/decodes")
    func affectedItemColourSpace() throws {
        let item = AffectedItem.colourSpace(name: "DeviceCMYK", pages: [0, 2])
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(AffectedItem.self, from: data)
        #expect(decoded == item)
    }

    @Test("AffectedItem.annotation encodes/decodes")
    func affectedItemAnnotation() throws {
        let item = AffectedItem.annotation(type: "Link", page: 1)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(AffectedItem.self, from: data)
        #expect(decoded == item)
    }

    @Test("AffectedItem.textFrame encodes/decodes")
    func affectedItemTextFrame() throws {
        let item = AffectedItem.textFrame(id: "txt_0_0", page: 0,
                                          bounds: AnnotationBounds(x: 50, y: 700, width: 200, height: 14))
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(AffectedItem.self, from: data)
        #expect(decoded == item)
    }

    @Test("AffectedItem.textFrame encodes/decodes without bounds")
    func affectedItemTextFrameNoBounds() throws {
        let item = AffectedItem.textFrame(id: "txt_1_2", page: 1)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(AffectedItem.self, from: data)
        #expect(decoded == item)
    }

    // MARK: - CheckResult

    @Test("CheckResult Codable round-trip with all fields")
    func checkResultFullRoundTrip() throws {
        let id = UUID()
        let result = CheckResult(
            checkID: id,
            checkTypeID: "file.size.max",
            status: .fail,
            severity: .error,
            message: "File too large",
            detail: "File is 15.0 MB",
            affectedItems: [.document, .page(index: 0)]
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(CheckResult.self, from: data)

        #expect(decoded == result)
        #expect(decoded.checkID == id)
        #expect(decoded.checkTypeID == "file.size.max")
        #expect(decoded.status == .fail)
        #expect(decoded.severity == .error)
        #expect(decoded.message == "File too large")
        #expect(decoded.detail == "File is 15.0 MB")
        #expect(decoded.affectedItems.count == 2)
    }

    @Test("CheckResult Codable round-trip with nil detail and empty affectedItems")
    func checkResultMinimalRoundTrip() throws {
        let result = CheckResult(
            checkID: UUID(),
            checkTypeID: "test.check",
            status: .pass,
            severity: .info,
            message: "All good"
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(CheckResult.self, from: data)

        #expect(decoded == result)
        #expect(decoded.detail == nil)
        #expect(decoded.affectedItems.isEmpty)
    }

    @Test("CheckResult id property returns checkID")
    func checkResultIdentifiable() {
        let uuid = UUID()
        let result = CheckResult(
            checkID: uuid,
            checkTypeID: "test",
            status: .pass,
            severity: .info,
            message: "OK"
        )
        #expect(result.id == uuid)
    }
}
