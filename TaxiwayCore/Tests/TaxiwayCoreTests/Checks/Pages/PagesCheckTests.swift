import Testing
import Foundation
import CoreGraphics
@testable import TaxiwayCore

// MARK: - PageCountCheck

@Suite("PageCountCheck")
struct PageCountCheckTests {

    @Test("passes when page count equals target")
    func passesEquals() {
        let check = PageCountCheck(parameters: .init(operator: .equals, value: 2))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.affectedItems.isEmpty)
    }

    @Test("fails when page count does not equal target")
    func failsEquals() {
        let check = PageCountCheck(parameters: .init(operator: .equals, value: 4))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.affectedItems == [.document])
        #expect(result.message.contains("2"))
        #expect(result.message.contains("4"))
    }

    @Test("passes when page count is less than target")
    func passesLessThan() {
        let check = PageCountCheck(parameters: .init(operator: .lessThan, value: 10))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("fails when page count is not less than target")
    func failsLessThan() {
        let check = PageCountCheck(parameters: .init(operator: .lessThan, value: 2))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
    }

    @Test("passes when page count is more than target")
    func passesMoreThan() {
        let check = PageCountCheck(parameters: .init(operator: .moreThan, value: 1))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("fails when page count is not more than target")
    func failsMoreThan() {
        let check = PageCountCheck(parameters: .init(operator: .moreThan, value: 5))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
    }

    @Test("zero pages equals zero")
    func zeroPages() {
        let check = PageCountCheck(parameters: .init(operator: .equals, value: 0))
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("typeID is correct")
    func typeID() {
        #expect(PageCountCheck.typeID == "pages.count")
    }

    @Test("category is pages")
    func category() {
        let check = PageCountCheck(parameters: .init(operator: .equals, value: 1))
        #expect(check.category == .pages)
    }

    @Test("default severity is error")
    func defaultSeverity() {
        let check = PageCountCheck(parameters: .init(operator: .equals, value: 1))
        #expect(check.defaultSeverity == .error)
    }
}

// MARK: - PageSizeCheck

@Suite("PageSizeCheck")
struct PageSizeCheckTests {

    // Sample trim box: (8.504, 8.504, 578.268, 824.882)
    private static let sampleTrimWidth = 595.276 - 2 * 8.504  // 578.268
    private static let sampleTrimHeight = 841.89 - 2 * 8.504  // 824.882

    @Test("passes when all pages match target size within tolerance")
    func passesMatchingSize() {
        let check = PageSizeCheck(parameters: .init(
            targetWidthPt: Self.sampleTrimWidth,
            targetHeightPt: Self.sampleTrimHeight,
            tolerancePt: 1.0
        ))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.affectedItems.isEmpty)
    }

    @Test("fails when pages do not match target size")
    func failsMismatchedSize() {
        let check = PageSizeCheck(parameters: .init(
            targetWidthPt: 612.0,  // US Letter
            targetHeightPt: 792.0,
            tolerancePt: 1.0
        ))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 2)
    }

    @Test("passes with rotated page when dimensions are swapped")
    func passesRotatedOrientation() {
        let page = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 842, height: 595),
            trimBox: CGRect(x: 0, y: 0, width: 842, height: 595),
            bleedBox: nil,
            artBox: nil,
            rotation: 90
        )
        let doc = TaxiwayDocument.sample.withPages([page])

        // Target is portrait A4-ish, page is landscape — should still match
        let check = PageSizeCheck(parameters: .init(
            targetWidthPt: 595,
            targetHeightPt: 842,
            tolerancePt: 1.0
        ))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("passes with zero pages")
    func emptyDocument() {
        let check = PageSizeCheck(parameters: .init(
            targetWidthPt: 595,
            targetHeightPt: 842,
            tolerancePt: 1.0
        ))
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("tolerance boundary: exactly at tolerance passes")
    func toleranceBoundary() {
        let page = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 600, height: 800),
            trimBox: CGRect(x: 0, y: 0, width: 600, height: 800),
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let doc = TaxiwayDocument.sample.withPages([page])

        // Target is 601 x 801, tolerance is 1.0 — diff is exactly 1.0
        let check = PageSizeCheck(parameters: .init(
            targetWidthPt: 601,
            targetHeightPt: 801,
            tolerancePt: 1.0
        ))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("reports only mismatched pages")
    func reportsOnlyMismatchedPages() {
        let goodPage = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 600, height: 800),
            trimBox: CGRect(x: 0, y: 0, width: 600, height: 800),
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let badPage = PageInfo(
            index: 1,
            mediaBox: CGRect(x: 0, y: 0, width: 500, height: 700),
            trimBox: CGRect(x: 0, y: 0, width: 500, height: 700),
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let doc = TaxiwayDocument.sample.withPages([goodPage, badPage])

        let check = PageSizeCheck(parameters: .init(
            targetWidthPt: 600,
            targetHeightPt: 800,
            tolerancePt: 1.0
        ))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems == [.page(index: 1)])
    }

    @Test("uses effectiveTrimBox (falls back to mediaBox when trimBox is nil)")
    func usesEffectiveTrimBox() {
        let page = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 612, height: 792),
            trimBox: nil,
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = PageSizeCheck(parameters: .init(
            targetWidthPt: 612,
            targetHeightPt: 792,
            tolerancePt: 0.5
        ))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("typeID is correct")
    func typeID() {
        #expect(PageSizeCheck.typeID == "pages.size")
    }
}

