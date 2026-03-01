import Testing
import Foundation
import CoreGraphics
@testable import TaxiwayCore

// MARK: - TaxiwayDocument Codable Round-Trip

@Suite("TaxiwayDocument")
struct TaxiwayDocumentTests {

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let original = TaxiwayDocument.sample
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TaxiwayDocument.self, from: data)

        #expect(decoded == original)
        #expect(decoded.fileInfo.fileName == "SampleBrochure.pdf")
        #expect(decoded.documentInfo.pdfVersion == "1.7")
        #expect(decoded.pages.count == 2)
        #expect(decoded.fonts.count == 2)
        #expect(decoded.images.count == 1)
        #expect(decoded.colourSpaces.count == 2)
        #expect(decoded.spotColours.count == 1)
        #expect(decoded.annotations.isEmpty)
        #expect(decoded.metadata.title == "Sample Brochure")
        #expect(decoded.parseWarnings.isEmpty)
    }

    @Test("Empty document Codable round-trip")
    func emptyCodableRoundTrip() throws {
        let original = TaxiwayDocument.empty
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TaxiwayDocument.self, from: data)

        #expect(decoded == original)
        #expect(decoded.pages.isEmpty)
        #expect(decoded.fonts.isEmpty)
        #expect(decoded.images.isEmpty)
        #expect(decoded.colourSpaces.isEmpty)
        #expect(decoded.spotColours.isEmpty)
        #expect(decoded.annotations.isEmpty)
        #expect(decoded.metadata.title == nil)
    }
}

// MARK: - FileInfo

@Suite("FileInfo")
struct FileInfoTests {

    @Test("fileSizeMB computes correctly for exact megabyte")
    func fileSizeMBExact() {
        let info = FileInfo(fileName: "test.pdf", filePath: "/test.pdf", fileSizeBytes: 1_048_576, isEncrypted: false, pageCount: 1)
        #expect(info.fileSizeMB == 1.0)
    }

    @Test("fileSizeMB computes correctly for 5 MB")
    func fileSizeMB5() {
        let info = FileInfo(fileName: "test.pdf", filePath: "/test.pdf", fileSizeBytes: 5_242_880, isEncrypted: false, pageCount: 2)
        #expect(info.fileSizeMB == 5.0)
    }

    @Test("fileSizeMB computes correctly for zero bytes")
    func fileSizeMBZero() {
        let info = FileInfo(fileName: "test.pdf", filePath: "/test.pdf", fileSizeBytes: 0, isEncrypted: false, pageCount: 0)
        #expect(info.fileSizeMB == 0.0)
    }

