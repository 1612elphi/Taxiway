import Testing
import Foundation
@testable import TaxiwayCore

@Suite("Colour Checks")
struct ColourCheckTests {

    // MARK: - ColourSpaceUsedCheck

    @Suite("ColourSpaceUsedCheck")
    struct ColourSpaceUsedCheckTests {

        @Test("Passes when colour space not found with operator .is")
        func passWhenNotFound() {
            let doc = TaxiwayDocument.sample.withColourSpaces([
                ColourSpaceInfo(name: .deviceCMYK, pagesUsedOn: [0]),
            ])
            let check = ColourSpaceUsedCheck(parameters: .init(colourSpace: .deviceRGB, operator: .is))
            let result = check.run(on: doc)

            #expect(result.status == .pass)
            #expect(result.message.contains("DeviceRGB"))
            #expect(result.message.contains("not found"))
        }

        @Test("Fails when colour space found with operator .is")
        func failWhenFound() {
            let check = ColourSpaceUsedCheck(parameters: .init(colourSpace: .deviceRGB, operator: .is))
            let result = check.run(on: .sample)

            #expect(result.status == .fail)
            #expect(result.message.contains("DeviceRGB"))
            #expect(result.message.contains("detected"))
            #expect(!result.affectedItems.isEmpty)
        }

        @Test("Passes when colour space found with operator .isNot")
        func passWhenFoundIsNot() {
            let check = ColourSpaceUsedCheck(parameters: .init(colourSpace: .deviceCMYK, operator: .isNot))
            let result = check.run(on: .sample)

            #expect(result.status == .pass)
            #expect(result.message.contains("DeviceCMYK"))
            #expect(result.message.contains("present"))
        }

        @Test("Fails when colour space not found with operator .isNot")
        func failWhenNotFoundIsNot() {
            let doc = TaxiwayDocument.sample.withColourSpaces([
                ColourSpaceInfo(name: .deviceCMYK, pagesUsedOn: [0]),
            ])
            let check = ColourSpaceUsedCheck(parameters: .init(colourSpace: .deviceRGB, operator: .isNot))
            let result = check.run(on: doc)

            #expect(result.status == .fail)
            #expect(result.message.contains("DeviceRGB"))
            #expect(result.message.contains("not found"))
            #expect(result.affectedItems == [.document])
        }

        @Test("Reports affected colour space with correct pages")
        func affectedItemPages() {
            let doc = TaxiwayDocument.sample.withColourSpaces([
                ColourSpaceInfo(name: .deviceRGB, pagesUsedOn: [0, 2]),
            ])
            let check = ColourSpaceUsedCheck(parameters: .init(colourSpace: .deviceRGB, operator: .is))
            let result = check.run(on: doc)

            #expect(result.status == .fail)
            #expect(result.affectedItems == [.colourSpace(name: "DeviceRGB", pages: [0, 2])])
            #expect(result.detail?.contains("1") == true)
            #expect(result.detail?.contains("3") == true)
        }

        @Test("Passes on empty document with operator .is")
        func passOnEmptyDocument() {
            let check = ColourSpaceUsedCheck(parameters: .init(colourSpace: .deviceRGB, operator: .is))
            let result = check.run(on: .empty)

            #expect(result.status == .pass)
        }

        @Test("Category is colour")
        func category() {
            let check = ColourSpaceUsedCheck(parameters: .init(colourSpace: .deviceRGB, operator: .is))
            #expect(check.category == .colour)
        }

        @Test("Default severity is warning")
        func defaultSeverity() {
            let check = ColourSpaceUsedCheck(parameters: .init(colourSpace: .deviceRGB, operator: .is))
            #expect(check.defaultSeverity == .warning)
        }

        @Test("TypeID is colour.space_used")
        func typeID() {
            #expect(ColourSpaceUsedCheck.typeID == "colour.space_used")
        }
    }

    // MARK: - RegistrationColourCheck

    @Suite("RegistrationColourCheck")
    struct RegistrationColourCheckTests {

        @Test("Passes with normal spot colours")
        func passWithNormalSpots() {
            let check = RegistrationColourCheck()
            let result = check.run(on: .sample)

            #expect(result.status == .pass)
            #expect(result.message.contains("No registration"))
        }

