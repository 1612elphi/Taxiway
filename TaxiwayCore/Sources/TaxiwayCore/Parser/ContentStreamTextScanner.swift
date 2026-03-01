import Foundation
import CoreGraphics

/// Scans PDF page content streams to find text object (BT/ET) placements and
/// their bounding rectangles derived from the text matrix and CTM.
///
/// Raw BT/ET blocks are scanned individually, then merged into logical text
/// frames using spatial proximity (blocks that are vertically stacked within
/// line-spacing distance and horizontally overlapping are combined).
struct ContentStreamTextScanner: Sendable {

    /// A text frame placement found in a content stream.
    struct TextFramePlacement: Sendable {
        let fontName: String
        let fontSize: Double
        let bounds: AnnotationBounds
    }

    /// Scan a page and return merged logical text frames.
    static func scan(page pageRef: CGPDFPage) -> [TextFramePlacement] {
        let raw = scanRaw(page: pageRef)
        return mergeProximateFrames(raw)
    }

    /// Scan a page's content stream and return all raw BT/ET placements.
    static func scanRaw(page pageRef: CGPDFPage) -> [TextFramePlacement] {
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

        // Concatenate matrix
        CGPDFOperatorTableSetCallback(table, "cm") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var a: CGPDFReal = 0, b: CGPDFReal = 0
            var c: CGPDFReal = 0, d: CGPDFReal = 0
            var e: CGPDFReal = 0, f: CGPDFReal = 0

            guard CGPDFScannerPopNumber(scanner, &f),
                  CGPDFScannerPopNumber(scanner, &e),
                  CGPDFScannerPopNumber(scanner, &d),
                  CGPDFScannerPopNumber(scanner, &c),
                  CGPDFScannerPopNumber(scanner, &b),
                  CGPDFScannerPopNumber(scanner, &a) else { return }

            let matrix = CGAffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f)
            ctx.concatenate(matrix)
        }

        // BT — begin text object
        CGPDFOperatorTableSetCallback(table, "BT") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.beginText()
        }

        // ET — end text object
        CGPDFOperatorTableSetCallback(table, "ET") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.endText()
        }

        // Tf — set font and size
        CGPDFOperatorTableSetCallback(table, "Tf") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var size: CGPDFReal = 0
            var namePtr: UnsafePointer<CChar>?
            guard CGPDFScannerPopNumber(scanner, &size),
                  CGPDFScannerPopName(scanner, &namePtr),
                  let name = namePtr else { return }
            ctx.setFont(name: String(cString: name), size: Double(size))
        }

        // Tm — set text matrix
        CGPDFOperatorTableSetCallback(table, "Tm") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var a: CGPDFReal = 0, b: CGPDFReal = 0
            var c: CGPDFReal = 0, d: CGPDFReal = 0
            var e: CGPDFReal = 0, f: CGPDFReal = 0

            guard CGPDFScannerPopNumber(scanner, &f),
                  CGPDFScannerPopNumber(scanner, &e),
                  CGPDFScannerPopNumber(scanner, &d),
                  CGPDFScannerPopNumber(scanner, &c),
                  CGPDFScannerPopNumber(scanner, &b),
                  CGPDFScannerPopNumber(scanner, &a) else { return }

            let matrix = CGAffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f)
            ctx.setTextMatrix(matrix)
        }

        // Td — move text position
        CGPDFOperatorTableSetCallback(table, "Td") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var tx: CGPDFReal = 0, ty: CGPDFReal = 0
            guard CGPDFScannerPopNumber(scanner, &ty),
                  CGPDFScannerPopNumber(scanner, &tx) else { return }
            ctx.translateTextPosition(tx: Double(tx), ty: Double(ty))
        }

        // TD — move text position and set leading
        CGPDFOperatorTableSetCallback(table, "TD") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var tx: CGPDFReal = 0, ty: CGPDFReal = 0
            guard CGPDFScannerPopNumber(scanner, &ty),
                  CGPDFScannerPopNumber(scanner, &tx) else { return }
            ctx.translateTextPosition(tx: Double(tx), ty: Double(ty))
        }

        // T* — move to start of next line
        CGPDFOperatorTableSetCallback(table, "T*") { _, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.nextLine()
        }

        // Tj — show text string
        CGPDFOperatorTableSetCallback(table, "Tj") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var strRef: CGPDFStringRef?
            if CGPDFScannerPopString(scanner, &strRef), let s = strRef {
                let bytes = CGPDFStringGetBytePtr(s)
                let length = CGPDFStringGetLength(s)
                if bytes != nil {
                    ctx.showText(glyphCount: Int(length))
                }
            }
        }

        // TJ — show text with individual glyph positioning
        CGPDFOperatorTableSetCallback(table, "TJ") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var arrayRef: CGPDFArrayRef?
            guard CGPDFScannerPopArray(scanner, &arrayRef), let arr = arrayRef else { return }

            var totalGlyphs = 0
            let count = CGPDFArrayGetCount(arr)
            for i in 0..<count {
                var strRef: CGPDFStringRef?
                if CGPDFArrayGetString(arr, i, &strRef), let s = strRef {
                    totalGlyphs += Int(CGPDFStringGetLength(s))
                }
            }
            if totalGlyphs > 0 {
                ctx.showText(glyphCount: totalGlyphs)
            }
        }

        // ' — move to next line and show text
        CGPDFOperatorTableSetCallback(table, "'") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.nextLine()
            var strRef: CGPDFStringRef?
            if CGPDFScannerPopString(scanner, &strRef), let s = strRef {
                let length = CGPDFStringGetLength(s)
                ctx.showText(glyphCount: Int(length))
            }
        }

        // " — set spacing, move to next line, and show text
        CGPDFOperatorTableSetCallback(table, "\"") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var strRef: CGPDFStringRef?
            var _ac: CGPDFReal = 0, _aw: CGPDFReal = 0
            if CGPDFScannerPopString(scanner, &strRef),
               CGPDFScannerPopNumber(scanner, &_ac),
               CGPDFScannerPopNumber(scanner, &_aw) {
                ctx.nextLine()
                if let s = strRef {
                    let length = CGPDFStringGetLength(s)
                    ctx.showText(glyphCount: Int(length))
                }
            }
        }

        let context = ScanContext()
        let contextPtr = Unmanaged.passUnretained(context).toOpaque()

        let pdfScanner = CGPDFScannerCreate(contentStream, table, contextPtr)
        CGPDFScannerScan(pdfScanner)
        CGPDFScannerRelease(pdfScanner)
        CGPDFOperatorTableRelease(table)

        return context.placements
    }

    // MARK: - Spatial Merge

    /// Merges raw BT/ET placements into logical text frames using spatial
    /// proximity. Two placements are merged when they are close enough to
    /// belong to the same visual text block (e.g. consecutive lines of a
    /// paragraph, or adjacent styled runs on the same line).
    ///
    /// Uses union-find for efficient connected-component grouping.
    static func mergeProximateFrames(_ placements: [TextFramePlacement]) -> [TextFramePlacement] {
        guard placements.count > 1 else { return placements }

        let n = placements.count
        var parent = Array(0..<n)
        var rank = Array(repeating: 0, count: n)

        func find(_ x: Int) -> Int {
            var x = x
            while parent[x] != x {
                parent[x] = parent[parent[x]]
                x = parent[x]
            }
            return x
        }

        func union(_ a: Int, _ b: Int) {
            let ra = find(a), rb = find(b)
            guard ra != rb else { return }
            if rank[ra] < rank[rb] {
                parent[ra] = rb
            } else if rank[ra] > rank[rb] {
                parent[rb] = ra
            } else {
                parent[rb] = ra
                rank[ra] += 1
            }
        }

        // Check every pair for proximity.
        // For typical page counts (~100 raw placements) this is fast enough.
        for i in 0..<n {
            let bi = placements[i].bounds
            let fi = placements[i].fontSize
            for j in (i + 1)..<n {
                let bj = placements[j].bounds
                let fj = placements[j].fontSize
                if areProximate(bi, fi, bj, fj) {
                    union(i, j)
                }
            }
        }

        // Group by root and merge each group
        var groups: [Int: [Int]] = [:]
        for i in 0..<n {
            groups[find(i), default: []].append(i)
        }

        return groups.values.map { indices in
            mergeGroup(indices.map { placements[$0] })
        }
    }

    /// Two placements are proximate if they're close enough to be part of the
    /// same visual text block.
    private static func areProximate(
        _ a: AnnotationBounds, _ aSize: Double,
        _ b: AnnotationBounds, _ bSize: Double
    ) -> Bool {
        // Don't merge frames with very different font sizes (e.g. heading + body).
        // This preserves individual font size data for checks like fonts.size.
        let minSize = max(min(aSize, bSize), 0.01)
        if max(aSize, bSize) / minSize > 2.0 { return false }

        let maxSize = max(aSize, bSize)

        // Vertical gap between the two bounding boxes
        let aTop = a.y + a.height
        let bTop = b.y + b.height
        let vertGap = max(0, max(a.y - bTop, b.y - aTop))

        // Horizontal gap between the two bounding boxes
        let aRight = a.x + a.width
        let bRight = b.x + b.width
        let horizGap = max(0, max(a.x - bRight, b.x - aRight))

        // Same-line merge: small vertical gap, horizontally close
        // (covers adjacent style runs on the same line)
        let sameLineVert = vertGap < maxSize * 0.6
        let sameLineHoriz = horizGap < maxSize * 2.0
        if sameLineVert && sameLineHoriz { return true }

        // Stacked-line merge: within ~2x line height vertically,
        // and horizontally overlapping (not just close)
        let stackedVert = vertGap < maxSize * 2.5
        let horizOverlap = min(aRight, bRight) - max(a.x, b.x)
        let minWidth = min(a.width, b.width)
        let hasHorizOverlap = horizOverlap > minWidth * 0.2
        if stackedVert && hasHorizOverlap { return true }

        return false
    }

    /// Merges a group of placements into a single frame with unioned bounds
    /// and the dominant (most common) font.
    private static func mergeGroup(_ placements: [TextFramePlacement]) -> TextFramePlacement {
        assert(!placements.isEmpty)
        if placements.count == 1 { return placements[0] }

        // Union the bounding boxes
        var minX = Double.infinity, minY = Double.infinity
        var maxX = -Double.infinity, maxY = -Double.infinity

        // Track dominant font by total area covered
        var fontAreas: [String: Double] = [:]
        var fontSizes: [String: Double] = [:]

        for p in placements {
            minX = min(minX, p.bounds.x)
            minY = min(minY, p.bounds.y)
            maxX = max(maxX, p.bounds.x + p.bounds.width)
            maxY = max(maxY, p.bounds.y + p.bounds.height)

            let area = p.bounds.width * p.bounds.height
            fontAreas[p.fontName, default: 0] += area
            // Keep the largest size seen for each font
            fontSizes[p.fontName] = max(fontSizes[p.fontName] ?? 0, p.fontSize)
        }

        let dominantFont = fontAreas.max(by: { $0.value < $1.value })!.key
        let dominantSize = fontSizes[dominantFont] ?? placements[0].fontSize

        return TextFramePlacement(
            fontName: dominantFont,
            fontSize: dominantSize,
            bounds: AnnotationBounds(
                x: minX,
                y: minY,
                width: maxX - minX,
                height: maxY - minY
            )
        )
    }
}