    @Test("fileSizeMB computes correctly for fractional values")
    func fileSizeMBFractional() {
        let info = FileInfo(fileName: "test.pdf", filePath: "/test.pdf", fileSizeBytes: 524_288, isEncrypted: false, pageCount: 1)
        #expect(info.fileSizeMB == 0.5)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let original = FileInfo(fileName: "doc.pdf", filePath: "/path/doc.pdf", fileSizeBytes: 2_097_152, isEncrypted: true, pageCount: 10)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FileInfo.self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - PageInfo

@Suite("PageInfo")
struct PageInfoTests {

    @Test("effectiveTrimBox returns trimBox when set")
    func effectiveTrimBoxWithTrimBox() {
        let mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        let trimBox = CGRect(x: 10, y: 10, width: 592, height: 772)
        let page = PageInfo(index: 0, mediaBox: mediaBox, trimBox: trimBox, bleedBox: nil, artBox: nil, rotation: 0)
        #expect(page.effectiveTrimBox == trimBox)
    }

    @Test("effectiveTrimBox returns mediaBox when trimBox is nil")
    func effectiveTrimBoxWithoutTrimBox() {
        let mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        let page = PageInfo(index: 0, mediaBox: mediaBox, trimBox: nil, bleedBox: nil, artBox: nil, rotation: 0)
        #expect(page.effectiveTrimBox == mediaBox)
    }

    @Test("bleedMargins calculates correct distances")
    func bleedMarginsCalculation() {
        let mediaBox = CGRect(x: 0, y: 0, width: 620, height: 800)
        let trimBox = CGRect(x: 10, y: 10, width: 600, height: 780)
        let bleedBox = CGRect(x: 5, y: 5, width: 610, height: 790)
        let page = PageInfo(index: 0, mediaBox: mediaBox, trimBox: trimBox, bleedBox: bleedBox, artBox: nil, rotation: 0)

        let margins = page.bleedMargins
        // left: trim.minX(10) - bleed.minX(5) = 5
        #expect(margins.left == 5.0)
        // right: bleed.maxX(615) - trim.maxX(610) = 5
        #expect(margins.right == 5.0)
        // top: bleed.maxY(795) - trim.maxY(790) = 5
        #expect(margins.top == 5.0)
        // bottom: trim.minY(10) - bleed.minY(5) = 5
        #expect(margins.bottom == 5.0)
    }

    @Test("bleedMargins returns zeros when bleedBox is nil")
    func bleedMarginsNil() {
        let page = PageInfo(index: 0, mediaBox: CGRect(x: 0, y: 0, width: 612, height: 792),
                            trimBox: nil, bleedBox: nil, artBox: nil, rotation: 0)
        let margins = page.bleedMargins
        #expect(margins.left == 0)
        #expect(margins.right == 0)
        #expect(margins.top == 0)
        #expect(margins.bottom == 0)
    }

    @Test("bleedMargins with asymmetric bleed")
    func bleedMarginsAsymmetric() {
        let trimBox = CGRect(x: 20, y: 10, width: 560, height: 770)
        let bleedBox = CGRect(x: 10, y: 5, width: 590, height: 790)
        let page = PageInfo(index: 0, mediaBox: CGRect(x: 0, y: 0, width: 620, height: 800),
                            trimBox: trimBox, bleedBox: bleedBox, artBox: nil, rotation: 0)

        let margins = page.bleedMargins
        // left: 20 - 10 = 10
        #expect(margins.left == 10.0)
        // right: (10+590) - (20+560) = 600 - 580 = 20
        #expect(margins.right == 20.0)
        // top: (5+790) - (10+770) = 795 - 780 = 15
        #expect(margins.top == 15.0)
        // bottom: 10 - 5 = 5
        #expect(margins.bottom == 5.0)
    }

    @Test("Codable round-trip with all boxes set")
    func codableRoundTripAllBoxes() throws {
        let original = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 612, height: 792),
            trimBox: CGRect(x: 10, y: 10, width: 592, height: 772),
            bleedBox: CGRect(x: 5, y: 5, width: 602, height: 782),
            artBox: CGRect(x: 20, y: 20, width: 572, height: 752),
            rotation: 90
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PageInfo.self, from: data)
        #expect(decoded == original)
        #expect(decoded.rotation == 90)
    }

    @Test("Codable round-trip with nil boxes")
    func codableRoundTripNilBoxes() throws {
        let original = PageInfo(
            index: 3,
            mediaBox: CGRect(x: 0, y: 0, width: 595, height: 842),
            trimBox: nil,
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PageInfo.self, from: data)
        #expect(decoded == original)
        #expect(decoded.trimBox == nil)
        #expect(decoded.bleedBox == nil)
        #expect(decoded.artBox == nil)
    }
}

// MARK: - FontInfo

@Suite("FontInfo")
struct FontInfoTests {

    @Test("Embedded subset font properties")
    func embeddedSubsetFont() {
        let font = FontInfo(name: "ABCDEF+Helvetica-Bold", type: .trueType, isEmbedded: true, isSubset: true, pagesUsedOn: [0, 1])
        #expect(font.isEmbedded == true)
        #expect(font.isSubset == true)
        #expect(font.type == .trueType)
        #expect(font.pagesUsedOn == [0, 1])
    }

