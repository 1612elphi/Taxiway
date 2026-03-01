import Foundation
import CoreGraphics
import PDFKit

/// Extracts font information from a PDF document by walking CGPDF resource dictionaries.
struct FontExtractor: Sendable {

    /// Collected font data before deduplication.
    private struct RawFontEntry {
        let name: String
        let type: FontType
        let isEmbedded: Bool
        let isSubset: Bool
        let pageIndex: Int
    }

    /// Extracts all fonts from the PDF document, deduplicating by name.
    static func extract(from pdfDoc: PDFDocument, warnings: inout [ParseWarning]) -> [FontInfo] {
        var rawEntries: [RawFontEntry] = []

        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i),
                  let pageRef = page.pageRef else {
                continue
            }

            guard let pageDict = pageRef.dictionary else {
                continue
            }

            var resourcesDict: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
                  let resources = resourcesDict else {
                continue
            }

            var fontDict: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(resources, "Font", &fontDict),
                  let fonts = fontDict else {
                continue
            }

            let pageIndex = i
            var pageWarnings: [ParseWarning] = []
            let entries = extractFontsFromDict(fonts, pageIndex: pageIndex, warnings: &pageWarnings)
            rawEntries.append(contentsOf: entries)
            warnings.append(contentsOf: pageWarnings)
        }

        return deduplicateFonts(rawEntries)
    }

    private static func extractFontsFromDict(_ fontDict: CGPDFDictionaryRef, pageIndex: Int, warnings: inout [ParseWarning]) -> [RawFontEntry] {

        final class Collector: @unchecked Sendable {
            var entries: [RawFontEntry] = []
            var warnings: [ParseWarning] = []
            let pageIndex: Int
            init(pageIndex: Int) { self.pageIndex = pageIndex }
        }

        let collector = Collector(pageIndex: pageIndex)
        let context = Unmanaged.passUnretained(collector).toOpaque()

        CGPDFDictionaryApplyBlock(fontDict, { (key, value, info) -> Bool in
            let collector = Unmanaged<Collector>.fromOpaque(info!).takeUnretainedValue()

            var fontSubDict: CGPDFDictionaryRef?
            guard CGPDFObjectGetValue(value, .dictionary, &fontSubDict),
                  let fontDict = fontSubDict else {
                return true // continue iteration
            }

            // Extract font name from /BaseFont
            var baseFont: UnsafePointer<CChar>?
            let fontName: String
            if CGPDFDictionaryGetName(fontDict, "BaseFont", &baseFont), let bf = baseFont {
                fontName = String(cString: bf)
            } else {
                fontName = String(cString: key)
            }

            // Extract font type from /Subtype
            let fontType = extractFontType(from: fontDict)

            // Check embedding via /FontDescriptor
            let isEmbedded = checkEmbedding(fontDict)

            // Check subset prefix: 6 uppercase letters + "+"
            let isSubset = checkSubset(fontName)

            collector.entries.append(RawFontEntry(
                name: fontName,
                type: fontType,
                isEmbedded: isEmbedded,
                isSubset: isSubset,
                pageIndex: collector.pageIndex
            ))

            return true
        }, context)

        let entries = collector.entries
        warnings.append(contentsOf: collector.warnings)
        return entries
    }

    private static func extractFontType(from fontDict: CGPDFDictionaryRef) -> FontType {
        var subtype: UnsafePointer<CChar>?
        guard CGPDFDictionaryGetName(fontDict, "Subtype", &subtype),
              let st = subtype else {
            return .unknown
        }

        let subtypeStr = String(cString: st)

        switch subtypeStr {
        case "Type1":
            return .type1
        case "TrueType":
            return .trueType
        case "Type3":
            return .type3
        case "MMType1":
            return .mmType1
        case "Type0":
            return extractCIDFontType(from: fontDict)
        case "CIDFontType0":
            return .cidFontType0
        case "CIDFontType2":
            return .cidFontType2
        default:
            return .unknown
        }
    }

    private static func extractCIDFontType(from fontDict: CGPDFDictionaryRef) -> FontType {
        var descendantsArray: CGPDFArrayRef?
        guard CGPDFDictionaryGetArray(fontDict, "DescendantFonts", &descendantsArray),
              let descendants = descendantsArray else {
            return .openTypeCFF
        }

        var cidFontDict: CGPDFDictionaryRef?
        guard CGPDFArrayGetDictionary(descendants, 0, &cidFontDict),
              let cidFont = cidFontDict else {
            return .openTypeCFF
        }

        var cidSubtype: UnsafePointer<CChar>?
        guard CGPDFDictionaryGetName(cidFont, "Subtype", &cidSubtype),
              let cs = cidSubtype else {
            return .openTypeCFF
        }

        let cidSubtypeStr = String(cString: cs)
        switch cidSubtypeStr {
        case "CIDFontType0":
            return .cidFontType0
        case "CIDFontType2":
            return .cidFontType2
        default:
            return .openTypeCFF
        }
    }

    private static func checkEmbedding(_ fontDict: CGPDFDictionaryRef) -> Bool {
        var descriptorDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(fontDict, "FontDescriptor", &descriptorDict),
              let descriptor = descriptorDict else {
            return false
        }

        var stream: CGPDFStreamRef?
        if CGPDFDictionaryGetStream(descriptor, "FontFile", &stream) { return true }
        if CGPDFDictionaryGetStream(descriptor, "FontFile2", &stream) { return true }
        if CGPDFDictionaryGetStream(descriptor, "FontFile3", &stream) { return true }

        return false
    }

    private static func checkSubset(_ fontName: String) -> Bool {
        guard fontName.count > 7 else { return false }
        let prefix = fontName.prefix(7)
        let letters = prefix.prefix(6)
        let plus = prefix.last
        return letters.allSatisfy { $0.isUppercase && $0.isLetter } && plus == "+"
    }

    private static func deduplicateFonts(_ entries: [RawFontEntry]) -> [FontInfo] {
        var fontMap: [String: (type: FontType, isEmbedded: Bool, isSubset: Bool, pages: Set<Int>)] = [:]

        for entry in entries {
            if var existing = fontMap[entry.name] {
                existing.pages.insert(entry.pageIndex)
                fontMap[entry.name] = existing
            } else {
                fontMap[entry.name] = (
                    type: entry.type,
                    isEmbedded: entry.isEmbedded,
                    isSubset: entry.isSubset,
                    pages: [entry.pageIndex]
                )
            }
        }

        return fontMap.map { name, info in
            FontInfo(
                name: name,
                type: info.type,
                isEmbedded: info.isEmbedded,
                isSubset: info.isSubset,
                pagesUsedOn: info.pages.sorted()
            )
        }.sorted { $0.name < $1.name }
    }
}
