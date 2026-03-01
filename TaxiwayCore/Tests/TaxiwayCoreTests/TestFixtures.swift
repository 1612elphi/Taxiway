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

        let colourUsages = [
            ColourUsageInfo(
                id: "cmyk:0,0,0,100",
                name: "[Black]",
                colourType: .process,
                mode: .cmyk,
                components: [0, 0, 0, 1],
                inkSum: 100,
                usageContexts: [.textFill, .pathFill],
                pagesUsedOn: [0, 1]
            ),
            ColourUsageInfo(
                id: "spot:PANTONE 485 C",
                name: "PANTONE 485 C",
                colourType: .spot,
                mode: .cmyk,
                components: [1],
                inkSum: nil,
                usageContexts: [.pathFill],
                pagesUsedOn: [0]
            ),
        ]

        let annotations: [AnnotationInfo] = []

        let textFrames = [
            TextFrameInfo(
                id: "txt_0_0",
                pageIndex: 0,
                fontName: "ABCDEF+Helvetica-Bold",
                fontSize: 12.0,
                bounds: AnnotationBounds(x: 50, y: 700, width: 200, height: 14)
            ),
        ]

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
            colourUsages: colourUsages,
            annotations: annotations,
            textFrames: textFrames,
            metadata: metadata
        )
    }

    // MARK: - Transform helpers

    func withFileInfo(_ transform: (FileInfo) -> FileInfo) -> TaxiwayDocument {
        TaxiwayDocument(fileInfo: transform(fileInfo), documentInfo: documentInfo, pages: pages, fonts: fonts,
                        images: images, colourSpaces: colourSpaces, spotColours: spotColours,
                        colourUsages: colourUsages, annotations: annotations, textFrames: textFrames,
                        overprintUsages: overprintUsages, strokeInfos: strokeInfos,
                        gradientSpotColours: gradientSpotColours,
                        metadata: metadata, parseWarnings: parseWarnings)
    }

    func withDocumentInfo(_ transform: (DocumentInfo) -> DocumentInfo) -> TaxiwayDocument {
        TaxiwayDocument(fileInfo: fileInfo, documentInfo: transform(documentInfo), pages: pages, fonts: fonts,
                        images: images, colourSpaces: colourSpaces, spotColours: spotColours,
                        colourUsages: colourUsages, annotations: annotations, textFrames: textFrames,
                        overprintUsages: overprintUsages, strokeInfos: strokeInfos,
                        gradientSpotColours: gradientSpotColours,
                        metadata: metadata, parseWarnings: parseWarnings)
    }

    func withMetadata(_ transform: (DocumentMetadata) -> DocumentMetadata) -> TaxiwayDocument {
        TaxiwayDocument(fileInfo: fileInfo, documentInfo: documentInfo, pages: pages, fonts: fonts,
                        images: images, colourSpaces: colourSpaces, spotColours: spotColours,
                        colourUsages: colourUsages, annotations: annotations, textFrames: textFrames,
                        metadata: transform(metadata), parseWarnings: parseWarnings)
    }

    func withAnnotations(_ annotations: [AnnotationInfo]) -> TaxiwayDocument {
        TaxiwayDocument(fileInfo: fileInfo, documentInfo: documentInfo, pages: pages, fonts: fonts,
                        images: images, colourSpaces: colourSpaces, spotColours: spotColours,
                        colourUsages: colourUsages, annotations: annotations, textFrames: textFrames,
                        overprintUsages: overprintUsages, strokeInfos: strokeInfos,
                        gradientSpotColours: gradientSpotColours,
                        metadata: metadata, parseWarnings: parseWarnings)
    }

    func withColourSpaces(_ spaces: [ColourSpaceInfo]) -> TaxiwayDocument {
        TaxiwayDocument(fileInfo: fileInfo, documentInfo: documentInfo, pages: pages, fonts: fonts,
                        images: images, colourSpaces: spaces, spotColours: spotColours,
                        colourUsages: colourUsages, annotations: annotations, textFrames: textFrames,
                        overprintUsages: overprintUsages, strokeInfos: strokeInfos,
                        gradientSpotColours: gradientSpotColours,
                        metadata: metadata, parseWarnings: parseWarnings)
    }

    func withSpotColours(_ spots: [SpotColourInfo]) -> TaxiwayDocument {
        TaxiwayDocument(fileInfo: fileInfo, documentInfo: documentInfo, pages: pages, fonts: fonts,
                        images: images, colourSpaces: colourSpaces, spotColours: spots,
                        colourUsages: colourUsages, annotations: annotations, textFrames: textFrames,
                        overprintUsages: overprintUsages, strokeInfos: strokeInfos,
                        gradientSpotColours: gradientSpotColours,
                        metadata: metadata, parseWarnings: parseWarnings)
    }

    func withColourUsages(_ usages: [ColourUsageInfo]) -> TaxiwayDocument {
        TaxiwayDocument(fileInfo: fileInfo, documentInfo: documentInfo, pages: pages, fonts: fonts,
                        images: images, colourSpaces: colourSpaces, spotColours: spotColours,
                        colourUsages: usages, annotations: annotations, textFrames: textFrames,
                        overprintUsages: overprintUsages, strokeInfos: strokeInfos,
                        gradientSpotColours: gradientSpotColours,
                        metadata: metadata, parseWarnings: parseWarnings)
    }

    func withFonts(_ fonts: [FontInfo]) -> TaxiwayDocument {
        TaxiwayDocument(fileInfo: fileInfo, documentInfo: documentInfo, pages: pages, fonts: fonts,
                        images: images, colourSpaces: colourSpaces, spotColours: spotColours,
                        colourUsages: colourUsages, annotations: annotations, textFrames: textFrames,
                        overprintUsages: overprintUsages, strokeInfos: strokeInfos,
                        gradientSpotColours: gradientSpotColours,
                        metadata: metadata, parseWarnings: parseWarnings)
    }

    func withImages(_ images: [ImageInfo]) -> TaxiwayDocument {
        TaxiwayDocument(fileInfo: fileInfo, documentInfo: documentInfo, pages: pages, fonts: fonts,
                        images: images, colourSpaces: colourSpaces, spotColours: spotColours,
                        colourUsages: colourUsages, annotations: annotations, textFrames: textFrames,
                        overprintUsages: overprintUsages, strokeInfos: strokeInfos,
                        gradientSpotColours: gradientSpotColours,
                        metadata: metadata, parseWarnings: parseWarnings)
    }

    func withPages(_ pages: [PageInfo]) -> TaxiwayDocument {
        TaxiwayDocument(
            fileInfo: FileInfo(
                fileName: fileInfo.fileName,
                filePath: fileInfo.filePath,
                fileSizeBytes: fileInfo.fileSizeBytes,
                isEncrypted: fileInfo.isEncrypted,
                pageCount: pages.count
            ),
            documentInfo: documentInfo,
            pages: pages,
            fonts: fonts,
            images: images,
            colourSpaces: colourSpaces,
            spotColours: spotColours,
            colourUsages: colourUsages,
            annotations: annotations,
            textFrames: textFrames,
            overprintUsages: overprintUsages,
            strokeInfos: strokeInfos,
            gradientSpotColours: gradientSpotColours,
            metadata: metadata,
            parseWarnings: parseWarnings
        )
    }

    func withOverprintUsages(_ overprints: [OverprintInfo]) -> TaxiwayDocument {
        TaxiwayDocument(fileInfo: fileInfo, documentInfo: documentInfo, pages: pages, fonts: fonts,
                        images: images, colourSpaces: colourSpaces, spotColours: spotColours,
                        colourUsages: colourUsages, annotations: annotations, textFrames: textFrames,
                        overprintUsages: overprints, strokeInfos: strokeInfos,
                        gradientSpotColours: gradientSpotColours,
                        metadata: metadata, parseWarnings: parseWarnings)
    }

    func withStrokeInfos(_ strokes: [StrokeInfo]) -> TaxiwayDocument {
        TaxiwayDocument(fileInfo: fileInfo, documentInfo: documentInfo, pages: pages, fonts: fonts,
                        images: images, colourSpaces: colourSpaces, spotColours: spotColours,
                        colourUsages: colourUsages, annotations: annotations, textFrames: textFrames,
                        overprintUsages: overprintUsages, strokeInfos: strokes,
                        gradientSpotColours: gradientSpotColours,
                        metadata: metadata, parseWarnings: parseWarnings)
    }

    func withGradientSpotColours(_ gradients: [SpotColourInfo]) -> TaxiwayDocument {
        TaxiwayDocument(fileInfo: fileInfo, documentInfo: documentInfo, pages: pages, fonts: fonts,
                        images: images, colourSpaces: colourSpaces, spotColours: spotColours,
                        colourUsages: colourUsages, annotations: annotations, textFrames: textFrames,
                        overprintUsages: overprintUsages, strokeInfos: strokeInfos,
                        gradientSpotColours: gradients,
                        metadata: metadata, parseWarnings: parseWarnings)
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