    @Test("Non-embedded font properties")
    func nonEmbeddedFont() {
        let font = FontInfo(name: "TimesNewRoman", type: .type1, isEmbedded: false, isSubset: false, pagesUsedOn: [1])
        #expect(font.isEmbedded == false)
        #expect(font.isSubset == false)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let original = FontInfo(name: "GHIJKL+MinionPro-Regular", type: .openTypeCFF, isEmbedded: true, isSubset: true, pagesUsedOn: [0, 1, 2])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FontInfo.self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - ImageInfo

@Suite("ImageInfo")
struct ImageInfoTests {

    @Test("effectivePPIHorizontal calculation")
    func effectivePPIHorizontal() {
        let image = ImageInfo(
            id: "img1", pageIndex: 0, widthPixels: 2400, heightPixels: 1600,
            effectiveWidthPoints: 576.0, effectiveHeightPoints: 384.0,
            colourMode: .deviceCMYK, compressionType: .jpeg, bitsPerComponent: 8,
            hasICCProfile: true, hasICCOverride: false, hasAlphaChannel: false,
            blendMode: .normal, opacity: 1.0
        )
        // 2400 / (576 / 72) = 2400 / 8 = 300
        #expect(image.effectivePPIHorizontal == 300.0)
    }

    @Test("effectivePPIVertical calculation")
    func effectivePPIVertical() {
        let image = ImageInfo(
            id: "img1", pageIndex: 0, widthPixels: 2400, heightPixels: 1600,
            effectiveWidthPoints: 576.0, effectiveHeightPoints: 384.0,
            colourMode: .deviceCMYK, compressionType: .jpeg, bitsPerComponent: 8,
            hasICCProfile: true, hasICCOverride: false, hasAlphaChannel: false,
            blendMode: .normal, opacity: 1.0
        )
        // 1600 / (384 / 72) = 1600 / 5.333... = 300
        #expect(image.effectivePPIVertical == 300.0)
    }

    @Test("effectivePPI returns 0 when dimensions are zero")
    func effectivePPIZeroDimensions() {
        let image = ImageInfo(
            id: "img0", pageIndex: 0, widthPixels: 100, heightPixels: 100,
            effectiveWidthPoints: 0, effectiveHeightPoints: 0,
            colourMode: .deviceRGB, compressionType: .flate, bitsPerComponent: 8,
            hasICCProfile: false, hasICCOverride: false, hasAlphaChannel: false,
            blendMode: .normal, opacity: 1.0
        )
        #expect(image.effectivePPIHorizontal == 0)
        #expect(image.effectivePPIVertical == 0)
    }

    @Test("isScaledProportionally returns true for proportional scaling")
    func isScaledProportionallyTrue() {
        let image = ImageInfo(
            id: "img1", pageIndex: 0, widthPixels: 2400, heightPixels: 1600,
            effectiveWidthPoints: 576.0, effectiveHeightPoints: 384.0,
            colourMode: .deviceCMYK, compressionType: .jpeg, bitsPerComponent: 8,
            hasICCProfile: true, hasICCOverride: false, hasAlphaChannel: false,
            blendMode: .normal, opacity: 1.0
        )
        // original ratio: 2400/1600 = 1.5, effective ratio: 576/384 = 1.5
        #expect(image.isScaledProportionally == true)
    }

    @Test("isScaledProportionally returns false for disproportionate scaling")
    func isScaledProportionallyFalse() {
        let image = ImageInfo(
            id: "img2", pageIndex: 0, widthPixels: 2400, heightPixels: 1600,
            effectiveWidthPoints: 576.0, effectiveHeightPoints: 200.0,
            colourMode: .deviceCMYK, compressionType: .jpeg, bitsPerComponent: 8,
            hasICCProfile: true, hasICCOverride: false, hasAlphaChannel: false,
            blendMode: .normal, opacity: 1.0
        )
        // original ratio: 1.5, effective ratio: 576/200 = 2.88
        #expect(image.isScaledProportionally == false)
    }

    @Test("isScaledProportionally returns true for zero-dimension edge cases")
    func isScaledProportionallyEdgeCases() {
        let image = ImageInfo(
            id: "img3", pageIndex: 0, widthPixels: 0, heightPixels: 0,
            effectiveWidthPoints: 0, effectiveHeightPoints: 0,
            colourMode: .deviceRGB, compressionType: .none, bitsPerComponent: 8,
            hasICCProfile: false, hasICCOverride: false, hasAlphaChannel: false,
            blendMode: .normal, opacity: 1.0
        )
        #expect(image.isScaledProportionally == true)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let original = ImageInfo(
            id: "img_test", pageIndex: 2, widthPixels: 1200, heightPixels: 800,
            effectiveWidthPoints: 288.0, effectiveHeightPoints: 192.0,
            colourMode: .iccBased, compressionType: .jpeg2000, bitsPerComponent: 16,
            hasICCProfile: true, hasICCOverride: true, hasAlphaChannel: true,
            blendMode: .multiply, opacity: 0.8
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ImageInfo.self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - Enum Codable Tests

@Suite("Enum Codable")
struct EnumCodableTests {

    @Test("FontType all cases encode and decode")
    func fontTypeRoundTrip() throws {
        for fontType in [FontType.type1, .trueType, .openTypeCFF, .cidFontType0, .cidFontType2, .type3, .mmType1, .unknown] {
            let data = try JSONEncoder().encode(fontType)
            let decoded = try JSONDecoder().decode(FontType.self, from: data)
            #expect(decoded == fontType)
        }
    }

    @Test("ImageColourMode all cases encode and decode")
    func imageColourModeRoundTrip() throws {
        for mode in [ImageColourMode.deviceGray, .deviceRGB, .deviceCMYK, .iccBased, .indexed, .separation, .deviceN, .unknown] {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(ImageColourMode.self, from: data)
            #expect(decoded == mode)
        }
    }

    @Test("ImageCompressionType all cases encode and decode")
    func imageCompressionTypeRoundTrip() throws {
        for comp in [ImageCompressionType.jpeg, .jpeg2000, .jbig2, .ccitt, .flate, .lzw, .runLength, .none, .unknown] {
            let data = try JSONEncoder().encode(comp)
            let decoded = try JSONDecoder().decode(ImageCompressionType.self, from: data)
            #expect(decoded == comp)
        }
    }

    @Test("BlendMode all cases encode and decode")
    func blendModeRoundTrip() throws {
        for mode in [BlendMode.normal, .multiply, .screen, .overlay, .darken, .lighten,
                     .colorDodge, .colorBurn, .hardLight, .softLight, .difference, .exclusion, .unknown] {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(BlendMode.self, from: data)
            #expect(decoded == mode)
        }
    }

    @Test("ColourSpaceName all cases encode and decode")
    func colourSpaceNameRoundTrip() throws {
        for name in [ColourSpaceName.deviceGray, .deviceRGB, .deviceCMYK, .iccBased, .calGray, .calRGB,
                     .lab, .indexed, .separation, .deviceN, .pattern, .unknown] {
            let data = try JSONEncoder().encode(name)
            let decoded = try JSONDecoder().decode(ColourSpaceName.self, from: data)
            #expect(decoded == name)
        }
    }

    @Test("AnnotationType all cases encode and decode")
    func annotationTypeRoundTrip() throws {
        for type in [AnnotationType.link, .widget, .text, .freeText, .highlight, .underline,
                     .strikeOut, .stamp, .ink, .popup, .fileAttachment, .other] {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(AnnotationType.self, from: data)
            #expect(decoded == type)
        }
    }

    @Test("FontType raw values match expected strings")
    func fontTypeRawValues() {
        #expect(FontType.type1.rawValue == "Type1")
        #expect(FontType.trueType.rawValue == "TrueType")
        #expect(FontType.openTypeCFF.rawValue == "OpenType CFF")
        #expect(FontType.cidFontType0.rawValue == "CIDFontType0")
        #expect(FontType.cidFontType2.rawValue == "CIDFontType2")
        #expect(FontType.type3.rawValue == "Type3")
        #expect(FontType.mmType1.rawValue == "MMType1")
        #expect(FontType.unknown.rawValue == "Unknown")
    }

    @Test("BlendMode raw values match expected strings")
    func blendModeRawValues() {
        #expect(BlendMode.normal.rawValue == "Normal")
        #expect(BlendMode.multiply.rawValue == "Multiply")
        #expect(BlendMode.colorDodge.rawValue == "ColorDodge")
        #expect(BlendMode.softLight.rawValue == "SoftLight")
    }
}

// MARK: - DocumentMetadata

@Suite("DocumentMetadata")
struct DocumentMetadataTests {

    @Test("Codable round-trip with all fields populated")
    func codableRoundTripFull() throws {
        let original = DocumentMetadata(
            title: "Test", author: "Author", subject: "Subject", keywords: "a, b",
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            modificationDate: Date(timeIntervalSince1970: 1_700_100_000),
            trapped: "False",
            outputIntents: [
                OutputIntent(subtype: "GTS_PDFX", outputCondition: "FOGRA39",
                             outputConditionIdentifier: "FOGRA39L", registryName: "http://www.color.org"),
            ],
            xmpRaw: "<xmp>test</xmp>",
            hasC2PA: true,
            hasGenAIMetadata: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DocumentMetadata.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip with nil fields")
    func codableRoundTripNils() throws {
        let original = DocumentMetadata(
            title: nil, author: nil, subject: nil, keywords: nil,
            creationDate: nil, modificationDate: nil, trapped: nil,
            outputIntents: [], xmpRaw: nil, hasC2PA: false, hasGenAIMetadata: false
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DocumentMetadata.self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - ColourSpaceInfo

@Suite("ColourSpaceInfo")
struct ColourSpaceInfoTests {

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let original = ColourSpaceInfo(name: .iccBased, pagesUsedOn: [0, 1, 2], iccProfileName: "sRGB IEC61966-2.1")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ColourSpaceInfo.self, from: data)
        #expect(decoded == original)
    }

    @Test("Optional ICC profile name defaults to nil")
    func nilICCProfile() {
        let cs = ColourSpaceInfo(name: .deviceRGB, pagesUsedOn: [0])
        #expect(cs.iccProfileName == nil)
    }
}

// MARK: - SpotColourInfo

@Suite("SpotColourInfo")
struct SpotColourInfoTests {

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let original = SpotColourInfo(name: "PANTONE 485 C", pagesUsedOn: [0, 1])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SpotColourInfo.self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - AnnotationInfo

@Suite("AnnotationInfo")
struct AnnotationInfoTests {

    @Test("Codable round-trip with subtype")
    func codableRoundTripWithSubtype() throws {
        let original = AnnotationInfo(type: .link, pageIndex: 0, subtype: "URI")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnnotationInfo.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip without subtype")
    func codableRoundTripWithoutSubtype() throws {
        let original = AnnotationInfo(type: .highlight, pageIndex: 2)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnnotationInfo.self, from: data)
        #expect(decoded == original)
        #expect(decoded.subtype == nil)
    }
}

// MARK: - ParseWarning

@Suite("ParseWarning")
struct ParseWarningTests {

    @Test("Codable round-trip with page index")
    func codableRoundTripWithPage() throws {
        let original = ParseWarning(domain: "fonts", message: "Font not embedded", pageIndex: 3)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ParseWarning.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip without page index")
    func codableRoundTripWithoutPage() throws {
        let original = ParseWarning(domain: "document", message: "Linearization broken")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ParseWarning.self, from: data)
        #expect(decoded == original)
        #expect(decoded.pageIndex == nil)
    }
}

// MARK: - Sample Fixture Validation

@Suite("Test Fixtures")
struct TestFixtureTests {

    @Test("Sample fixture has expected structure")
    func sampleFixture() {
        let doc = TaxiwayDocument.sample
        #expect(doc.fileInfo.fileName == "SampleBrochure.pdf")
        #expect(doc.fileInfo.fileSizeBytes == 5_242_880)
        #expect(doc.fileInfo.fileSizeMB == 5.0)
        #expect(doc.fileInfo.pageCount == 2)
        #expect(doc.documentInfo.pdfVersion == "1.7")
        #expect(doc.documentInfo.isTagged == true)
        #expect(doc.pages.count == 2)
        #expect(doc.fonts.count == 2)
        #expect(doc.fonts[0].isEmbedded == true)
        #expect(doc.fonts[1].isEmbedded == false)
        #expect(doc.images.count == 1)
        #expect(doc.images[0].colourMode == .deviceCMYK)
        #expect(doc.images[0].compressionType == .jpeg)
        #expect(doc.colourSpaces.count == 2)
        #expect(doc.spotColours.count == 1)
        #expect(doc.spotColours[0].name == "PANTONE 485 C")
        #expect(doc.annotations.isEmpty)
    }

    @Test("Empty fixture has no content")
    func emptyFixture() {
        let doc = TaxiwayDocument.empty
        #expect(doc.fileInfo.fileName == "Empty.pdf")
        #expect(doc.fileInfo.pageCount == 0)
        #expect(doc.pages.isEmpty)
        #expect(doc.fonts.isEmpty)
        #expect(doc.images.isEmpty)
        #expect(doc.colourSpaces.isEmpty)
        #expect(doc.spotColours.isEmpty)
        #expect(doc.annotations.isEmpty)
        #expect(doc.metadata.title == nil)
        #expect(doc.metadata.author == nil)
        #expect(doc.metadata.outputIntents.isEmpty)
    }
}
