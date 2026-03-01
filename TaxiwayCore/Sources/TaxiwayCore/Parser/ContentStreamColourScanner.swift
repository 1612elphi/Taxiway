import Foundation
import CoreGraphics

/// Scans PDF page content streams to extract actual colour values used in
/// drawing operations (text, fills, strokes), along with their usage contexts.
///
/// Tracks colour-setting operators (`g`, `rg`, `k`, `cs`/`sc`, etc.) and
/// records which colours are used by text-showing and path-painting operators.
struct ContentStreamColourScanner: Sendable {

    /// Resolved colour space info from the page's Resources/ColorSpace dictionary.
    struct ColourSpaceEntry: Sendable {
        let mode: ColourMode
        let componentCount: Int
        let isSpot: Bool
        let spotName: String?
    }

    typealias ColourSpaceLookup = [String: ColourSpaceEntry]

    /// Resolved ExtGState entry for overprint state.
    struct ExtGStateEntry: Sendable {
        let overprintFill: Bool?
        let overprintStroke: Bool?
    }

    typealias ExtGStateLookup = [String: ExtGStateEntry]

    /// A raw colour usage recorded during scanning, before deduplication.
    struct RawColourUsage: Sendable {
        let mode: ColourMode
        let components: [Double]
        let isSpot: Bool
        let spotName: String?
        let context: ColourUsageContext
        let pageIndex: Int
        let overprintEnabled: Bool
    }

    // MARK: - Colour Space Lookup

    /// Builds a lookup table mapping resource names to colour space info for a page.
    static func buildLookup(pageRef: CGPDFPage) -> ColourSpaceLookup {
        guard let pageDict = pageRef.dictionary else { return [:] }

        var resourcesDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
              let resources = resourcesDict else { return [:] }

        var csDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(resources, "ColorSpace", &csDict),
              let colourSpaces = csDict else { return [:] }

        final class LookupCollector: @unchecked Sendable {
            var lookup: ColourSpaceLookup = [:]
        }

        let collector = LookupCollector()
        let context = Unmanaged.passUnretained(collector).toOpaque()

        CGPDFDictionaryApplyBlock(colourSpaces, { (key, value, info) -> Bool in
            let collector = Unmanaged<LookupCollector>.fromOpaque(info!).takeUnretainedValue()
            let resourceName = String(cString: key)

            var csArray: CGPDFArrayRef?
            if CGPDFObjectGetValue(value, .array, &csArray), let arr = csArray {
                var csName: UnsafePointer<CChar>?
                guard CGPDFArrayGetName(arr, 0, &csName), let name = csName else { return true }
                let nameStr = String(cString: name)

                switch nameStr {
                case "ICCBased":
                    // Get /N from the stream dictionary to determine component count
                    var stream: CGPDFStreamRef?
                    if CGPDFArrayGetStream(arr, 1, &stream), let iccStream = stream {
                        let streamDict = CGPDFStreamGetDictionary(iccStream)
                        var n: CGPDFInteger = 0
                        if let dict = streamDict, CGPDFDictionaryGetInteger(dict, "N", &n) {
                            let mode: ColourMode
                            switch n {
                            case 1: mode = .gray
                            case 3: mode = .rgb
                            case 4: mode = .cmyk
                            default: mode = .cmyk
                            }
                            collector.lookup[resourceName] = ColourSpaceEntry(
                                mode: mode, componentCount: Int(n), isSpot: false, spotName: nil)
                        }
                    }

                case "Separation":
                    var spotName: UnsafePointer<CChar>?
                    if CGPDFArrayGetName(arr, 1, &spotName), let sn = spotName {
                        let spotNameStr = String(cString: sn)
                        let processNames = ["Cyan", "Magenta", "Yellow", "Black",
                                             "Red", "Green", "Blue", "None", "All"]
                        let isSpot = !processNames.contains(spotNameStr)
                        // Separation always has 1 tint component
                        collector.lookup[resourceName] = ColourSpaceEntry(
                            mode: .cmyk, componentCount: 1, isSpot: isSpot,
                            spotName: isSpot ? spotNameStr : nil)
                    }

                case "DeviceN":
                    var namesArray: CGPDFArrayRef?
                    if CGPDFArrayGetArray(arr, 1, &namesArray), let names = namesArray {
                        let count = CGPDFArrayGetCount(names)
                        collector.lookup[resourceName] = ColourSpaceEntry(
                            mode: .cmyk, componentCount: Int(count), isSpot: false, spotName: nil)
                    }

                case "DeviceGray", "CalGray":
                    collector.lookup[resourceName] = ColourSpaceEntry(
                        mode: .gray, componentCount: 1, isSpot: false, spotName: nil)

                case "DeviceRGB", "CalRGB":
                    collector.lookup[resourceName] = ColourSpaceEntry(
                        mode: .rgb, componentCount: 3, isSpot: false, spotName: nil)

                case "DeviceCMYK":
                    collector.lookup[resourceName] = ColourSpaceEntry(
                        mode: .cmyk, componentCount: 4, isSpot: false, spotName: nil)

                default:
                    break
                }
            } else {
                // Simple name reference
                var csName: UnsafePointer<CChar>?
                if CGPDFObjectGetValue(value, .name, &csName), let name = csName {
                    let nameStr = String(cString: name)
                    switch nameStr {
                    case "DeviceGray":
                        collector.lookup[resourceName] = ColourSpaceEntry(
                            mode: .gray, componentCount: 1, isSpot: false, spotName: nil)
                    case "DeviceRGB":
                        collector.lookup[resourceName] = ColourSpaceEntry(
                            mode: .rgb, componentCount: 3, isSpot: false, spotName: nil)
                    case "DeviceCMYK":
                        collector.lookup[resourceName] = ColourSpaceEntry(
                            mode: .cmyk, componentCount: 4, isSpot: false, spotName: nil)
                    default:
                        break
                    }
                }
            }

            return true
        }, context)

        return collector.lookup
    }