// MARK: - Scan Context

/// Mutable state used during content stream text scanning.
private final class ScanContext: @unchecked Sendable {
    /// The graphics state stack, each entry is the CTM at that level.
    private var ctmStack: [CGAffineTransform] = [.identity]

    /// Current text matrix (set by Tm, modified by Td/TD/T*).
    private var textMatrix: CGAffineTransform = .identity

    /// Current line matrix (set by Tm/Td/TD, used by T*).
    private var lineMatrix: CGAffineTransform = .identity

    /// Current font name and size.
    private var currentFontName: String = ""
    private var currentFontSize: Double = 12.0

    /// Per-frame bounding box accumulator (in page space).
    private var frameMinX: Double = .infinity
    private var frameMinY: Double = .infinity
    private var frameMaxX: Double = -.infinity
    private var frameMaxY: Double = -.infinity

    /// Font name captured at start of frame (first Tf in the BT block).
    private var frameFontName: String = ""
    private var frameFontSize: Double = 12.0
    private var hasFrameContent: Bool = false
    private var inTextObject: Bool = false

    /// Recorded text frame placements.
    var placements: [ContentStreamTextScanner.TextFramePlacement] = []

    /// Current CTM.
    var ctm: CGAffineTransform {
        get { ctmStack.last ?? .identity }
        set { ctmStack[ctmStack.count - 1] = newValue }
    }

