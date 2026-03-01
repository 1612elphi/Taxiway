import Testing
import Foundation
import CoreGraphics
@testable import TaxiwayCore

// MARK: - Helper

/// Creates a PageInfo with specific bleed margins (in points) around a standard trim box.
private func pageWithBleed(index: Int, left: Double, right: Double, top: Double, bottom: Double,
                           trimWidth: Double = 595, trimHeight: Double = 842) -> PageInfo {
    let trimBox = CGRect(x: left, y: bottom, width: trimWidth, height: trimHeight)
    let mediaBox = CGRect(x: 0, y: 0, width: trimWidth + left + right, height: trimHeight + top + bottom)
    let bleedBox = mediaBox
    return PageInfo(index: index, mediaBox: mediaBox, trimBox: trimBox, bleedBox: bleedBox, artBox: nil, rotation: 0)
}

/// Creates a PageInfo with no bleed box at all.
private func pageWithNoBleedBox(index: Int) -> PageInfo {
    let mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
    return PageInfo(index: index, mediaBox: mediaBox, trimBox: mediaBox, bleedBox: nil, artBox: nil, rotation: 0)
}

/// Creates a PageInfo with no trim box.
private func pageWithNoTrimBox(index: Int) -> PageInfo {
    let mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
    return PageInfo(index: index, mediaBox: mediaBox, trimBox: nil, bleedBox: nil, artBox: nil, rotation: 0)
}

private let mmToPoints = 72.0 / 25.4

// MARK: - BleedZeroCheck

@Suite("BleedZeroCheck")
struct BleedZeroCheckTests {

    @Test("passes when all pages have bleed")
    func passesWithBleed() {
        // Sample document has ~8.5pt bleed on all sides
        let check = BleedZeroCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("fails when a page has zero bleed (no bleed box)")
    func failsNoBleedBox() {
        let page = pageWithNoBleedBox(index: 0)
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = BleedZeroCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems == [.page(index: 0)])
    }

    @Test("fails when bleed box equals trim box (zero margins)")
    func failsBleedEqualsTrim() {
        let trim = CGRect(x: 10, y: 10, width: 575, height: 822)
        let page = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 595, height: 842),
            trimBox: trim,
            bleedBox: trim,  // bleed = trim means zero margins
            artBox: nil,
            rotation: 0
        )
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = BleedZeroCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems == [.page(index: 0)])
    }

    @Test("passes with zero pages")
    func emptyDocument() {
        let check = BleedZeroCheck()
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("reports multiple pages with zero bleed")
    func multipleZeroBleedPages() {
        let pages = [
            pageWithNoBleedBox(index: 0),
            pageWithBleed(index: 1, left: 8, right: 8, top: 8, bottom: 8),
            pageWithNoBleedBox(index: 2),
        ]
        let doc = TaxiwayDocument.sample.withPages(pages)

        let check = BleedZeroCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 2)
        #expect(result.affectedItems.contains(.page(index: 0)))
        #expect(result.affectedItems.contains(.page(index: 2)))
    }

    @Test("typeID is correct")
    func typeID() {
        #expect(BleedZeroCheck.typeID == "marks.bleed_zero")
    }

    @Test("default severity is error")
    func defaultSeverity() {
        let check = BleedZeroCheck()
        #expect(check.defaultSeverity == .error)
    }
}

// MARK: - BleedNonZeroCheck

@Suite("BleedNonZeroCheck")
struct BleedNonZeroCheckTests {

    @Test("passes when no pages have bleed")
    func passesNoBleed() {
        let pages = [
            pageWithNoBleedBox(index: 0),
            pageWithNoBleedBox(index: 1),
        ]
        let doc = TaxiwayDocument.sample.withPages(pages)

        let check = BleedNonZeroCheck()
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("fails when a page has non-zero bleed")
    func failsWithBleed() {
        // Sample has bleed on both pages
        let check = BleedNonZeroCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 2)
    }

    @Test("passes with zero pages")
    func emptyDocument() {
        let check = BleedNonZeroCheck()
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("reports only pages with non-zero bleed")
    func reportsOnlyNonZero() {
        let pages = [
            pageWithNoBleedBox(index: 0),
            pageWithBleed(index: 1, left: 5, right: 5, top: 5, bottom: 5),
            pageWithNoBleedBox(index: 2),
        ]
        let doc = TaxiwayDocument.sample.withPages(pages)

        let check = BleedNonZeroCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems == [.page(index: 1)])
    }

    @Test("typeID is correct")
    func typeID() {
        #expect(BleedNonZeroCheck.typeID == "marks.bleed_nonzero")
    }

    @Test("default severity is warning")
    func defaultSeverity() {
        let check = BleedNonZeroCheck()
        #expect(check.defaultSeverity == .warning)
    }
}

// MARK: - BleedLessThanCheck

@Suite("BleedLessThanCheck")
struct BleedLessThanCheckTests {