    // MARK: - ExtGState Lookup

    /// Builds a lookup table for ExtGState entries (overprint flags) on a page.
    static func buildExtGStateLookup(pageRef: CGPDFPage) -> ExtGStateLookup {
        guard let pageDict = pageRef.dictionary else { return [:] }

        var resourcesDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
              let resources = resourcesDict else { return [:] }

        var gsDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(resources, "ExtGState", &gsDict),
              let extGState = gsDict else { return [:] }

        final class GSCollector: @unchecked Sendable {
            var lookup: ExtGStateLookup = [:]
        }

        let collector = GSCollector()
        let context = Unmanaged.passUnretained(collector).toOpaque()

        CGPDFDictionaryApplyBlock(extGState, { (key, value, info) -> Bool in
            let collector = Unmanaged<GSCollector>.fromOpaque(info!).takeUnretainedValue()
            let name = String(cString: key)

            var dict: CGPDFDictionaryRef?
            guard CGPDFObjectGetValue(value, .dictionary, &dict), let gs = dict else { return true }

            // OP = overprint for stroke (and fill if op not present)
            // op = overprint for fill
            var opStroke: CGPDFBoolean = 0
            let hasOP = CGPDFDictionaryGetBoolean(gs, "OP", &opStroke)

            var opFill: CGPDFBoolean = 0
            let hasop = CGPDFDictionaryGetBoolean(gs, "op", &opFill)

            if hasOP || hasop {
                let strokeOverprint = hasOP ? (opStroke != 0) : nil
                // Per PDF spec: if op is absent, fill overprint defaults to OP value
                let fillOverprint: Bool? = hasop ? (opFill != 0) : strokeOverprint
                collector.lookup[name] = ExtGStateEntry(
                    overprintFill: fillOverprint, overprintStroke: strokeOverprint)
            }

            return true
        }, context)

        return collector.lookup
    }

