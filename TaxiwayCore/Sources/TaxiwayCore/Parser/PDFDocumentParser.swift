import Foundation
import CoreGraphics
import PDFKit

/// Main entry point for parsing a PDF file into a TaxiwayDocument.
public struct PDFDocumentParser: Sendable {

    public init() {}

    /// Parses a PDF file at the given URL and returns a fully populated TaxiwayDocument.
    public func parse(url: URL) throws -> TaxiwayDocument {
        // Verify file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ParsingError.fileNotFound(url)
        }

        // Open with PDFKit
        guard let pdfDoc = PDFDocument(url: url) else {
            throw ParsingError.cannotOpenPDF(url)
        }

        // Check if locked (encrypted and not unlockable)
        if pdfDoc.isLocked {
            throw ParsingError.encrypted(url)
        }

        var warnings: [ParseWarning] = []

        let fileInfo = extractFileInfo(url: url, pdfDoc: pdfDoc)
        let documentInfo = extractDocumentInfo(url: url, pdfDoc: pdfDoc)
        let pages = PageGeometry.extract(from: pdfDoc, warnings: &warnings)
        let fonts = FontExtractor.extract(from: pdfDoc, warnings: &warnings)
        let images = ImageExtractor.extract(from: pdfDoc, warnings: &warnings)
        let colourSpaces = ColourExtractor.extractColourSpaces(from: pdfDoc, warnings: &warnings)
        let spotColours = ColourExtractor.extractSpotColours(from: pdfDoc, warnings: &warnings)
        let (colourUsages, overprintUsages) = extractColourUsagesAndOverprints(from: pdfDoc)
        let annotations = AnnotationExtractor.extract(from: pdfDoc, warnings: &warnings)
        let textFrames = extractTextFrames(from: pdfDoc)
        let strokeInfos = extractStrokeInfos(from: pdfDoc)
        let gradientSpotColours = ShadingExtractor.extract(from: pdfDoc)
        let metadata = MetadataExtractor.extract(from: pdfDoc, warnings: &warnings)

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
            overprintUsages: overprintUsages,
            strokeInfos: strokeInfos,
            gradientSpotColours: gradientSpotColours,
            metadata: metadata,
            parseWarnings: warnings
        )
    }

    // MARK: - File Info

    private func extractFileInfo(url: URL, pdfDoc: PDFDocument) -> FileInfo {
        let fileName = url.lastPathComponent
        let filePath = url.path

        var fileSizeBytes: Int64 = 0
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            fileSizeBytes = size
        }

        let isEncrypted = pdfDoc.isEncrypted
        let pageCount = pdfDoc.pageCount

        return FileInfo(
            fileName: fileName,
            filePath: filePath,
            fileSizeBytes: fileSizeBytes,
            isEncrypted: isEncrypted,
            pageCount: pageCount
        )
    }

    // MARK: - Document Info

    private func extractDocumentInfo(url: URL, pdfDoc: PDFDocument) -> DocumentInfo {
        let pdfVersion: String
        if let cgDoc = pdfDoc.documentRef {
            var majorVersion: Int32 = 0
            var minorVersion: Int32 = 0
            cgDoc.getVersion(majorVersion: &majorVersion, minorVersion: &minorVersion)
            pdfVersion = "\(majorVersion).\(minorVersion)"
        } else {
            pdfVersion = "1.0"
        }

        let attributes = pdfDoc.documentAttributes ?? [:]
        let producer = attributes["Producer"] as? String
        let creator = attributes["Creator"] as? String

        let isLinearized = checkLinearized(url: url)
        let isTagged = checkTagged(pdfDoc: pdfDoc)
        let hasLayers = checkLayers(pdfDoc: pdfDoc)
        let transparencyDetected = checkTransparency(pdfDoc: pdfDoc)
        let hasEmbeddedFiles = checkEmbeddedFiles(pdfDoc: pdfDoc)
        let hasJavaScript = checkJavaScript(pdfDoc: pdfDoc)
        let outputIntentIdentifier = extractOutputIntent(pdfDoc: pdfDoc)

        return DocumentInfo(
            pdfVersion: pdfVersion,
            producer: producer,
            creator: creator,
            isLinearized: isLinearized,
            isTagged: isTagged,
            hasLayers: hasLayers,
            transparencyDetected: transparencyDetected,
            hasEmbeddedFiles: hasEmbeddedFiles,
            hasJavaScript: hasJavaScript,
            outputIntentIdentifier: outputIntentIdentifier
        )
    }

    private func checkLinearized(url: URL) -> Bool {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? fileHandle.close() }

        let data = fileHandle.readData(ofLength: 1024)
        guard let headerStr = String(data: data, encoding: .ascii) else { return false }
        return headerStr.contains("Linearized")
    }

    private func checkTagged(pdfDoc: PDFDocument) -> Bool {
        guard let cgDoc = pdfDoc.documentRef else { return false }
        guard let catalog = cgDoc.catalog else { return false }

        var markInfoDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(catalog, "MarkInfo", &markInfoDict),
              let markInfo = markInfoDict else {
            return false
        }

        var marked: CGPDFBoolean = 0
        if CGPDFDictionaryGetBoolean(markInfo, "Marked", &marked) {
            return marked != 0
        }

        return false
    }

    // MARK: - Colour Usages & Overprints

    private func extractColourUsagesAndOverprints(from pdfDoc: PDFDocument) -> ([ColourUsageInfo], [OverprintInfo]) {
        var rawUsages: [ContentStreamColourScanner.RawColourUsage] = []

        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i),
                  let pageRef = page.pageRef else { continue }

            let lookup = ContentStreamColourScanner.buildLookup(pageRef: pageRef)
            let extGStateLookup = ContentStreamColourScanner.buildExtGStateLookup(pageRef: pageRef)
            let pageUsages = ContentStreamColourScanner.scan(
                page: pageRef, pageIndex: i, lookup: lookup, extGStateLookup: extGStateLookup)
            rawUsages.append(contentsOf: pageUsages)
        }

        // Extract overprint info from raw usages
        let overprintUsages = Self.extractOverprintInfos(from: rawUsages)

        return (ContentStreamColourScanner.deduplicate(rawUsages), overprintUsages)
    }

    private static func extractOverprintInfos(from rawUsages: [ContentStreamColourScanner.RawColourUsage]) -> [OverprintInfo] {
        var seen: Set<String> = []
        var results: [OverprintInfo] = []

        for usage in rawUsages where usage.overprintEnabled {
            let context: OverprintContext
            if usage.context == .pathStroke {
                context = .stroke
            } else if usage.context == .textFill {
                context = .text
            } else {
                context = .fill
            }

            let isWhite = Self.isWhiteColour(mode: usage.mode, components: usage.components)
            let key = "\(usage.pageIndex):\(context.rawValue):\(isWhite)"
            guard seen.insert(key).inserted else { continue }

            results.append(OverprintInfo(
                pageIndex: usage.pageIndex,
                context: context,
                isWhiteOverprint: isWhite
            ))
        }

        return results
    }

    private static func isWhiteColour(mode: ColourMode, components: [Double]) -> Bool {
        switch mode {
        case .cmyk:
            return components.count >= 4 && components.allSatisfy { $0 < 0.001 }
        case .rgb:
            return components.count >= 3 && components.allSatisfy { $0 > 0.999 }
        case .gray:
            return components.first.map { $0 > 0.999 } ?? false
        }
    }

    // MARK: - Text Frames

    private func extractTextFrames(from pdfDoc: PDFDocument) -> [TextFrameInfo] {
        var frames: [TextFrameInfo] = []
        var counter = 0

        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i),
                  let pageRef = page.pageRef else { continue }

            let placements = ContentStreamTextScanner.scan(page: pageRef)
            for placement in placements {
                let id = "txt_\(i)_\(counter)"
                counter += 1
                frames.append(TextFrameInfo(
                    id: id,
                    pageIndex: i,
                    fontName: placement.fontName,
                    fontSize: placement.fontSize,
                    bounds: placement.bounds
                ))
            }
        }

        return frames
    }

    // MARK: - Stroke Infos

    private func extractStrokeInfos(from pdfDoc: PDFDocument) -> [StrokeInfo] {
        var rawRecords: [ContentStreamStrokeScanner.StrokeRecord] = []

        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i),
                  let pageRef = page.pageRef else { continue }

            let pageRecords = ContentStreamStrokeScanner.scan(page: pageRef, pageIndex: i)
            rawRecords.append(contentsOf: pageRecords)
        }

        return ContentStreamStrokeScanner.deduplicate(rawRecords)
    }

    // MARK: - Transparency Detection

    private func checkTransparency(pdfDoc: PDFDocument) -> Bool {
        guard let cgDoc = pdfDoc.documentRef else { return false }

        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i),
                  let pageDict = page.pageRef?.dictionary else { continue }

            // Check for transparency group on page
            var groupDict: CGPDFDictionaryRef?
            if CGPDFDictionaryGetDictionary(pageDict, "Group", &groupDict), let group = groupDict {
                var sName: UnsafePointer<CChar>?
                if CGPDFDictionaryGetName(group, "S", &sName), let s = sName {
                    if String(cString: s) == "Transparency" {
                        return true
                    }
                }
            }

            // Check ExtGState entries for transparency indicators
            var resourcesDict: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
                  let resources = resourcesDict else { continue }

            var extGStateDict: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(resources, "ExtGState", &extGStateDict),
                  let extGState = extGStateDict else { continue }

            final class TransparencyDetector: @unchecked Sendable {
                var found = false
            }
            let detector = TransparencyDetector()
            let detectorPtr = Unmanaged.passUnretained(detector).toOpaque()

            CGPDFDictionaryApplyBlock(extGState, { (_, value, info) -> Bool in
                let detector = Unmanaged<TransparencyDetector>.fromOpaque(info!).takeUnretainedValue()

                var gsDict: CGPDFDictionaryRef?
                guard CGPDFObjectGetValue(value, .dictionary, &gsDict), let gs = gsDict else { return true }

                // Check fill opacity (ca) < 1.0
                var ca: CGPDFReal = 1.0
                if CGPDFDictionaryGetNumber(gs, "ca", &ca), ca < 1.0 {
                    detector.found = true
                    return false
                }

                // Check stroke opacity (CA) < 1.0
                var bigCA: CGPDFReal = 1.0
                if CGPDFDictionaryGetNumber(gs, "CA", &bigCA), bigCA < 1.0 {
                    detector.found = true
                    return false
                }

                // Check blend mode != Normal
                var bmName: UnsafePointer<CChar>?
                if CGPDFDictionaryGetName(gs, "BM", &bmName), let bm = bmName {
                    let bmStr = String(cString: bm)
                    if bmStr != "Normal" {
                        detector.found = true
                        return false
                    }
                }

                // Check for soft mask
                var smaskObj: CGPDFObjectRef?
                if CGPDFDictionaryGetObject(gs, "SMask", &smaskObj), let obj = smaskObj {
                    // SMask can be a name (/None) or a dictionary
                    var smaskName: UnsafePointer<CChar>?
                    if CGPDFObjectGetValue(obj, .name, &smaskName), let name = smaskName {
                        if String(cString: name) != "None" {
                            detector.found = true
                            return false
                        }
                    } else {
                        // It's a dictionary (actual soft mask definition)
                        detector.found = true
                        return false
                    }
                }

                return true
            }, detectorPtr)

            if detector.found { return true }
        }

        return false
    }

    private func checkLayers(pdfDoc: PDFDocument) -> Bool {
        guard let cgDoc = pdfDoc.documentRef else { return false }
        guard let catalog = cgDoc.catalog else { return false }

        var ocPropsDict: CGPDFDictionaryRef?
        return CGPDFDictionaryGetDictionary(catalog, "OCProperties", &ocPropsDict)
    }

    private func checkEmbeddedFiles(pdfDoc: PDFDocument) -> Bool {
        guard let cgDoc = pdfDoc.documentRef else { return false }
        guard let catalog = cgDoc.catalog else { return false }

        var namesDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(catalog, "Names", &namesDict),
              let names = namesDict else { return false }

        var embeddedFilesDict: CGPDFDictionaryRef?
        return CGPDFDictionaryGetDictionary(names, "EmbeddedFiles", &embeddedFilesDict)
    }

    private func checkJavaScript(pdfDoc: PDFDocument) -> Bool {
        guard let cgDoc = pdfDoc.documentRef else { return false }
        guard let catalog = cgDoc.catalog else { return false }

        // Check Names → JavaScript name tree
        var namesDict: CGPDFDictionaryRef?
        if CGPDFDictionaryGetDictionary(catalog, "Names", &namesDict), let names = namesDict {
            var jsDict: CGPDFDictionaryRef?
            if CGPDFDictionaryGetDictionary(names, "JavaScript", &jsDict) {
                return true
            }
        }

        // Check OpenAction for JavaScript type
        var openActionDict: CGPDFDictionaryRef?
        if CGPDFDictionaryGetDictionary(catalog, "OpenAction", &openActionDict), let openAction = openActionDict {
            var sName: UnsafePointer<CChar>?
            if CGPDFDictionaryGetName(openAction, "S", &sName), let s = sName {
                if String(cString: s) == "JavaScript" {
                    return true
                }
            }
        }

        return false
    }

    private func extractOutputIntent(pdfDoc: PDFDocument) -> String? {
        guard let cgDoc = pdfDoc.documentRef else { return nil }
        guard let catalog = cgDoc.catalog else { return nil }

        var outputIntentsArray: CGPDFArrayRef?
        guard CGPDFDictionaryGetArray(catalog, "OutputIntents", &outputIntentsArray),
              let intents = outputIntentsArray else { return nil }

        guard CGPDFArrayGetCount(intents) > 0 else { return nil }

        var intentDict: CGPDFDictionaryRef?
        guard CGPDFArrayGetDictionary(intents, 0, &intentDict),
              let intent = intentDict else { return nil }

        var pdfString: CGPDFStringRef?
        guard CGPDFDictionaryGetString(intent, "OutputConditionIdentifier", &pdfString),
              let str = pdfString,
              let cfStr = CGPDFStringCopyTextString(str) else { return nil }

        return cfStr as String
    }
}