        @Test("Fails when 'All' spot colour present")
        func failWithRegistrationColour() {
            let doc = TaxiwayDocument.sample.withSpotColours([
                SpotColourInfo(name: "PANTONE 485 C", pagesUsedOn: [0]),
                SpotColourInfo(name: "All", pagesUsedOn: [0, 1]),
            ])
            let check = RegistrationColourCheck()
            let result = check.run(on: doc)

            #expect(result.status == .fail)
            #expect(result.message.contains("Registration colour"))
            #expect(result.detail?.contains("1") == true)
            #expect(result.detail?.contains("2") == true)
        }

        @Test("Passes on empty document")
        func passOnEmptyDocument() {
            let check = RegistrationColourCheck()
            let result = check.run(on: .empty)

            #expect(result.status == .pass)
        }

        @Test("Passes when spot colours exist but none named 'All'")
        func passWithNonRegistrationSpots() {
            let doc = TaxiwayDocument.sample.withSpotColours([
                SpotColourInfo(name: "PANTONE 485 C", pagesUsedOn: [0]),
                SpotColourInfo(name: "Spot Blue", pagesUsedOn: [1]),
            ])
            let check = RegistrationColourCheck()
            let result = check.run(on: doc)

            #expect(result.status == .pass)
        }

        @Test("TypeID is colour.registration")
        func typeID() {
            #expect(RegistrationColourCheck.typeID == "colour.registration")
        }

        @Test("Default severity is warning")
        func defaultSeverity() {
            let check = RegistrationColourCheck()
            #expect(check.defaultSeverity == .warning)
        }
    }

    // MARK: - SpotColourUsedCheck

    @Suite("SpotColourUsedCheck")
    struct SpotColourUsedCheckTests {

        @Test("Passes with no spot colours")
        func passWithNoSpots() {
            let doc = TaxiwayDocument.sample.withSpotColours([])
            let check = SpotColourUsedCheck()
            let result = check.run(on: doc)

            #expect(result.status == .pass)
            #expect(result.message.contains("No spot colours"))
        }

        @Test("Fails when spot colours present")
        func failWithSpots() {
            let check = SpotColourUsedCheck()
            let result = check.run(on: .sample)

            #expect(result.status == .fail)
            #expect(result.message.contains("1 spot colour"))
            #expect(result.detail?.contains("PANTONE 485 C") == true)
        }

        @Test("Fails with multiple spot colours and lists all names")
        func failWithMultipleSpots() {
            let doc = TaxiwayDocument.sample.withSpotColours([
                SpotColourInfo(name: "PANTONE 485 C", pagesUsedOn: [0]),
                SpotColourInfo(name: "PANTONE 300 C", pagesUsedOn: [1]),
                SpotColourInfo(name: "Gold Metallic", pagesUsedOn: [0, 1]),
            ])
            let check = SpotColourUsedCheck()
            let result = check.run(on: doc)

            #expect(result.status == .fail)
            #expect(result.message.contains("3 spot colour"))
            #expect(result.detail?.contains("PANTONE 485 C") == true)
            #expect(result.detail?.contains("PANTONE 300 C") == true)
            #expect(result.detail?.contains("Gold Metallic") == true)
        }

        @Test("Passes on empty document")
        func passOnEmptyDocument() {
            let check = SpotColourUsedCheck()
            let result = check.run(on: .empty)

            #expect(result.status == .pass)
        }

        @Test("TypeID is colour.spot_used")
        func typeID() {
            #expect(SpotColourUsedCheck.typeID == "colour.spot_used")
        }

        @Test("Default severity is info")
        func defaultSeverity() {
            let check = SpotColourUsedCheck()
            #expect(check.defaultSeverity == .info)
        }
    }

    // MARK: - SpotColourCountCheck

    @Suite("SpotColourCountCheck")
    struct SpotColourCountCheckTests {

        @Test("Passes when under max count")
        func passUnderLimit() {
            let check = SpotColourCountCheck(parameters: .init(maxCount: 5))
            let result = check.run(on: .sample) // 1 spot colour

            #expect(result.status == .pass)
            #expect(result.message.contains("OK"))
            #expect(result.message.contains("1"))
        }