    // MARK: - Scan

    /// Scan a page's content stream for colour usage.
    static func scan(page pageRef: CGPDFPage, pageIndex: Int,
                     lookup: ColourSpaceLookup,
                     extGStateLookup: ExtGStateLookup = [:]) -> [RawColourUsage] {
        let contentStream = CGPDFContentStreamCreateWithPage(pageRef)
        defer { CGPDFContentStreamRelease(contentStream) }

        guard let table = CGPDFOperatorTableCreate() else { return [] }

        // Graphics state stack
        CGPDFOperatorTableSetCallback(table, "q") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.saveState()
        }

        CGPDFOperatorTableSetCallback(table, "Q") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.restoreState()
        }

        // gs - set graphics state from ExtGState resource
        CGPDFOperatorTableSetCallback(table, "gs") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var namePtr: UnsafePointer<CChar>?
            guard CGPDFScannerPopName(scanner, &namePtr), let name = namePtr else { return }
            ctx.applyExtGState(name: String(cString: name))
        }

        // --- Device colour operators ---

        // g - DeviceGray fill
        CGPDFOperatorTableSetCallback(table, "g") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var g: CGPDFReal = 0
            guard CGPDFScannerPopNumber(scanner, &g) else { return }
            ctx.setFillColour(mode: .gray, components: [Double(g)], isSpot: false, spotName: nil)
        }

        // G - DeviceGray stroke
        CGPDFOperatorTableSetCallback(table, "G") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var g: CGPDFReal = 0
            guard CGPDFScannerPopNumber(scanner, &g) else { return }
            ctx.setStrokeColour(mode: .gray, components: [Double(g)], isSpot: false, spotName: nil)
        }

        // rg - DeviceRGB fill
        CGPDFOperatorTableSetCallback(table, "rg") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var r: CGPDFReal = 0, g: CGPDFReal = 0, b: CGPDFReal = 0
            guard CGPDFScannerPopNumber(scanner, &b),
                  CGPDFScannerPopNumber(scanner, &g),
                  CGPDFScannerPopNumber(scanner, &r) else { return }
            ctx.setFillColour(mode: .rgb, components: [Double(r), Double(g), Double(b)],
                              isSpot: false, spotName: nil)
        }

        // RG - DeviceRGB stroke
        CGPDFOperatorTableSetCallback(table, "RG") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var r: CGPDFReal = 0, g: CGPDFReal = 0, b: CGPDFReal = 0
            guard CGPDFScannerPopNumber(scanner, &b),
                  CGPDFScannerPopNumber(scanner, &g),
                  CGPDFScannerPopNumber(scanner, &r) else { return }
            ctx.setStrokeColour(mode: .rgb, components: [Double(r), Double(g), Double(b)],
                                isSpot: false, spotName: nil)
        }

        // k - DeviceCMYK fill
        CGPDFOperatorTableSetCallback(table, "k") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var c: CGPDFReal = 0, m: CGPDFReal = 0, y: CGPDFReal = 0, kk: CGPDFReal = 0
            guard CGPDFScannerPopNumber(scanner, &kk),
                  CGPDFScannerPopNumber(scanner, &y),
                  CGPDFScannerPopNumber(scanner, &m),
                  CGPDFScannerPopNumber(scanner, &c) else { return }
            ctx.setFillColour(mode: .cmyk,
                              components: [Double(c), Double(m), Double(y), Double(kk)],
                              isSpot: false, spotName: nil)
        }

        // K - DeviceCMYK stroke
        CGPDFOperatorTableSetCallback(table, "K") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var c: CGPDFReal = 0, m: CGPDFReal = 0, y: CGPDFReal = 0, kk: CGPDFReal = 0
            guard CGPDFScannerPopNumber(scanner, &kk),
                  CGPDFScannerPopNumber(scanner, &y),
                  CGPDFScannerPopNumber(scanner, &m),
                  CGPDFScannerPopNumber(scanner, &c) else { return }
            ctx.setStrokeColour(mode: .cmyk,
                                components: [Double(c), Double(m), Double(y), Double(kk)],
                                isSpot: false, spotName: nil)
        }

        // --- Colour space operators ---

        // cs - set fill colour space
        CGPDFOperatorTableSetCallback(table, "cs") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var namePtr: UnsafePointer<CChar>?
            guard CGPDFScannerPopName(scanner, &namePtr), let name = namePtr else { return }
            ctx.setFillSpace(name: String(cString: name))
        }

        // CS - set stroke colour space
        CGPDFOperatorTableSetCallback(table, "CS") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var namePtr: UnsafePointer<CChar>?
            guard CGPDFScannerPopName(scanner, &namePtr), let name = namePtr else { return }
            ctx.setStrokeSpace(name: String(cString: name))
        }

        // sc - set fill colour components
        CGPDFOperatorTableSetCallback(table, "sc") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.popFillColourComponents(scanner: scanner)
        }

        // SC - set stroke colour components
        CGPDFOperatorTableSetCallback(table, "SC") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.popStrokeColourComponents(scanner: scanner)
        }

        // scn - set fill colour (extended, may have pattern name)
        CGPDFOperatorTableSetCallback(table, "scn") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.popFillColourComponents(scanner: scanner)
        }

        // SCN - set stroke colour (extended, may have pattern name)
        CGPDFOperatorTableSetCallback(table, "SCN") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.popStrokeColourComponents(scanner: scanner)
        }

        // --- Text operators (record fill colour as textFill) ---

        CGPDFOperatorTableSetCallback(table, "Tj") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .textFill, isFill: true)
        }

        CGPDFOperatorTableSetCallback(table, "TJ") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .textFill, isFill: true)
        }

        CGPDFOperatorTableSetCallback(table, "'") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .textFill, isFill: true)
        }

        CGPDFOperatorTableSetCallback(table, "\"") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .textFill, isFill: true)
        }

        // --- Path fill operators ---

        CGPDFOperatorTableSetCallback(table, "f") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .pathFill, isFill: true)
        }

        CGPDFOperatorTableSetCallback(table, "F") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .pathFill, isFill: true)
        }

        CGPDFOperatorTableSetCallback(table, "f*") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .pathFill, isFill: true)
        }

        // --- Path stroke operators ---

        CGPDFOperatorTableSetCallback(table, "S") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .pathStroke, isFill: false)
        }

        CGPDFOperatorTableSetCallback(table, "s") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .pathStroke, isFill: false)
        }

        // --- Combined fill+stroke operators ---

        CGPDFOperatorTableSetCallback(table, "B") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .pathFill, isFill: true)
            ctx.recordUsage(context: .pathStroke, isFill: false)
        }

        CGPDFOperatorTableSetCallback(table, "B*") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .pathFill, isFill: true)
            ctx.recordUsage(context: .pathStroke, isFill: false)
        }

        CGPDFOperatorTableSetCallback(table, "b") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .pathFill, isFill: true)
            ctx.recordUsage(context: .pathStroke, isFill: false)
        }

        CGPDFOperatorTableSetCallback(table, "b*") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordUsage(context: .pathFill, isFill: true)
            ctx.recordUsage(context: .pathStroke, isFill: false)
        }

        let scanCtx = ScanContext(pageIndex: pageIndex, lookup: lookup, extGStateLookup: extGStateLookup)
        let contextPtr = Unmanaged.passUnretained(scanCtx).toOpaque()

        let pdfScanner = CGPDFScannerCreate(contentStream, table, contextPtr)
        CGPDFScannerScan(pdfScanner)
        CGPDFScannerRelease(pdfScanner)
        CGPDFOperatorTableRelease(table)

        return scanCtx.usages
    }

    // MARK: - Deduplication

    /// Merges raw usages by quantized colour identity, unioning contexts and pages.
    static func deduplicate(_ rawUsages: [RawColourUsage]) -> [ColourUsageInfo] {
        struct AccumulatedUsage {
            let mode: ColourMode
            let components: [Double]
            let isSpot: Bool
            let spotName: String?
            var contexts: ColourUsageContext
            var pages: Set<Int>
        }

        var map: [String: AccumulatedUsage] = [:]

        for usage in rawUsages {
            let key = ColourUsageInfo.quantizedID(
                mode: usage.mode, components: usage.components, spotName: usage.spotName)

            if var existing = map[key] {
                existing.contexts.formUnion(usage.context)
                existing.pages.insert(usage.pageIndex)
                map[key] = existing
            } else {
                map[key] = AccumulatedUsage(
                    mode: usage.mode,
                    components: usage.components,
                    isSpot: usage.isSpot,
                    spotName: usage.spotName,
                    contexts: usage.context,
                    pages: [usage.pageIndex]
                )
            }
        }

        return map.map { key, acc in
            let name = ColourUsageInfo.displayName(
                mode: acc.mode, components: acc.components, spotName: acc.spotName)

            let inkSum: Double?
            if acc.mode == .cmyk && acc.components.count == 4 {
                inkSum = acc.components.reduce(0, +) * 100
            } else {
                inkSum = nil
            }

            return ColourUsageInfo(
                id: key,
                name: name,
                colourType: acc.isSpot ? .spot : .process,
                mode: acc.mode,
                components: acc.components,
                inkSum: inkSum,
                usageContexts: acc.contexts,
                pagesUsedOn: acc.pages.sorted()
            )
        }.sorted { a, b in
            // Spot colours first, then by name
            if a.colourType != b.colourType {
                return a.colourType == .spot
            }
            return a.name < b.name
        }
    }
}