// MARK: - MixedPageSizesCheck

@Suite("MixedPageSizesCheck")
struct MixedPageSizesCheckTests {

    @Test("passes when all pages have the same size")
    func passesSameSize() {
        let check = MixedPageSizesCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("fails when pages have different sizes")
    func failsDifferentSizes() {
        let page0 = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 595, height: 842),
            trimBox: CGRect(x: 0, y: 0, width: 595, height: 842),
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let page1 = PageInfo(
            index: 1,
            mediaBox: CGRect(x: 0, y: 0, width: 612, height: 792),
            trimBox: CGRect(x: 0, y: 0, width: 612, height: 792),
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let doc = TaxiwayDocument.sample.withPages([page0, page1])

        let check = MixedPageSizesCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        // Both pages should be listed as affected
        #expect(result.affectedItems.contains(.page(index: 0)))
        #expect(result.affectedItems.contains(.page(index: 1)))
    }

    @Test("passes with zero pages")
    func emptyDocument() {
        let check = MixedPageSizesCheck()
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("passes with single page")
    func singlePage() {
        let page = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 595, height: 842),
            trimBox: nil,
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = MixedPageSizesCheck()
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("passes when size difference is within 1pt tolerance")
    func withinTolerance() {
        let page0 = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 595.0, height: 842.0),
            trimBox: CGRect(x: 0, y: 0, width: 595.0, height: 842.0),
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let page1 = PageInfo(
            index: 1,
            mediaBox: CGRect(x: 0, y: 0, width: 595.5, height: 842.8),
            trimBox: CGRect(x: 0, y: 0, width: 595.5, height: 842.8),
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let doc = TaxiwayDocument.sample.withPages([page0, page1])

        let check = MixedPageSizesCheck()
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("fails when size difference exceeds 1pt")
    func exceedsTolerance() {
        let page0 = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 595.0, height: 842.0),
            trimBox: CGRect(x: 0, y: 0, width: 595.0, height: 842.0),
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let page1 = PageInfo(
            index: 1,
            mediaBox: CGRect(x: 0, y: 0, width: 597.0, height: 842.0),
            trimBox: CGRect(x: 0, y: 0, width: 597.0, height: 842.0),
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let doc = TaxiwayDocument.sample.withPages([page0, page1])

        let check = MixedPageSizesCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
    }

    @Test("typeID is correct")
    func typeID() {
        #expect(MixedPageSizesCheck.typeID == "pages.mixed_sizes")
    }

    @Test("default severity is warning")
    func defaultSeverity() {
        let check = MixedPageSizesCheck()
        #expect(check.defaultSeverity == .warning)
    }
}

// MARK: - PageRotationCheck

@Suite("PageRotationCheck")
struct PageRotationCheckTests {

    @Test("passes when no pages are rotated")
    func passesNoRotation() {
        let check = PageRotationCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.affectedItems.isEmpty)
    }

    @Test("fails when a page is rotated")
    func failsWithRotation() {
        let page0 = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 595, height: 842),
            trimBox: nil,
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let page1 = PageInfo(
            index: 1,
            mediaBox: CGRect(x: 0, y: 0, width: 595, height: 842),
            trimBox: nil,
            bleedBox: nil,
            artBox: nil,
            rotation: 90
        )
        let doc = TaxiwayDocument.sample.withPages([page0, page1])

        let check = PageRotationCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems == [.page(index: 1)])
    }

    @Test("passes with zero pages")
    func emptyDocument() {
        let check = PageRotationCheck()
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("reports multiple rotated pages")
    func multipleRotatedPages() {
        let pages = [
            PageInfo(index: 0, mediaBox: CGRect(x: 0, y: 0, width: 595, height: 842),
                     trimBox: nil, bleedBox: nil, artBox: nil, rotation: 90),
            PageInfo(index: 1, mediaBox: CGRect(x: 0, y: 0, width: 595, height: 842),
                     trimBox: nil, bleedBox: nil, artBox: nil, rotation: 180),
            PageInfo(index: 2, mediaBox: CGRect(x: 0, y: 0, width: 595, height: 842),
                     trimBox: nil, bleedBox: nil, artBox: nil, rotation: 0),
        ]
        let doc = TaxiwayDocument.sample.withPages(pages)

        let check = PageRotationCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 2)
        #expect(result.affectedItems.contains(.page(index: 0)))
        #expect(result.affectedItems.contains(.page(index: 1)))
    }

    @Test("typeID is correct")
    func typeID() {
        #expect(PageRotationCheck.typeID == "pages.rotation")
    }

    @Test("default severity is warning")
    func defaultSeverity() {
        let check = PageRotationCheck()
        #expect(check.defaultSeverity == .warning)
    }
}

// MARK: - NumericOperator

@Suite("NumericOperator")
struct NumericOperatorTests {

    @Test("Codable round-trip for all cases")
    func codableRoundTrip() throws {
        let cases: [NumericOperator] = [.equals, .lessThan, .moreThan]
        for op in cases {
            let data = try JSONEncoder().encode(op)
            let decoded = try JSONDecoder().decode(NumericOperator.self, from: data)
            #expect(decoded == op)
        }
    }

    @Test("raw values are correct")
    func rawValues() {
        #expect(NumericOperator.equals.rawValue == "equals")
        #expect(NumericOperator.lessThan.rawValue == "less_than")
        #expect(NumericOperator.moreThan.rawValue == "more_than")
    }
}
