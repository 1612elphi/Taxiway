import Foundation
import CoreGraphics
import PDFKit

/// Extracts spot colour names used in gradient shadings from PDF page resources.
///
/// For each page, reads `Resources/Shading` and inspects the `/ColorSpace`
/// of each shading entry. Separation colour spaces yield a single spot name;
/// DeviceN colour spaces yield multiple names. Process colour names are filtered out.
struct ShadingExtractor: Sendable {

    private static let processNames: Set<String> = [
        "Cyan", "Magenta", "Yellow", "Black",
        "Red", "Green", "Blue", "None", "All"
    ]

    /// Extract spot colour names used in gradient shadings across all pages.
    static func extract(from pdfDoc: PDFDocument) -> [SpotColourInfo] {
        var spotsByName: [String: Set<Int>] = [:]

        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i),
                  let pageRef = page.pageRef,
                  let pageDict = pageRef.dictionary else { continue }

            var resourcesDict: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
                  let resources = resourcesDict else { continue }

            var shadingDict: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(resources, "Shading", &shadingDict),
                  let shadings = shadingDict else { continue }

            // Iterate all shading entries on this page
            final class ShadingCollector: @unchecked Sendable {
                var names: [(String, Int)] = []
                let pageIndex: Int
                init(pageIndex: Int) { self.pageIndex = pageIndex }
            }

            let collector = ShadingCollector(pageIndex: i)
            let context = Unmanaged.passUnretained(collector).toOpaque()

            CGPDFDictionaryApplyBlock(shadings, { (_, value, info) -> Bool in
                let collector = Unmanaged<ShadingCollector>.fromOpaque(info!).takeUnretainedValue()

                var shadingRef: CGPDFDictionaryRef?
                // Shading can be a dictionary or a stream (which also has a dictionary)
                if CGPDFObjectGetValue(value, .dictionary, &shadingRef) {
                    // good
                } else {
                    var stream: CGPDFStreamRef?
                    if CGPDFObjectGetValue(value, .stream, &stream), let s = stream {
                        shadingRef = CGPDFStreamGetDictionary(s)
                    }
                }

                guard let shading = shadingRef else { return true }

                // Read /ColorSpace — can be a name, array, or indirect reference
                var csObj: CGPDFObjectRef?
                guard CGPDFDictionaryGetObject(shading, "ColorSpace", &csObj), let cs = csObj else { return true }

                let spotNames = extractSpotNames(from: cs)
                for name in spotNames {
                    collector.names.append((name, collector.pageIndex))
                }

                return true
            }, context)

            for (name, pageIndex) in collector.names {
                spotsByName[name, default: []].insert(pageIndex)
            }
        }

        return spotsByName.map { name, pages in
            SpotColourInfo(name: name, pagesUsedOn: pages.sorted())
        }.sorted { $0.name < $1.name }
    }

    /// Extract spot colour names from a colour space PDF object.
    private static func extractSpotNames(from csObj: CGPDFObjectRef) -> [String] {
        // Try as array first (Separation or DeviceN)
        var csArray: CGPDFArrayRef?
        if CGPDFObjectGetValue(csObj, .array, &csArray), let arr = csArray {
            var csName: UnsafePointer<CChar>?
            guard CGPDFArrayGetName(arr, 0, &csName), let name = csName else { return [] }
            let nameStr = String(cString: name)

            switch nameStr {
            case "Separation":
                var spotName: UnsafePointer<CChar>?
                if CGPDFArrayGetName(arr, 1, &spotName), let sn = spotName {
                    let spotNameStr = String(cString: sn)
                    if !processNames.contains(spotNameStr) {
                        return [spotNameStr]
                    }
                }

            case "DeviceN":
                var namesArray: CGPDFArrayRef?
                if CGPDFArrayGetArray(arr, 1, &namesArray), let names = namesArray {
                    let count = CGPDFArrayGetCount(names)
                    var result: [String] = []
                    for j in 0..<count {
                        var entryName: UnsafePointer<CChar>?
                        if CGPDFArrayGetName(names, j, &entryName), let en = entryName {
                            let entryNameStr = String(cString: en)
                            if !processNames.contains(entryNameStr) {
                                result.append(entryNameStr)
                            }
                        }
                    }
                    return result
                }

            default:
                break
            }
        }

        return []
    }
}