// MARK: - Scan Context

private final class ScanContext: @unchecked Sendable {
    let pageIndex: Int
    let lookup: ContentStreamColourScanner.ColourSpaceLookup
    let extGStateLookup: ContentStreamColourScanner.ExtGStateLookup

    /// Colour state: (mode, components, isSpot, spotName)
    struct ColourState {
        var mode: ColourMode
        var components: [Double]
        var isSpot: Bool
        var spotName: String?
        var spaceName: String?
    }

    struct GraphicsState {
        var fillColour: ColourState
        var strokeColour: ColourState
        var fillSpaceName: String?
        var strokeSpaceName: String?
        var overprintFill: Bool = false
        var overprintStroke: Bool = false
    }

    private var stateStack: [GraphicsState] = []
    private var currentState: GraphicsState

    var usages: [ContentStreamColourScanner.RawColourUsage] = []

    init(pageIndex: Int, lookup: ContentStreamColourScanner.ColourSpaceLookup,
         extGStateLookup: ContentStreamColourScanner.ExtGStateLookup = [:]) {
        self.pageIndex = pageIndex
        self.lookup = lookup
        self.extGStateLookup = extGStateLookup
        // Default graphics state: DeviceGray black fill, DeviceGray black stroke
        let defaultColour = ColourState(mode: .gray, components: [0], isSpot: false, spotName: nil, spaceName: nil)
        self.currentState = GraphicsState(
            fillColour: defaultColour,
            strokeColour: defaultColour,
            fillSpaceName: nil,
            strokeSpaceName: nil
        )
    }

