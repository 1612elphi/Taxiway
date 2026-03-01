import Foundation
import CoreGraphics

/// Scans PDF page content streams to extract stroke (line width) information.
///
/// Tracks the `w` operator (set line width) within the graphics state stack
/// (`q`/`Q`) and records the active line width whenever a stroke-painting
/// operator is encountered (`S`, `s`, `B`, `B*`, `b`, `b*`).
struct ContentStreamStrokeScanner: Sendable {

    struct StrokeRecord: Sendable {
        let lineWidth: Double
        let pageIndex: Int
    }

    /// Scan a page's content stream for stroke operations and return records.
    static func scan(page pageRef: CGPDFPage, pageIndex: Int) -> [StrokeRecord] {
        let contentStream = CGPDFContentStreamCreateWithPage(pageRef)
        defer { CGPDFContentStreamRelease(contentStream) }

        guard let table = CGPDFOperatorTableCreate() else { return [] }

        // Graphics state stack
        CGPDFOperatorTableSetCallback(table, "q") { _, info in
            let ctx = Unmanaged<StrokeScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.saveState()
        }

        CGPDFOperatorTableSetCallback(table, "Q") { _, info in
            let ctx = Unmanaged<StrokeScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.restoreState()
        }

        // w — set line width
        CGPDFOperatorTableSetCallback(table, "w") { scanner, info in
            let ctx = Unmanaged<StrokeScanContext>.fromOpaque(info!).takeUnretainedValue()
            var width: CGPDFReal = 0
            guard CGPDFScannerPopNumber(scanner, &width) else { return }
            ctx.setLineWidth(Double(width))
        }

        // Stroke operators
        CGPDFOperatorTableSetCallback(table, "S") { _, info in
            let ctx = Unmanaged<StrokeScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordStroke()
        }

        CGPDFOperatorTableSetCallback(table, "s") { _, info in
            let ctx = Unmanaged<StrokeScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordStroke()
        }

        // Combined fill+stroke operators
        CGPDFOperatorTableSetCallback(table, "B") { _, info in
            let ctx = Unmanaged<StrokeScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordStroke()
        }

        CGPDFOperatorTableSetCallback(table, "B*") { _, info in
            let ctx = Unmanaged<StrokeScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordStroke()
        }

        CGPDFOperatorTableSetCallback(table, "b") { _, info in
            let ctx = Unmanaged<StrokeScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordStroke()
        }

        CGPDFOperatorTableSetCallback(table, "b*") { _, info in
            let ctx = Unmanaged<StrokeScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.recordStroke()
        }

        let context = StrokeScanContext(pageIndex: pageIndex)
        let contextPtr = Unmanaged.passUnretained(context).toOpaque()

        let pdfScanner = CGPDFScannerCreate(contentStream, table, contextPtr)
        CGPDFScannerScan(pdfScanner)
        CGPDFScannerRelease(pdfScanner)
        CGPDFOperatorTableRelease(table)

        return context.records
    }

    /// Deduplicates stroke records by (pageIndex, quantized lineWidth).
    static func deduplicate(_ records: [StrokeRecord]) -> [StrokeInfo] {
        var seen: Set<String> = []
        var results: [StrokeInfo] = []

        for record in records {
            // Quantize to 3 decimal places (0.001pt precision)
            let quantized = Int(round(record.lineWidth * 1000))
            let key = "\(record.pageIndex):\(quantized)"
            guard seen.insert(key).inserted else { continue }

            results.append(StrokeInfo(
                pageIndex: record.pageIndex,
                lineWidth: record.lineWidth
            ))
        }

        return results
    }
}

// MARK: - Scan Context

private final class StrokeScanContext: @unchecked Sendable {
    let pageIndex: Int

    // PDF default line width is 1.0 pt
    private var lineWidthStack: [Double] = []
    private var currentLineWidth: Double = 1.0

    var records: [ContentStreamStrokeScanner.StrokeRecord] = []

    init(pageIndex: Int) {
        self.pageIndex = pageIndex
    }

    func saveState() {
        lineWidthStack.append(currentLineWidth)
    }

    func restoreState() {
        if let restored = lineWidthStack.popLast() {
            currentLineWidth = restored
        }
    }

    func setLineWidth(_ width: Double) {
        currentLineWidth = width
    }

    func recordStroke() {
        records.append(ContentStreamStrokeScanner.StrokeRecord(
            lineWidth: currentLineWidth,
            pageIndex: pageIndex
        ))
    }
}