        @Test("Passes when exactly at max count")
        func passAtExactLimit() {
            let doc = TaxiwayDocument.sample.withSpotColours([
                SpotColourInfo(name: "PANTONE 485 C", pagesUsedOn: [0]),
                SpotColourInfo(name: "PANTONE 300 C", pagesUsedOn: [1]),
            ])
            let check = SpotColourCountCheck(parameters: .init(maxCount: 2))
            let result = check.run(on: doc)

            #expect(result.status == .pass)
        }

        @Test("Fails when over max count")
        func failOverLimit() {
            let doc = TaxiwayDocument.sample.withSpotColours([
                SpotColourInfo(name: "Spot 1", pagesUsedOn: [0]),
                SpotColourInfo(name: "Spot 2", pagesUsedOn: [0]),
                SpotColourInfo(name: "Spot 3", pagesUsedOn: [1]),
                SpotColourInfo(name: "Spot 4", pagesUsedOn: [1]),
                SpotColourInfo(name: "Spot 5", pagesUsedOn: [0]),
                SpotColourInfo(name: "Spot 6", pagesUsedOn: [1]),
            ])
            let check = SpotColourCountCheck(parameters: .init(maxCount: 5))
            let result = check.run(on: doc)

            #expect(result.status == .fail)
            #expect(result.message.contains("6"))
            #expect(result.message.contains("5"))
        }

        @Test("Passes with zero spot colours and max 0")
        func passWithZeroSpotsMaxZero() {
            let doc = TaxiwayDocument.sample.withSpotColours([])
            let check = SpotColourCountCheck(parameters: .init(maxCount: 0))
            let result = check.run(on: doc)

            #expect(result.status == .pass)
        }

        @Test("Fails with one spot colour and max 0")
        func failWithOneSpotMaxZero() {
            let check = SpotColourCountCheck(parameters: .init(maxCount: 0))
            let result = check.run(on: .sample) // 1 spot colour

            #expect(result.status == .fail)
        }

        @Test("Passes on empty document")
        func passOnEmptyDocument() {
            let check = SpotColourCountCheck(parameters: .init(maxCount: 5))
            let result = check.run(on: .empty)

            #expect(result.status == .pass)
        }

        @Test("TypeID is colour.spot_count")
        func typeID() {
            #expect(SpotColourCountCheck.typeID == "colour.spot_count")
        }

        @Test("Default severity is warning")
        func defaultSeverity() {
            let check = SpotColourCountCheck(parameters: .init(maxCount: 5))
            #expect(check.defaultSeverity == .warning)
        }
    }

    // MARK: - UnnamedSpotColourCheck

    @Suite("UnnamedSpotColourCheck")
    struct UnnamedSpotColourCheckTests {

        @Test("Passes when all spot colours have names")
        func passWithNamedSpots() {
            let check = UnnamedSpotColourCheck()
            let result = check.run(on: .sample)

            #expect(result.status == .pass)
            #expect(result.message.contains("No unnamed"))
        }

        @Test("Fails when spot colour has empty name")
        func failWithEmptyName() {
            let doc = TaxiwayDocument.sample.withSpotColours([
                SpotColourInfo(name: "", pagesUsedOn: [0]),
                SpotColourInfo(name: "PANTONE 485 C", pagesUsedOn: [1]),
            ])
            let check = UnnamedSpotColourCheck()
            let result = check.run(on: doc)

            #expect(result.status == .fail)
            #expect(result.message.contains("1 unnamed"))
        }

        @Test("Fails when spot colour has whitespace-only name")
        func failWithWhitespaceName() {
            let doc = TaxiwayDocument.sample.withSpotColours([
                SpotColourInfo(name: "   ", pagesUsedOn: [0]),
            ])
            let check = UnnamedSpotColourCheck()
            let result = check.run(on: doc)

            #expect(result.status == .fail)
        }

        @Test("Passes on empty document")
        func passOnEmptyDocument() {
            let check = UnnamedSpotColourCheck()
            let result = check.run(on: .empty)

            #expect(result.status == .pass)
        }

        @Test("TypeID is colour.unnamed_spot")
        func typeID() {
            #expect(UnnamedSpotColourCheck.typeID == "colour.unnamed_spot")
        }

        @Test("Default severity is warning")
        func defaultSeverity() {
            let check = UnnamedSpotColourCheck()
            #expect(check.defaultSeverity == .warning)
        }
    }

    // MARK: - RichBlackCheck

    @Suite("RichBlackCheck")
    struct RichBlackCheckTests {

