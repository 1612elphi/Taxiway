import Testing
import Foundation
@testable import TaxiwayCore

@Suite("Font Checks")
struct FontCheckTests {

    // MARK: - FontNotEmbeddedCheck

    @Suite("FontNotEmbeddedCheck")
    struct FontNotEmbeddedCheckTests {

        @Test("Fails when a font is not embedded")
        func failWithUnembeddedFont() {
            // sample has TimesNewRoman not embedded
            let check = FontNotEmbeddedCheck()
            let result = check.run(on: .sample)

            #expect(result.status == .fail)
            #expect(result.message.contains("1 font"))
            #expect(result.message.contains("not embedded"))
            #expect(result.detail?.contains("TimesNewRoman") == true)
            #expect(result.affectedItems == [.font(name: "TimesNewRoman", pages: [1])])
        }

        @Test("Passes when all fonts are embedded")
        func passAllEmbedded() {
            let doc = TaxiwayDocument.sample.withFonts([
                FontInfo(name: "Helvetica-Bold", type: .trueType, isEmbedded: true, isSubset: true, pagesUsedOn: [0, 1]),
                FontInfo(name: "Arial", type: .trueType, isEmbedded: true, isSubset: false, pagesUsedOn: [0]),
            ])
            let check = FontNotEmbeddedCheck()
            let result = check.run(on: doc)

            #expect(result.status == .pass)
            #expect(result.message.contains("All fonts are embedded"))
        }

        @Test("Passes on empty fonts list")
        func passOnEmptyFonts() {
            let doc = TaxiwayDocument.sample.withFonts([])
            let check = FontNotEmbeddedCheck()
            let result = check.run(on: doc)

            #expect(result.status == .pass)
        }

        @Test("Fails with multiple unembedded fonts and reports all")
        func failMultipleUnembedded() {
            let doc = TaxiwayDocument.sample.withFonts([
                FontInfo(name: "Font-A", type: .type1, isEmbedded: false, isSubset: false, pagesUsedOn: [0]),
                FontInfo(name: "Font-B", type: .trueType, isEmbedded: true, isSubset: true, pagesUsedOn: [0]),
                FontInfo(name: "Font-C", type: .type3, isEmbedded: false, isSubset: false, pagesUsedOn: [1]),
            ])
            let check = FontNotEmbeddedCheck()
            let result = check.run(on: doc)

            #expect(result.status == .fail)
            #expect(result.message.contains("2 font"))
            #expect(result.affectedItems.count == 2)
            #expect(result.detail?.contains("Font-A") == true)
            #expect(result.detail?.contains("Font-C") == true)
        }

        @Test("TypeID is fonts.not_embedded")
        func typeID() {
            #expect(FontNotEmbeddedCheck.typeID == "fonts.not_embedded")
        }

        @Test("Default severity is error")
        func defaultSeverity() {
            let check = FontNotEmbeddedCheck()
            #expect(check.defaultSeverity == .error)
        }

        @Test("Category is fonts")
        func category() {
            let check = FontNotEmbeddedCheck()
            #expect(check.category == .fonts)
        }
    }

    // MARK: - FontTypeCheck

    @Suite("FontTypeCheck")
    struct FontTypeCheckTests {

        @Test("Fails when matching font type found with operator .is")
        func failWhenTypeFound() {
            // sample has a Type1 font (TimesNewRoman)
            let check = FontTypeCheck(parameters: .init(fontType: .type1, operator: .is))
            let result = check.run(on: .sample)

            #expect(result.status == .fail)
            #expect(result.message.contains("1"))
            #expect(result.message.contains("Type1"))
            #expect(result.detail?.contains("TimesNewRoman") == true)
        }

        @Test("Passes when matching font type not found with operator .is")
        func passWhenTypeNotFound() {
            let check = FontTypeCheck(parameters: .init(fontType: .type3, operator: .is))
            let result = check.run(on: .sample)

            #expect(result.status == .pass)
            #expect(result.message.contains("No Type3 fonts"))
        }

        @Test("Passes when all fonts match with operator .isNot")
        func passWhenAllMatch() {
            let doc = TaxiwayDocument.sample.withFonts([
                FontInfo(name: "Arial", type: .trueType, isEmbedded: true, isSubset: false, pagesUsedOn: [0]),
                FontInfo(name: "Verdana", type: .trueType, isEmbedded: true, isSubset: false, pagesUsedOn: [1]),
            ])
            let check = FontTypeCheck(parameters: .init(fontType: .trueType, operator: .isNot))
            let result = check.run(on: doc)

            #expect(result.status == .pass)
            #expect(result.message.contains("All fonts are TrueType"))
        }