    @Test("passes when all bleed margins meet minimum (sample has ~3mm)")
    func passesSufficientBleed() {
        let check = BleedLessThanCheck(parameters: .init(thresholdMM: 3.0))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("fails when bleed is non-zero but below threshold")
    func failsInsufficientBleed() {
        // 1mm bleed = ~2.835pt
        let bleedPt = 1.0 * mmToPoints
        let page = pageWithBleed(index: 0, left: bleedPt, right: bleedPt, top: bleedPt, bottom: bleedPt)
        let doc = TaxiwayDocument.sample.withPages([page])

        // Threshold is 3mm — 1mm bleed should fail
        let check = BleedLessThanCheck(parameters: .init(thresholdMM: 3.0))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems == [.page(index: 0)])
    }

    @Test("does not flag pages with zero bleed (zero is not 'less than')")
    func ignoresZeroBleed() {
        let page = pageWithNoBleedBox(index: 0)
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = BleedLessThanCheck(parameters: .init(thresholdMM: 3.0))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("passes with zero pages")
    func emptyDocument() {
        let check = BleedLessThanCheck(parameters: .init(thresholdMM: 3.0))
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("fails when only one side is insufficient")
    func oneSideInsufficient() {
        // 3 sides have 5mm, one side has 1mm
        let page = pageWithBleed(
            index: 0,
            left: 5.0 * mmToPoints,
            right: 5.0 * mmToPoints,
            top: 5.0 * mmToPoints,
            bottom: 1.0 * mmToPoints
        )
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = BleedLessThanCheck(parameters: .init(thresholdMM: 3.0))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems == [.page(index: 0)])
    }

    @Test("typeID is correct")
    func typeID() {
        #expect(BleedLessThanCheck.typeID == "marks.bleed_less_than")
    }
}

// MARK: - BleedGreaterThanCheck

@Suite("BleedGreaterThanCheck")
struct BleedGreaterThanCheckTests {

    @Test("passes when all bleed is within threshold")
    func passesWithinThreshold() {
        // 3mm bleed, threshold 5mm
        let bleedPt = 3.0 * mmToPoints
        let page = pageWithBleed(index: 0, left: bleedPt, right: bleedPt, top: bleedPt, bottom: bleedPt)
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = BleedGreaterThanCheck(parameters: .init(thresholdMM: 5.0))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("fails when bleed exceeds threshold")
    func failsExcessiveBleed() {
        // 10mm bleed, threshold 5mm
        let bleedPt = 10.0 * mmToPoints
        let page = pageWithBleed(index: 0, left: bleedPt, right: bleedPt, top: bleedPt, bottom: bleedPt)
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = BleedGreaterThanCheck(parameters: .init(thresholdMM: 5.0))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems == [.page(index: 0)])
    }