    func saveState() {
        stateStack.append(currentState)
    }

    func restoreState() {
        if let restored = stateStack.popLast() {
            currentState = restored
        }
    }

    func setFillColour(mode: ColourMode, components: [Double], isSpot: Bool, spotName: String?) {
        currentState.fillColour = ColourState(
            mode: mode, components: components, isSpot: isSpot,
            spotName: spotName, spaceName: currentState.fillSpaceName)
    }

    func setStrokeColour(mode: ColourMode, components: [Double], isSpot: Bool, spotName: String?) {
        currentState.strokeColour = ColourState(
            mode: mode, components: components, isSpot: isSpot,
            spotName: spotName, spaceName: currentState.strokeSpaceName)
    }

    func setFillSpace(name: String) {
        currentState.fillSpaceName = name
        // Also resolve the space and set default colour if known
        if let entry = lookup[name] {
            currentState.fillColour = ColourState(
                mode: entry.mode,
                components: Array(repeating: 0.0, count: entry.componentCount),
                isSpot: entry.isSpot,
                spotName: entry.spotName,
                spaceName: name
            )
        } else {
            // Handle built-in space names used directly with cs
            switch name {
            case "DeviceGray":
                currentState.fillColour = ColourState(
                    mode: .gray, components: [0], isSpot: false, spotName: nil, spaceName: name)
            case "DeviceRGB":
                currentState.fillColour = ColourState(
                    mode: .rgb, components: [0, 0, 0], isSpot: false, spotName: nil, spaceName: name)
            case "DeviceCMYK":
                currentState.fillColour = ColourState(
                    mode: .cmyk, components: [0, 0, 0, 0], isSpot: false, spotName: nil, spaceName: name)
            default:
                break
            }
        }
    }