    func saveState() {
        ctmStack.append(ctm)
    }

    func restoreState() {
        if ctmStack.count > 1 {
            ctmStack.removeLast()
        }
    }

    func concatenate(_ matrix: CGAffineTransform) {
        ctm = matrix.concatenating(ctm)
    }

    func beginText() {
        inTextObject = true
        textMatrix = .identity
        lineMatrix = .identity
        frameMinX = .infinity
        frameMinY = .infinity
        frameMaxX = -.infinity
        frameMaxY = -.infinity
        hasFrameContent = false
        frameFontName = currentFontName
        frameFontSize = currentFontSize
    }

    func endText() {
        guard inTextObject, hasFrameContent else {
            inTextObject = false
            return
        }
        inTextObject = false

        let width = frameMaxX - frameMinX
        let height = frameMaxY - frameMinY
        guard width > 0, height > 0 else { return }

        let bounds = AnnotationBounds(
            x: frameMinX,
            y: frameMinY,
            width: width,
            height: height
        )

        placements.append(.init(
            fontName: frameFontName,
            fontSize: frameFontSize,
            bounds: bounds
        ))
    }

    func setFont(name: String, size: Double) {
        currentFontName = name
        currentFontSize = abs(size)
        if inTextObject && !hasFrameContent {
            frameFontName = name
            frameFontSize = abs(size)
        }
    }

