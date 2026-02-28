import Testing
import Foundation
@testable import TaxiwayCore

// MARK: - StrokeWeightBelowCheck

@Suite("StrokeWeightBelowCheck")
struct StrokeWeightBelowCheckTests {

    @Test("Always returns skipped")
    func alwaysSkipped() {
        let check = StrokeWeightBelowCheck(parameters: .init(thresholdPt: 0.25))
        let result = check.run(on: .sample)

        #expect(result.status == .skipped)
        #expect(result.message.contains("content stream parsing"))
    }

    @Test("Returns skipped on empty document")
    func skippedEmptyDocument() {
        let check = StrokeWeightBelowCheck(parameters: .init(thresholdPt: 0.5))
        let result = check.run(on: .empty)

        #expect(result.status == .skipped)
    }

    @Test("Returns skipped regardless of threshold value")
    func skippedAnyThreshold() {
        let check = StrokeWeightBelowCheck(parameters: .init(thresholdPt: 100.0))
        let result = check.run(on: .sample)

        #expect(result.status == .skipped)
        #expect(result.message.contains("deferred"))
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

    @Test("Always returns skipped")
    func alwaysSkipped() {
        let check = ZeroWidthStrokeCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .skipped)
        #expect(result.message.contains("content stream parsing"))
    }

    @Test("Returns skipped on empty document")
    func skippedEmptyDocument() {
        let check = ZeroWidthStrokeCheck()
        let result = check.run(on: .empty)

        #expect(result.status == .skipped)
    }

    @Test("Skipped message mentions deferred")
    func skippedMessageContent() {
        let check = ZeroWidthStrokeCheck()
        let result = check.run(on: .sample)

        #expect(result.message.contains("deferred"))
        #expect(result.message.contains("Zero-width"))
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