        @Test("Passes when no rich black present")
        func passNoRichBlack() {
            // Sample has pure black (0,0,0,1) — K=100% but C/M/Y all 0
            let check = RichBlackCheck()
            let result = check.run(on: .sample)

            #expect(result.status == .pass)
            #expect(result.message.contains("No rich black"))
        }

        @Test("Fails when rich black detected")
        func failWithRichBlack() {
            let doc = TaxiwayDocument.sample.withColourUsages([
                ColourUsageInfo(
                    id: "cmyk:60,40,40,100",
                    name: "Rich Black",
                    colourType: .process,
                    mode: .cmyk,
                    components: [0.6, 0.4, 0.4, 1.0],
                    inkSum: 240,
                    usageContexts: [.textFill],
                    pagesUsedOn: [0]
                ),
            ])
            let check = RichBlackCheck()
            let result = check.run(on: doc)

            #expect(result.status == .fail)
            #expect(result.message.contains("1 rich black"))
        }

        @Test("Passes with pure K-only black")
        func passWithPureBlack() {
            let doc = TaxiwayDocument.sample.withColourUsages([
                ColourUsageInfo(
                    id: "cmyk:0,0,0,100",
                    name: "[Black]",
                    colourType: .process,
                    mode: .cmyk,
                    components: [0, 0, 0, 1.0],
                    inkSum: 100,
                    usageContexts: [.textFill],
                    pagesUsedOn: [0]
                ),
            ])
            let check = RichBlackCheck()
            let result = check.run(on: doc)

            #expect(result.status == .pass)
        }

        @Test("Ignores non-CMYK colours")
        func ignoresNonCMYK() {
            let doc = TaxiwayDocument.sample.withColourUsages([
                ColourUsageInfo(
                    id: "rgb:0,0,0",
                    name: "RGB Black",
                    colourType: .process,
                    mode: .rgb,
                    components: [0, 0, 0],
                    inkSum: nil,
                    usageContexts: [.textFill],
                    pagesUsedOn: [0]
                ),
            ])
            let check = RichBlackCheck()
            let result = check.run(on: doc)

            #expect(result.status == .pass)
        }

        @Test("Passes on empty document")
        func passOnEmptyDocument() {
            let check = RichBlackCheck()
            let result = check.run(on: .empty)

            #expect(result.status == .pass)
        }

        @Test("TypeID is colour.rich_black")
        func typeID() {
            #expect(RichBlackCheck.typeID == "colour.rich_black")
        }
    }

    // MARK: - InkCoverageCheck

    @Suite("InkCoverageCheck")
    struct InkCoverageCheckTests {

        @Test("Passes when all ink sums below threshold")
        func passUnderThreshold() {
            // Sample has [Black] at 100% ink sum
            let check = InkCoverageCheck(parameters: .init(thresholdPercent: 300, operator: .moreThan))
            let result = check.run(on: .sample)

            #expect(result.status == .pass)
        }

        @Test("Fails when ink sum exceeds threshold")
        func failOverThreshold() {
            let doc = TaxiwayDocument.sample.withColourUsages([
                ColourUsageInfo(
                    id: "cmyk:100,80,60,100",
                    name: "Heavy Black",
                    colourType: .process,
                    mode: .cmyk,
                    components: [1, 0.8, 0.6, 1],
                    inkSum: 340,
                    usageContexts: [.pathFill],
                    pagesUsedOn: [0]
                ),
            ])
            let check = InkCoverageCheck(parameters: .init(thresholdPercent: 300, operator: .moreThan))
            let result = check.run(on: doc)

            #expect(result.status == .fail)
            #expect(result.message.contains("1 colour"))
        }

        @Test("Passes on empty document")
        func passOnEmptyDocument() {
            let check = InkCoverageCheck(parameters: .init(thresholdPercent: 300, operator: .moreThan))
            let result = check.run(on: .empty)

            #expect(result.status == .pass)
        }

        @Test("TypeID is colour.ink_coverage")
        func typeID() {
            #expect(InkCoverageCheck.typeID == "colour.ink_coverage")
        }

        @Test("Default severity is warning")
        func defaultSeverity() {
            let check = InkCoverageCheck(parameters: .init(thresholdPercent: 300, operator: .moreThan))
            #expect(check.defaultSeverity == .warning)
        }
    }
}
