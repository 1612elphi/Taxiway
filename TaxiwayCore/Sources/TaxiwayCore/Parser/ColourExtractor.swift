import Foundation
import CoreGraphics
import PDFKit

/// Extracts colour space and spot colour information from a PDF document.
struct ColourExtractor: Sendable {

    private struct RawColourSpace {
        let name: ColourSpaceName
        let pageIndex: Int
        let iccProfileName: String?
    }

    private struct RawSpotColour {
        let name: String
        let pageIndex: Int
    }

    /// Extracts all colour spaces from the PDF document.
    static func extractColourSpaces(from pdfDoc: PDFDocument, warnings: inout [ParseWarning]) -> [ColourSpaceInfo] {
        var rawSpaces: [RawColourSpace] = []

        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i),
                  let pageRef = page.pageRef,
                  let pageDict = pageRef.dictionary else {
                continue
            }

            var resourcesDict: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
                  let resources = resourcesDict else {
                continue
            }

            var csDict: CGPDFDictionaryRef?
            if CGPDFDictionaryGetDictionary(resources, "ColorSpace", &csDict), let colourSpaces = csDict {
                let pageIndex = i

                final class Collector: @unchecked Sendable {
                    var spaces: [RawColourSpace] = []
                    var warnings: [ParseWarning] = []
                    let pageIndex: Int
                    init(pageIndex: Int) { self.pageIndex = pageIndex }
                }

                let collector = Collector(pageIndex: pageIndex)
                let context = Unmanaged.passUnretained(collector).toOpaque()

                CGPDFDictionaryApplyBlock(colourSpaces, { (key, value, info) -> Bool in
                    let collector = Unmanaged<Collector>.fromOpaque(info!).takeUnretainedValue()

                    // Try as array first (parameterised colour space)
                    var csArray: CGPDFArrayRef?
                    if CGPDFObjectGetValue(value, .array, &csArray), let arr = csArray {
                        var csName: UnsafePointer<CChar>?
                        if CGPDFArrayGetName(arr, 0, &csName), let name = csName {
                            let nameStr = String(cString: name)
                            let csType = mapColourSpaceName(nameStr)
                            var iccProfileName: String? = nil

                            if nameStr == "ICCBased" {
                                iccProfileName = extractICCProfileName(from: arr)
                            }

                            collector.spaces.append(RawColourSpace(
                                name: csType,
                                pageIndex: collector.pageIndex,
                                iccProfileName: iccProfileName
                            ))
                        }
                    } else {
                        // Try as name (simple colour space reference)
                        var csName: UnsafePointer<CChar>?
                        if CGPDFObjectGetValue(value, .name, &csName), let name = csName {
                            let csType = mapColourSpaceName(String(cString: name))
                            collector.spaces.append(RawColourSpace(
                                name: csType,
                                pageIndex: collector.pageIndex,
                                iccProfileName: nil
                            ))
                        }
                    }

                    return true
                }, context)

                rawSpaces.append(contentsOf: collector.spaces)
                warnings.append(contentsOf: collector.warnings)
            }
        }

        return deduplicateColourSpaces(rawSpaces)
    }

    /// Extracts all spot colours from the PDF document.
    static func extractSpotColours(from pdfDoc: PDFDocument, warnings: inout [ParseWarning]) -> [SpotColourInfo] {
        var rawSpots: [RawSpotColour] = []

        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i),
                  let pageRef = page.pageRef,
                  let pageDict = pageRef.dictionary else {
                continue
            }

            var resourcesDict: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
                  let resources = resourcesDict else {
                continue
            }

            var csDict: CGPDFDictionaryRef?
            if CGPDFDictionaryGetDictionary(resources, "ColorSpace", &csDict), let colourSpaces = csDict {
                let pageIndex = i

                final class SpotCollector: @unchecked Sendable {
                    var spots: [RawSpotColour] = []
                    let pageIndex: Int
                    init(pageIndex: Int) { self.pageIndex = pageIndex }
                }

                let collector = SpotCollector(pageIndex: pageIndex)
                let context = Unmanaged.passUnretained(collector).toOpaque()

                CGPDFDictionaryApplyBlock(colourSpaces, { (key, value, info) -> Bool in
                    let collector = Unmanaged<SpotCollector>.fromOpaque(info!).takeUnretainedValue()

                    var csArray: CGPDFArrayRef?
                    guard CGPDFObjectGetValue(value, .array, &csArray), let arr = csArray else {
                        return true
                    }

                    var csName: UnsafePointer<CChar>?
                    guard CGPDFArrayGetName(arr, 0, &csName), let name = csName else {
                        return true
                    }

                    let nameStr = String(cString: name)

                    if nameStr == "Separation" {
                        var spotName: UnsafePointer<CChar>?
                        if CGPDFArrayGetName(arr, 1, &spotName), let sn = spotName {
                            let spotNameStr = String(cString: sn)
                            if spotNameStr != "All" && spotNameStr != "None" {
                                collector.spots.append(RawSpotColour(name: spotNameStr, pageIndex: collector.pageIndex))
                            }
                        }
                    } else if nameStr == "DeviceN" {
                        var namesArray: CGPDFArrayRef?
                        if CGPDFArrayGetArray(arr, 1, &namesArray), let names = namesArray {
                            let count = CGPDFArrayGetCount(names)
                            for j in 0..<count {
                                var compName: UnsafePointer<CChar>?
                                if CGPDFArrayGetName(names, j, &compName), let cn = compName {
                                    let compNameStr = String(cString: cn)
                                    let processNames = ["Cyan", "Magenta", "Yellow", "Black", "Red", "Green", "Blue", "None", "All"]
                                    if !processNames.contains(compNameStr) {
                                        collector.spots.append(RawSpotColour(name: compNameStr, pageIndex: collector.pageIndex))
                                    }
                                }
                            }
                        }
                    }

                    return true
                }, context)

                rawSpots.append(contentsOf: collector.spots)
            }
        }

        return deduplicateSpotColours(rawSpots)
    }

    // MARK: - Helpers

    private static func mapColourSpaceName(_ name: String) -> ColourSpaceName {
        switch name {
        case "DeviceGray": return .deviceGray
        case "DeviceRGB": return .deviceRGB
        case "DeviceCMYK": return .deviceCMYK
        case "ICCBased": return .iccBased
        case "CalGray": return .calGray
        case "CalRGB": return .calRGB
        case "Lab": return .lab
        case "Indexed": return .indexed
        case "Separation": return .separation
        case "DeviceN": return .deviceN
        case "Pattern": return .pattern
        default: return .unknown
        }
    }

    private static func extractICCProfileName(from array: CGPDFArrayRef) -> String? {
        var stream: CGPDFStreamRef?
        guard CGPDFArrayGetStream(array, 1, &stream), let iccStream = stream else {
            return nil
        }

        var format: CGPDFDataFormat = .raw
        guard let data = CGPDFStreamCopyData(iccStream, &format) else {
            return nil
        }

        let cfData = data as Data
        // ICC profiles have a tag table; extracting description is complex.
        // Return nil for now — a full ICC parser would be needed for profile names.
        if cfData.count > 132 {
            return nil
        }

        return nil
    }

    private static func deduplicateColourSpaces(_ entries: [RawColourSpace]) -> [ColourSpaceInfo] {
        var csMap: [ColourSpaceName: (pages: Set<Int>, iccProfileName: String?)] = [:]

        for entry in entries {
            if var existing = csMap[entry.name] {
                existing.pages.insert(entry.pageIndex)
                if existing.iccProfileName == nil && entry.iccProfileName != nil {
                    existing.iccProfileName = entry.iccProfileName
                }
                csMap[entry.name] = existing
            } else {
                csMap[entry.name] = (pages: [entry.pageIndex], iccProfileName: entry.iccProfileName)
            }
        }

        return csMap.map { name, info in
            ColourSpaceInfo(
                name: name,
                pagesUsedOn: info.pages.sorted(),
                iccProfileName: info.iccProfileName
            )
        }.sorted { $0.name.rawValue < $1.name.rawValue }
    }

    private static func deduplicateSpotColours(_ entries: [RawSpotColour]) -> [SpotColourInfo] {
        var spotMap: [String: Set<Int>] = [:]

        for entry in entries {
            if var existing = spotMap[entry.name] {
                existing.insert(entry.pageIndex)
                spotMap[entry.name] = existing
            } else {
                spotMap[entry.name] = [entry.pageIndex]
            }
        }

        return spotMap.map { name, pages in
            SpotColourInfo(name: name, pagesUsedOn: pages.sorted())
        }.sorted { $0.name < $1.name }
    }
}
