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
        let annotations = AnnotationExtractor.extract(from: pdfDoc, warnings: &warnings)
        let metadata = MetadataExtractor.extract(from: pdfDoc, warnings: &warnings)

        return TaxiwayDocument(
            fileInfo: fileInfo,
            documentInfo: documentInfo,
            pages: pages,
            fonts: fonts,
            images: images,
            colourSpaces: colourSpaces,
            spotColours: spotColours,
            annotations: annotations,
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

        return DocumentInfo(
            pdfVersion: pdfVersion,
            producer: producer,
            creator: creator,
            isLinearized: isLinearized,
            isTagged: isTagged,
            hasLayers: hasLayers
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

    private func checkLayers(pdfDoc: PDFDocument) -> Bool {
        guard let cgDoc = pdfDoc.documentRef else { return false }
        guard let catalog = cgDoc.catalog else { return false }

        var ocPropsDict: CGPDFDictionaryRef?
        return CGPDFDictionaryGetDictionary(catalog, "OCProperties", &ocPropsDict)
    }
}
