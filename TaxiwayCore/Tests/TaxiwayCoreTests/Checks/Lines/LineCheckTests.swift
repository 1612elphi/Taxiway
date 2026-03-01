import Testing
import Foundation
@testable import TaxiwayCore

// MARK: - StrokeWeightBelowCheck

@Suite("StrokeWeightBelowCheck")
struct StrokeWeightBelowCheckTests {

    @Test("Passes when no strokes below threshold")
    func passNoThinStrokes() {
        let doc = TaxiwayDocument.sample.withStrokeInfos([
            StrokeInfo(pageIndex: 0, lineWidth: 1.0),
            StrokeInfo(pageIndex: 1, lineWidth: 0.5),
        ])
        let check = StrokeWeightBelowCheck(parameters: .init(thresholdPt: 0.25))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
        #expect(result.message.contains("0.250"))
    }

    @Test("Fails when strokes below threshold")
    func failThinStrokes() {
        let doc = TaxiwayDocument.sample.withStrokeInfos([
            StrokeInfo(pageIndex: 0, lineWidth: 0.1),
            StrokeInfo(pageIndex: 1, lineWidth: 1.0),
        ])
        let check = StrokeWeightBelowCheck(parameters: .init(thresholdPt: 0.25))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.message.contains("1 stroke"))
        #expect(result.detail!.contains("0.100"))
        #expect(result.affectedItems == [.page(index: 0)])
    }

    @Test("Ignores zero-width strokes")
    func ignoresZeroWidth() {
        let doc = TaxiwayDocument.sample.withStrokeInfos([
            StrokeInfo(pageIndex: 0, lineWidth: 0.0),
        ])
        let check = StrokeWeightBelowCheck(parameters: .init(thresholdPt: 0.25))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Reports multiple pages with thin strokes")
    func multiplePages() {
        let doc = TaxiwayDocument.sample.withStrokeInfos([
            StrokeInfo(pageIndex: 0, lineWidth: 0.1),
            StrokeInfo(pageIndex: 1, lineWidth: 0.2),
        ])
        let check = StrokeWeightBelowCheck(parameters: .init(thresholdPt: 0.25))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 2)
    }

    @Test("Passes on empty document")
    func passEmptyDocument() {
        let check = StrokeWeightBelowCheck(parameters: .init(thresholdPt: 0.25))
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("Passes on sample document (no stroke infos)")
    func passSampleDocument() {
        let check = StrokeWeightBelowCheck(parameters: .init(thresholdPt: 0.25))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = StrokeWeightBelowCheck(parameters: .init(thresholdPt: 0.25))
        #expect(check.defaultSeverity == .warning)
    }

    @Test("Category is lines")
    func category() {
        let check = StrokeWeightBelowCheck(parameters: .init(thresholdPt: 0.25))
        #expect(check.category == .lines)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(StrokeWeightBelowCheck.typeID == "lines.stroke_below")
    }
}

// MARK: - ZeroWidthStrokeCheck

@Suite("ZeroWidthStrokeCheck")
struct ZeroWidthStrokeCheckTests {

    @Test("Passes when no zero-width strokes")
    func passNoZeroWidth() {
        let doc = TaxiwayDocument.sample.withStrokeInfos([
            StrokeInfo(pageIndex: 0, lineWidth: 0.5),
            StrokeInfo(pageIndex: 1, lineWidth: 1.0),
        ])
        let check = ZeroWidthStrokeCheck()
        let result = check.run(on: doc)

        #expect(result.status == .pass)
        #expect(result.message.contains("No zero-width"))
    }

    @Test("Fails when zero-width strokes exist")
    func failZeroWidth() {
        let doc = TaxiwayDocument.sample.withStrokeInfos([
            StrokeInfo(pageIndex: 0, lineWidth: 0.0),
            StrokeInfo(pageIndex: 1, lineWidth: 1.0),
        ])
        let check = ZeroWidthStrokeCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.message.contains("1 zero-width"))
        #expect(result.affectedItems == [.page(index: 0)])
    }

    @Test("Reports multiple pages with zero-width strokes")
    func multiplePages() {
        let doc = TaxiwayDocument.sample.withStrokeInfos([
            StrokeInfo(pageIndex: 0, lineWidth: 0.0),
            StrokeInfo(pageIndex: 1, lineWidth: 0.0),
        ])
        let check = ZeroWidthStrokeCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 2)
    }

    @Test("Passes on empty document")
    func passEmptyDocument() {
        let check = ZeroWidthStrokeCheck()
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("Passes on sample document (no stroke infos)")
    func passSampleDocument() {
        let check = ZeroWidthStrokeCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = ZeroWidthStrokeCheck()
        #expect(check.defaultSeverity == .warning)
    }

    @Test("Category is lines")
    func category() {
        let check = ZeroWidthStrokeCheck()
        #expect(check.category == .lines)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(ZeroWidthStrokeCheck.typeID == "lines.zero_width")
    }
}
