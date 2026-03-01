import Foundation
import CoreGraphics

/// Scans PDF page content streams to find image XObject placements and their
/// bounding rectangles derived from the current transformation matrix (CTM).
///
/// The scanner tracks CTM changes via `q` (save), `Q` (restore), `cm` (concatenate),
/// and records image placements via the `Do` operator.
struct ContentStreamImageScanner: Sendable {

    /// An image placement found in a content stream.
    struct ImagePlacement: Sendable {
        let name: String              // XObject resource name (e.g. "Im0")
        let bounds: AnnotationBounds  // Bounding rect in page (default user) space
        let widthPoints: Double       // Effective width in points
        let heightPoints: Double      // Effective height in points
    }

    /// Scan a page's content stream and return all image XObject placements.
    static func scan(page pageRef: CGPDFPage) -> [ImagePlacement] {
        let contentStream = CGPDFContentStreamCreateWithPage(pageRef)
        defer { CGPDFContentStreamRelease(contentStream) }

        guard let table = CGPDFOperatorTableCreate() else { return [] }

        // Graphics state stack operators
        CGPDFOperatorTableSetCallback(table, "q") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            ctx.saveState()
        }

        CGPDFOperatorTableSetCallback(table, "Q") { scanner, info in
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

        // Do (paint XObject)
        CGPDFOperatorTableSetCallback(table, "Do") { scanner, info in
            let ctx = Unmanaged<ScanContext>.fromOpaque(info!).takeUnretainedValue()
            var namePtr: UnsafePointer<CChar>?
            guard CGPDFScannerPopName(scanner, &namePtr),
                  let name = namePtr else { return }
            ctx.recordDo(name: String(cString: name))
        }

        let context = ScanContext()
        let contextPtr = Unmanaged.passUnretained(context).toOpaque()

        let pdfScanner = CGPDFScannerCreate(contentStream, table, contextPtr)
        CGPDFScannerScan(pdfScanner)
        CGPDFScannerRelease(pdfScanner)
        CGPDFOperatorTableRelease(table)

        return context.placements
    }
}

// MARK: - Scan Context

/// Mutable state used during content stream scanning. Not `Sendable` itself;
/// used only within a single synchronous scan call.
private final class ScanContext: @unchecked Sendable {
    /// The graphics state stack, each entry is the CTM at that level.
    private var ctmStack: [CGAffineTransform] = [.identity]

    /// Recorded image placements.
    var placements: [ContentStreamImageScanner.ImagePlacement] = []

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

    func recordDo(name: String) {
        // In PDF, images are drawn into a 1x1 unit square.
        // The CTM transforms that unit square to the actual placement rectangle.
        // The four corners of the unit square [0,0], [1,0], [1,1], [0,1]
        // transformed by the CTM give us the placement quadrilateral.
        // We compute the axis-aligned bounding box.

        let corners = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 1, y: 0),
            CGPoint(x: 1, y: 1),
            CGPoint(x: 0, y: 1),
        ].map { $0.applying(ctm) }

        let xs = corners.map(\.x)
        let ys = corners.map(\.y)

        let minX = xs.min()!
        let maxX = xs.max()!
        let minY = ys.min()!
        let maxY = ys.max()!

        let width = maxX - minX
        let height = maxY - minY

        // Derive effective size from the CTM's scale components.
        // For a simple scale+translate CTM [sx 0 0 sy tx ty],
        // width = abs(sx) and height = abs(sy).
        // For rotated/sheared images, use the bounding box dimensions.
        let widthPoints = Double(width)
        let heightPoints = Double(height)

        let bounds = AnnotationBounds(
            x: Double(minX),
            y: Double(minY),
            width: Double(width),
            height: Double(height)
        )

        placements.append(.init(
            name: name,
            bounds: bounds,
            widthPoints: widthPoints,
            heightPoints: heightPoints
        ))
    }
}
