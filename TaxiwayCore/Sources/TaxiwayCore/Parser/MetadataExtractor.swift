import Foundation
import CoreGraphics
import PDFKit

/// Extracts document metadata, XMP, output intents, and AI-related markers from a PDF.
struct MetadataExtractor: Sendable {

    /// Extracts all metadata from the PDF document.
    static func extract(from pdfDoc: PDFDocument, warnings: inout [ParseWarning]) -> DocumentMetadata {
        let attributes = pdfDoc.documentAttributes ?? [:]

        let title = attributes[PDFDocumentAttribute.titleAttribute] as? String
        let author = attributes[PDFDocumentAttribute.authorAttribute] as? String
        let subject = attributes[PDFDocumentAttribute.subjectAttribute] as? String
        let keywords = extractKeywords(from: attributes)
        let creationDate = attributes[PDFDocumentAttribute.creationDateAttribute] as? Date
        let modificationDate = attributes[PDFDocumentAttribute.modificationDateAttribute] as? Date

        let trapped = extractTrapped(from: pdfDoc)
        let xmpRaw = extractXMP(from: pdfDoc)
        let hasC2PA = xmpRaw?.contains("c2pa") ?? false
        let hasGenAIMetadata = detectGenAI(in: xmpRaw)
        let outputIntents = extractOutputIntents(from: pdfDoc, warnings: &warnings)

        return DocumentMetadata(
            title: title,
            author: author,
            subject: subject,
            keywords: keywords,
            creationDate: creationDate,
            modificationDate: modificationDate,
            trapped: trapped,
            outputIntents: outputIntents,
            xmpRaw: xmpRaw,
            hasC2PA: hasC2PA,
            hasGenAIMetadata: hasGenAIMetadata
        )
    }

    // MARK: - Private Helpers

    private static func extractKeywords(from attributes: [AnyHashable: Any]) -> String? {
        if let keywords = attributes[PDFDocumentAttribute.keywordsAttribute] as? String {
            return keywords
        }
        if let keywordArray = attributes[PDFDocumentAttribute.keywordsAttribute] as? [String] {
            return keywordArray.joined(separator: ", ")
        }
        return nil
    }

    private static func extractTrapped(from pdfDoc: PDFDocument) -> String? {
        guard let cgDoc = pdfDoc.documentRef else { return nil }
        guard let infoDict = cgDoc.info else { return nil }

        var trappedName: UnsafePointer<CChar>?
        if CGPDFDictionaryGetName(infoDict, "Trapped", &trappedName), let name = trappedName {
            return String(cString: name)
        }

        return nil
    }

    private static func extractXMP(from pdfDoc: PDFDocument) -> String? {
        guard let cgDoc = pdfDoc.documentRef else { return nil }
        guard let catalog = cgDoc.catalog else { return nil }

        var metadataStream: CGPDFStreamRef?
        guard CGPDFDictionaryGetStream(catalog, "Metadata", &metadataStream),
              let stream = metadataStream else {
            return nil
        }

        var format: CGPDFDataFormat = .raw
        guard let data = CGPDFStreamCopyData(stream, &format) else {
            return nil
        }

        return String(data: data as Data, encoding: .utf8)
    }

    private static func detectGenAI(in xmp: String?) -> Bool {
        guard let xmp = xmp else { return false }
        return xmp.contains("DigitalSourceType") || xmp.contains("aig:")
    }

    private static func extractOutputIntents(from pdfDoc: PDFDocument, warnings: inout [ParseWarning]) -> [OutputIntent] {
        guard let cgDoc = pdfDoc.documentRef else { return [] }
        guard let catalog = cgDoc.catalog else { return [] }

        var intentArray: CGPDFArrayRef?
        guard CGPDFDictionaryGetArray(catalog, "OutputIntents", &intentArray),
              let intents = intentArray else {
            return []
        }

        var results: [OutputIntent] = []
        let count = CGPDFArrayGetCount(intents)

        for i in 0..<count {
            var intentDict: CGPDFDictionaryRef?
            guard CGPDFArrayGetDictionary(intents, i, &intentDict),
                  let dict = intentDict else {
                continue
            }

            var subtypePtr: UnsafePointer<CChar>?
            let subtype: String
            if CGPDFDictionaryGetName(dict, "S", &subtypePtr), let s = subtypePtr {
                subtype = String(cString: s)
            } else {
                subtype = "Unknown"
            }

            let outputCondition = extractStringValue(from: dict, key: "OutputCondition")
            let outputConditionIdentifier = extractStringValue(from: dict, key: "OutputConditionIdentifier")
            let registryName = extractStringValue(from: dict, key: "RegistryName")

            results.append(OutputIntent(
                subtype: subtype,
                outputCondition: outputCondition,
                outputConditionIdentifier: outputConditionIdentifier,
                registryName: registryName
            ))
        }

        return results
    }

    private static func extractStringValue(from dict: CGPDFDictionaryRef, key: String) -> String? {
        var stringRef: CGPDFStringRef?
        if CGPDFDictionaryGetString(dict, key, &stringRef), let str = stringRef {
            if let cfString = CGPDFStringCopyTextString(str) {
                return cfString as String
            }
        }
        return nil
    }
}
