import Foundation
import CoreGraphics
import PDFKit

/// Extracts image (XObject) information from a PDF document.
struct ImageExtractor: Sendable {

    /// Extracts all images from the PDF document.
    static func extract(from pdfDoc: PDFDocument, warnings: inout [ParseWarning]) -> [ImageInfo] {
        var images: [ImageInfo] = []
        var imageCounter = 0

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

            var xobjectDict: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(resources, "XObject", &xobjectDict),
                  let xobjects = xobjectDict else {
                continue
            }

            let pageIndex = i

            // Scan the content stream for image placements (CTM-derived bounds)
            let placements = ContentStreamImageScanner.scan(page: pageRef)
            // Build a lookup: XObject name -> placement
            var placementsByName: [String: ContentStreamImageScanner.ImagePlacement] = [:]
            for p in placements {
                // If an image is placed multiple times, keep the first placement
                if placementsByName[p.name] == nil {
                    placementsByName[p.name] = p
                }
            }

            final class Collector: @unchecked Sendable {
                var images: [ImageInfo] = []
                var warnings: [ParseWarning] = []
                var counter: Int
                let pageIndex: Int
                let placements: [String: ContentStreamImageScanner.ImagePlacement]
                init(counter: Int, pageIndex: Int, placements: [String: ContentStreamImageScanner.ImagePlacement]) {
                    self.counter = counter
                    self.pageIndex = pageIndex
                    self.placements = placements
                }
            }

            let collector = Collector(counter: imageCounter, pageIndex: pageIndex, placements: placementsByName)
            let context = Unmanaged.passUnretained(collector).toOpaque()

            CGPDFDictionaryApplyBlock(xobjects, { (key, value, info) -> Bool in
                let collector = Unmanaged<Collector>.fromOpaque(info!).takeUnretainedValue()

                var streamRef: CGPDFStreamRef?
                guard CGPDFObjectGetValue(value, .stream, &streamRef),
                      let stream = streamRef else {
                    return true
                }

                guard let dict = CGPDFStreamGetDictionary(stream) else { return true }

                // Check /Subtype is /Image
                var subtype: UnsafePointer<CChar>?
                guard CGPDFDictionaryGetName(dict, "Subtype", &subtype),
                      let st = subtype,
                      String(cString: st) == "Image" else {
                    return true
                }

                // Extract dimensions
                var width: CGPDFInteger = 0
                var height: CGPDFInteger = 0
                CGPDFDictionaryGetInteger(dict, "Width", &width)
                CGPDFDictionaryGetInteger(dict, "Height", &height)

                // Extract bits per component
                var bpc: CGPDFInteger = 8
                CGPDFDictionaryGetInteger(dict, "BitsPerComponent", &bpc)

                // Extract colour space
                let colourMode = extractColourMode(from: dict)

                // Extract compression filter
                let compression = extractCompression(from: dict)

                // Check for alpha (SMask)
                var smaskStream: CGPDFStreamRef?
                let hasAlpha = CGPDFDictionaryGetStream(dict, "SMask", &smaskStream)

                // Check ICC profile
                let hasICC = checkICCProfile(from: dict)

                let resourceName = String(cString: key)
                let imageId = "img_\(collector.pageIndex)_\(collector.counter)"
                collector.counter += 1

                // Use content stream placement data if available
                let placement = collector.placements[resourceName]
                let effectiveWidth = placement?.widthPoints ?? Double(width)
                let effectiveHeight = placement?.heightPoints ?? Double(height)
                let bounds = placement?.bounds

                collector.images.append(ImageInfo(
                    id: imageId,
                    pageIndex: collector.pageIndex,
                    widthPixels: Int(width),
                    heightPixels: Int(height),
                    effectiveWidthPoints: effectiveWidth,
                    effectiveHeightPoints: effectiveHeight,
                    colourMode: colourMode,
                    compressionType: compression,
                    bitsPerComponent: Int(bpc),
                    hasICCProfile: hasICC,
                    hasICCOverride: false,
                    hasAlphaChannel: hasAlpha,
                    blendMode: .normal,
                    opacity: 1.0,
                    bounds: bounds
                ))

                return true
            }, context)

            images.append(contentsOf: collector.images)
            imageCounter = collector.counter
        }

        return images
    }

    private static func extractColourMode(from dict: CGPDFDictionaryRef) -> ImageColourMode {
        // Try as name first (simple colour spaces)
        var csName: UnsafePointer<CChar>?
        if CGPDFDictionaryGetName(dict, "ColorSpace", &csName), let name = csName {
            return mapColourSpaceName(String(cString: name))
        }

        // Try as array (parameterised colour spaces)
        var csArray: CGPDFArrayRef?
        if CGPDFDictionaryGetArray(dict, "ColorSpace", &csArray), let arr = csArray {
            var arrayName: UnsafePointer<CChar>?
            if CGPDFArrayGetName(arr, 0, &arrayName), let name = arrayName {
                return mapColourSpaceName(String(cString: name))
            }
        }

        return .unknown
    }

    private static func mapColourSpaceName(_ name: String) -> ImageColourMode {
        switch name {
        case "DeviceGray": return .deviceGray
        case "DeviceRGB": return .deviceRGB
        case "DeviceCMYK": return .deviceCMYK
        case "ICCBased": return .iccBased
        case "Indexed": return .indexed
        case "Separation": return .separation
        case "DeviceN": return .deviceN
        default: return .unknown
        }
    }

    private static func extractCompression(from dict: CGPDFDictionaryRef) -> ImageCompressionType {
        // Try as name (single filter)
        var filterName: UnsafePointer<CChar>?
        if CGPDFDictionaryGetName(dict, "Filter", &filterName), let name = filterName {
            return mapFilterName(String(cString: name))
        }

        // Try as array (multiple filters)
        var filterArray: CGPDFArrayRef?
        if CGPDFDictionaryGetArray(dict, "Filter", &filterArray), let arr = filterArray {
            let count = CGPDFArrayGetCount(arr)
            if count > 0 {
                var name: UnsafePointer<CChar>?
                if CGPDFArrayGetName(arr, count - 1, &name), let n = name {
                    return mapFilterName(String(cString: n))
                }
            }
        }

        return .none
    }

    private static func mapFilterName(_ name: String) -> ImageCompressionType {
        switch name {
        case "DCTDecode": return .jpeg
        case "JPXDecode": return .jpeg2000
        case "JBIG2Decode": return .jbig2
        case "CCITTFaxDecode": return .ccitt
        case "FlateDecode": return .flate
        case "LZWDecode": return .lzw
        case "RunLengthDecode": return .runLength
        default: return .unknown
        }
    }

    private static func checkICCProfile(from dict: CGPDFDictionaryRef) -> Bool {
        var csArray: CGPDFArrayRef?
        if CGPDFDictionaryGetArray(dict, "ColorSpace", &csArray), let arr = csArray {
            var csName: UnsafePointer<CChar>?
            if CGPDFArrayGetName(arr, 0, &csName), let name = csName {
                return String(cString: name) == "ICCBased"
            }
        }
        return false
    }
}
