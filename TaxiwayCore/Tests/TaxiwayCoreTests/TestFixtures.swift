import Foundation
import CoreGraphics
@testable import TaxiwayCore

extension TaxiwayDocument {
    /// A sample document representing a typical 2-page A4 CMYK print PDF.
    static var sample: TaxiwayDocument {
        let a4Width: CGFloat = 595.276  // A4 width in points
        let a4Height: CGFloat = 841.89  // A4 height in points
        let bleedInset: CGFloat = 8.504 // 3mm bleed in points

        let fileInfo = FileInfo(
            fileName: "SampleBrochure.pdf",
            filePath: "/Users/test/Documents/SampleBrochure.pdf",
            fileSizeBytes: 5_242_880,  // 5 MB
            isEncrypted: false,
            pageCount: 2
        )

        let documentInfo = DocumentInfo(
            pdfVersion: "1.7",
            producer: "Adobe InDesign CC 2024",
            creator: "Adobe InDesign CC 2024",
            isLinearized: false,
            isTagged: true,
            hasLayers: false
        )

        let mediaBox = CGRect(x: 0, y: 0, width: a4Width, height: a4Height)
        let trimBox = CGRect(x: bleedInset, y: bleedInset,
                             width: a4Width - 2 * bleedInset,
                             height: a4Height - 2 * bleedInset)
        let bleedBox = mediaBox  // bleed extends to media box edges

        let pages = [
            PageInfo(index: 0, mediaBox: mediaBox, trimBox: trimBox, bleedBox: bleedBox, artBox: nil, rotation: 0),
            PageInfo(index: 1, mediaBox: mediaBox, trimBox: trimBox, bleedBox: bleedBox, artBox: nil, rotation: 0),
        ]

        let fonts = [
            FontInfo(name: "ABCDEF+Helvetica-Bold", type: .trueType, isEmbedded: true, isSubset: true, pagesUsedOn: [0, 1]),
            FontInfo(name: "TimesNewRoman", type: .type1, isEmbedded: false, isSubset: false, pagesUsedOn: [1]),
        ]

        let images = [
            ImageInfo(
                id: "img_0_1",
                pageIndex: 0,
                widthPixels: 2400,
                heightPixels: 1600,
                effectiveWidthPoints: 576.0,
                effectiveHeightPoints: 384.0,
                colourMode: .deviceCMYK,
                compressionType: .jpeg,
                bitsPerComponent: 8,
                hasICCProfile: true,
                hasICCOverride: false,
                hasAlphaChannel: false,
                blendMode: .normal,
                opacity: 1.0
            ),
        ]

        let colourSpaces = [
            ColourSpaceInfo(name: .deviceCMYK, pagesUsedOn: [0, 1], iccProfileName: "Coated FOGRA39"),
            ColourSpaceInfo(name: .deviceRGB, pagesUsedOn: [0]),
        ]

        let spotColours = [
            SpotColourInfo(name: "PANTONE 485 C", pagesUsedOn: [0]),
        ]

        let annotations: [AnnotationInfo] = []

        let metadata = DocumentMetadata(
            title: "Sample Brochure",
            author: "Test Author",
            subject: "A sample brochure for testing",
            keywords: "sample, test, brochure",
            creationDate: Date(timeIntervalSince1970: 1_700_000_000),
            modificationDate: Date(timeIntervalSince1970: 1_700_100_000),
            trapped: "False",
            outputIntents: [
                OutputIntent(
                    subtype: "GTS_PDFX",
                    outputCondition: "FOGRA39",
                    outputConditionIdentifier: "FOGRA39L",
                    registryName: "http://www.color.org"
                ),
            ],
            xmpRaw: nil,
            hasC2PA: false,
            hasGenAIMetadata: false
        )

        return TaxiwayDocument(
            fileInfo: fileInfo,
            documentInfo: documentInfo,
            pages: pages,
            fonts: fonts,
            images: images,
            colourSpaces: colourSpaces,
            spotColours: spotColours,
            annotations: annotations,
            metadata: metadata
        )
    }

    /// An empty document with no pages, fonts, images, etc.
    static var empty: TaxiwayDocument {
        let fileInfo = FileInfo(
            fileName: "Empty.pdf",
            filePath: "/Users/test/Documents/Empty.pdf",
            fileSizeBytes: 1024,
            isEncrypted: false,
            pageCount: 0
        )

        let documentInfo = DocumentInfo(
            pdfVersion: "1.4",
            producer: nil,
            creator: nil,
            isLinearized: false,
            isTagged: false,
            hasLayers: false
        )

        let metadata = DocumentMetadata(
            title: nil,
            author: nil,
            subject: nil,
            keywords: nil,
            creationDate: nil,
            modificationDate: nil,
            trapped: nil,
            outputIntents: [],
            xmpRaw: nil,
            hasC2PA: false,
            hasGenAIMetadata: false
        )

        return TaxiwayDocument(
            fileInfo: fileInfo,
            documentInfo: documentInfo,
            pages: [],
            fonts: [],
            images: [],
            colourSpaces: [],
            spotColours: [],
            annotations: [],
            metadata: metadata
        )
    }
}