    func setTextMatrix(_ matrix: CGAffineTransform) {
        textMatrix = matrix
        lineMatrix = matrix
    }

    func translateTextPosition(tx: Double, ty: Double) {
        let translation = CGAffineTransform(translationX: tx, y: ty)
        lineMatrix = translation.concatenating(lineMatrix)
        textMatrix = lineMatrix
    }

    func nextLine() {
        // T* is equivalent to 0 -Tl Td, but we don't track Tl.
        // Use a small downward offset as approximation.
        let leading = currentFontSize * 1.2
        translateTextPosition(tx: 0, ty: -leading)
    }

    func showText(glyphCount: Int) {
        guard inTextObject, glyphCount > 0 else { return }

        // The text rendering position in page space is Tm × CTM.
        // The text origin is at (0,0) in text space.
        let renderMatrix = textMatrix.concatenating(ctm)

        // Text baseline position in page space
        let origin = CGPoint(x: 0, y: 0).applying(renderMatrix)

        // Approximate glyph width: fontSize × 0.5 per glyph (average advance).
        let approxWidth = currentFontSize * 0.5 * Double(glyphCount)

        // The font size in page space accounts for any scaling in the matrices.
        // Use the vertical scale component of the render matrix.
        let effectiveSize = abs(currentFontSize * hypot(Double(renderMatrix.b), Double(renderMatrix.d)))

        // Compute the four corners of the text bounding box in page space.
        // Text sits on the baseline; descenders go below, ascenders above.
        let descent = effectiveSize * 0.2
        let ascent = effectiveSize * 0.8

        // Advance direction in page space
        let advanceEnd = CGPoint(x: approxWidth, y: 0).applying(renderMatrix)

        let x0 = min(Double(origin.x), Double(advanceEnd.x))
        let x1 = max(Double(origin.x), Double(advanceEnd.x))
        let y0 = min(Double(origin.y), Double(advanceEnd.y)) - descent
        let y1 = max(Double(origin.y), Double(advanceEnd.y)) + ascent

        expandFrame(minX: x0, minY: y0, maxX: x1, maxY: y1)

        // Advance the text matrix by the approximate width.
        textMatrix = CGAffineTransform(translationX: approxWidth, y: 0)
            .concatenating(textMatrix)

        hasFrameContent = true
    }

    private func expandFrame(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        frameMinX = min(frameMinX, minX)
        frameMinY = min(frameMinY, minY)
        frameMaxX = max(frameMaxX, maxX)
        frameMaxY = max(frameMaxY, maxY)
    }
}