    func setStrokeSpace(name: String) {
        currentState.strokeSpaceName = name
        if let entry = lookup[name] {
            currentState.strokeColour = ColourState(
                mode: entry.mode,
                components: Array(repeating: 0.0, count: entry.componentCount),
                isSpot: entry.isSpot,
                spotName: entry.spotName,
                spaceName: name
            )
        } else {
            switch name {
            case "DeviceGray":
                currentState.strokeColour = ColourState(
                    mode: .gray, components: [0], isSpot: false, spotName: nil, spaceName: name)
            case "DeviceRGB":
                currentState.strokeColour = ColourState(
                    mode: .rgb, components: [0, 0, 0], isSpot: false, spotName: nil, spaceName: name)
            case "DeviceCMYK":
                currentState.strokeColour = ColourState(
                    mode: .cmyk, components: [0, 0, 0, 0], isSpot: false, spotName: nil, spaceName: name)
            default:
                break
            }
        }
    }

    func popFillColourComponents(scanner: OpaquePointer?) {
        guard let scanner = scanner else { return }
        let expectedCount = currentState.fillColour.components.count
        var values: [Double] = []
        for _ in 0..<expectedCount {
            var val: CGPDFReal = 0
            if CGPDFScannerPopNumber(scanner, &val) {
                values.append(Double(val))
            }
        }
        if !values.isEmpty {
            values.reverse() // popped in reverse order
            currentState.fillColour.components = values
        }
    }

    func popStrokeColourComponents(scanner: OpaquePointer?) {
        guard let scanner = scanner else { return }
        let expectedCount = currentState.strokeColour.components.count
        var values: [Double] = []
        for _ in 0..<expectedCount {
            var val: CGPDFReal = 0
            if CGPDFScannerPopNumber(scanner, &val) {
                values.append(Double(val))
            }
        }
        if !values.isEmpty {
            values.reverse()
            currentState.strokeColour.components = values
        }
    }

    func applyExtGState(name: String) {
        guard let entry = extGStateLookup[name] else { return }
        if let fill = entry.overprintFill {
            currentState.overprintFill = fill
        }
        if let stroke = entry.overprintStroke {
            currentState.overprintStroke = stroke
        }
    }

    func recordUsage(context: ColourUsageContext, isFill: Bool) {
        let colour = isFill ? currentState.fillColour : currentState.strokeColour
        let overprintEnabled = isFill ? currentState.overprintFill : currentState.overprintStroke
        usages.append(ContentStreamColourScanner.RawColourUsage(
            mode: colour.mode,
            components: colour.components,
            isSpot: colour.isSpot,
            spotName: colour.spotName,
            context: context,
            pageIndex: pageIndex,
            overprintEnabled: overprintEnabled
        ))
    }
}