        @Test("Fails when some fonts don't match with operator .isNot")
        func failWhenNotAllMatch() {
            // sample has TrueType and Type1 — checking isNot TrueType should fail for Type1
            let check = FontTypeCheck(parameters: .init(fontType: .trueType, operator: .isNot))
            let result = check.run(on: .sample)

            #expect(result.status == .fail)
            #expect(result.message.contains("not TrueType"))
            #expect(result.detail?.contains("TimesNewRoman") == true)
        }

        @Test("Passes on empty fonts with operator .is")
        func passOnEmptyFontsIs() {
            let doc = TaxiwayDocument.sample.withFonts([])
            let check = FontTypeCheck(parameters: .init(fontType: .type1, operator: .is))
            let result = check.run(on: doc)

            #expect(result.status == .pass)
        }

        @Test("Passes on empty fonts with operator .isNot")
        func passOnEmptyFontsIsNot() {
            let doc = TaxiwayDocument.sample.withFonts([])
            let check = FontTypeCheck(parameters: .init(fontType: .trueType, operator: .isNot))
            let result = check.run(on: doc)

            #expect(result.status == .pass)
        }

        @Test("Reports affected font items with correct pages")
        func affectedItems() {
            let doc = TaxiwayDocument.sample.withFonts([
                FontInfo(name: "OldFont", type: .type1, isEmbedded: true, isSubset: false, pagesUsedOn: [0, 2, 3]),
            ])
            let check = FontTypeCheck(parameters: .init(fontType: .type1, operator: .is))
            let result = check.run(on: doc)

            #expect(result.affectedItems == [.font(name: "OldFont", pages: [0, 2, 3])])
        }

        @Test("TypeID is fonts.type")
        func typeID() {
            #expect(FontTypeCheck.typeID == "fonts.type")
        }

        @Test("Default severity is warning")
        func defaultSeverity() {
            let check = FontTypeCheck(parameters: .init(fontType: .type1, operator: .is))
            #expect(check.defaultSeverity == .warning)
        }
    }

    // MARK: - FontSizeCheck

    @Suite("FontSizeCheck")
    struct FontSizeCheckTests {

        @Test("Fails when text below threshold with lessThan operator")
        func failLessThan() {
            // Sample has a 12pt text frame
            let check = FontSizeCheck(parameters: .init(threshold: 14.0, operator: .lessThan))
            let result = check.run(on: .sample)

            #expect(result.status == .fail)
            #expect(result.message.contains("1 text frame"))
            #expect(!result.affectedItems.isEmpty)
        }

        @Test("Passes when text above threshold with lessThan operator")
        func passLessThan() {
            // Sample has 12pt text — checking < 6pt should find nothing
            let check = FontSizeCheck(parameters: .init(threshold: 6.0, operator: .lessThan))
            let result = check.run(on: .sample)

            #expect(result.status == .pass)
        }

        @Test("Passes when no text exceeds threshold with moreThan operator")
        func passMoreThan() {
            // Sample has 12pt text — checking > 72pt should find nothing
            let check = FontSizeCheck(parameters: .init(threshold: 72.0, operator: .moreThan))
            let result = check.run(on: .sample)

            #expect(result.status == .pass)
        }

        @Test("Fails when text matches threshold with equals operator")
        func failEquals() {
            let check = FontSizeCheck(parameters: .init(threshold: 12.0, operator: .equals))
            let result = check.run(on: .sample)

            #expect(result.status == .fail)
            #expect(result.message.contains("1 text frame"))
        }

        @Test("Passes on empty document")
        func passOnEmptyDocument() {
            let check = FontSizeCheck(parameters: .init(threshold: 10.0, operator: .lessThan))
            let result = check.run(on: .empty)

            #expect(result.status == .pass)
            #expect(result.message.contains("No text frames"))
        }

        @Test("Reports textFrame affected items with bounds")
        func affectedItemsHaveBounds() {
            let check = FontSizeCheck(parameters: .init(threshold: 14.0, operator: .lessThan))
            let result = check.run(on: .sample)

            #expect(result.affectedItems.count == 1)
            if case .textFrame(let id, let page, _) = result.affectedItems.first {
                #expect(id == "txt_0_0")
                #expect(page == 0)
            } else {
                Issue.record("Expected textFrame affected item")
            }
        }

        @Test("TypeID is fonts.size")
        func typeID() {
            #expect(FontSizeCheck.typeID == "fonts.size")
        }

        @Test("Default severity is warning")
        func defaultSeverity() {
            let check = FontSizeCheck(parameters: .init(threshold: 12.0, operator: .lessThan))
            #expect(check.defaultSeverity == .warning)
        }
    }
}