    @Test("passes with zero pages")
    func emptyDocument() {
        let check = BleedGreaterThanCheck(parameters: .init(thresholdMM: 5.0))
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("does not flag zero bleed pages")
    func zeroBleedNotFlagged() {
        let page = pageWithNoBleedBox(index: 0)
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = BleedGreaterThanCheck(parameters: .init(thresholdMM: 5.0))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("fails when only one side exceeds threshold")
    func oneSideExcessive() {
        let page = pageWithBleed(
            index: 0,
            left: 3.0 * mmToPoints,
            right: 3.0 * mmToPoints,
            top: 3.0 * mmToPoints,
            bottom: 10.0 * mmToPoints
        )
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = BleedGreaterThanCheck(parameters: .init(thresholdMM: 5.0))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
    }

    @Test("typeID is correct")
    func typeID() {
        #expect(BleedGreaterThanCheck.typeID == "marks.bleed_greater_than")
    }
}

// MARK: - BleedNonUniformCheck

@Suite("BleedNonUniformCheck")
struct BleedNonUniformCheckTests {

    @Test("passes when bleed is uniform on all sides")
    func passesUniform() {
        // Sample has ~8.504pt bleed on all sides (uniform)
        let check = BleedNonUniformCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("fails when bleed margins differ beyond tolerance")
    func failsNonUniform() {
        // Left/right: 3mm, top/bottom: 5mm — difference is 2mm, default tolerance is 0.5mm
        let page = pageWithBleed(
            index: 0,
            left: 3.0 * mmToPoints,
            right: 3.0 * mmToPoints,
            top: 5.0 * mmToPoints,
            bottom: 5.0 * mmToPoints
        )
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = BleedNonUniformCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems == [.page(index: 0)])
    }

    @Test("passes when margins differ within tolerance")
    func passesWithinTolerance() {
        // All sides ~3mm, with 0.3mm variation — within 0.5mm tolerance
        let base = 3.0 * mmToPoints
        let page = pageWithBleed(
            index: 0,
            left: base,
            right: base + 0.3 * mmToPoints,
            top: base + 0.1 * mmToPoints,
            bottom: base + 0.2 * mmToPoints
        )
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = BleedNonUniformCheck()
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("passes with zero pages")
    func emptyDocument() {
        let check = BleedNonUniformCheck()
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("custom tolerance parameter works")
    func customTolerance() {
        // Margins differ by 2mm, tolerance is 3mm — should pass
        let page = pageWithBleed(
            index: 0,
            left: 3.0 * mmToPoints,
            right: 3.0 * mmToPoints,
            top: 5.0 * mmToPoints,
            bottom: 5.0 * mmToPoints
        )
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = BleedNonUniformCheck(parameters: .init(toleranceMM: 3.0))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("zero bleed on all sides is considered uniform")
    func zeroBleedIsUniform() {
        let page = pageWithNoBleedBox(index: 0)
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = BleedNonUniformCheck()
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("typeID is correct")
    func typeID() {
        #expect(BleedNonUniformCheck.typeID == "marks.bleed_non_uniform")
    }

    @Test("default severity is warning")
    func defaultSeverity() {
        let check = BleedNonUniformCheck()
        #expect(check.defaultSeverity == .warning)
    }
}

// MARK: - TrimBoxSetCheck

@Suite("TrimBoxSetCheck")
struct TrimBoxSetCheckTests {

    @Test("passes when all pages have trim box")
    func passesAllHaveTrimBox() {
        // Sample pages have trim boxes
        let check = TrimBoxSetCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("fails when a page has no trim box")
    func failsMissingTrimBox() {
        let page = pageWithNoTrimBox(index: 0)
        let doc = TaxiwayDocument.sample.withPages([page])

        let check = TrimBoxSetCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems == [.page(index: 0)])
    }

    @Test("passes with zero pages")
    func emptyDocument() {
        let check = TrimBoxSetCheck()
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("reports only pages missing trim box")
    func reportsOnlyMissing() {
        let pages = [
            PageInfo(index: 0, mediaBox: CGRect(x: 0, y: 0, width: 595, height: 842),
                     trimBox: CGRect(x: 0, y: 0, width: 595, height: 842),
                     bleedBox: nil, artBox: nil, rotation: 0),
            pageWithNoTrimBox(index: 1),
            PageInfo(index: 2, mediaBox: CGRect(x: 0, y: 0, width: 595, height: 842),
                     trimBox: CGRect(x: 0, y: 0, width: 595, height: 842),
                     bleedBox: nil, artBox: nil, rotation: 0),
            pageWithNoTrimBox(index: 3),
        ]
        let doc = TaxiwayDocument.sample.withPages(pages)

        let check = TrimBoxSetCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 2)
        #expect(result.affectedItems.contains(.page(index: 1)))
        #expect(result.affectedItems.contains(.page(index: 3)))
    }

    @Test("typeID is correct")
    func typeID() {
        #expect(TrimBoxSetCheck.typeID == "marks.trim_box_set")
    }

    @Test("default severity is error")
    func defaultSeverity() {
        let check = TrimBoxSetCheck()
        #expect(check.defaultSeverity == .error)
    }
}

// MARK: - ArtSlugBoxCheck

@Suite("ArtSlugBoxCheck")
struct ArtSlugBoxCheckTests {

    @Test("Passes when no art box set with operator .is")
    func passNoArtBoxIs() {
        // Sample pages have artBox: nil
        let check = ArtSlugBoxCheck(parameters: .init(operator: .is))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("No art box"))
    }

    @Test("Fails when art box set with operator .is")
    func failArtBoxSetIs() {
        let mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
        let artBox = CGRect(x: 10, y: 10, width: 575, height: 822)
        let doc = TaxiwayDocument.sample.withPages([
            PageInfo(index: 0, mediaBox: mediaBox, trimBox: mediaBox, bleedBox: nil, artBox: artBox, rotation: 0),
        ])
        let check = ArtSlugBoxCheck(parameters: .init(operator: .is))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.message.contains("1 page"))
        #expect(result.affectedItems == [.page(index: 0)])
    }

    @Test("Fails when no art box set with operator .isNot")
    func failNoArtBoxIsNot() {
        let check = ArtSlugBoxCheck(parameters: .init(operator: .isNot))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.message.contains("missing art box"))
    }

    @Test("Passes when all pages have art box with operator .isNot")
    func passAllHaveArtBox() {
        let mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
        let artBox = CGRect(x: 10, y: 10, width: 575, height: 822)
        let doc = TaxiwayDocument.sample.withPages([
            PageInfo(index: 0, mediaBox: mediaBox, trimBox: mediaBox, bleedBox: nil, artBox: artBox, rotation: 0),
            PageInfo(index: 1, mediaBox: mediaBox, trimBox: mediaBox, bleedBox: nil, artBox: artBox, rotation: 0),
        ])
        let check = ArtSlugBoxCheck(parameters: .init(operator: .isNot))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
        #expect(result.message.contains("All pages have art box"))
    }

    @Test("Passes on empty document with operator .is")
    func passEmptyIs() {
        let check = ArtSlugBoxCheck(parameters: .init(operator: .is))
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("TypeID is marks.art_slug_box")
    func typeID() {
        #expect(ArtSlugBoxCheck.typeID == "marks.art_slug_box")
    }

    @Test("Default severity is info")
    func defaultSeverity() {
        let check = ArtSlugBoxCheck(parameters: .init(operator: .is))
        #expect(check.defaultSeverity == .info)
    }
}
