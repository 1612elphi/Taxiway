import Foundation
import CoreGraphics
import PDFKit

/// Helper enum that creates test PDFs programmatically using CoreGraphics.
enum TestPDFGenerator {

    /// Standard A4 page size in points.
    static let a4Size = CGSize(width: 595.276, height: 841.89)

    /// Creates a simple single-page PDF at the given URL.
    @discardableResult
    static func createSimplePDF(at url: URL, pageSize: CGSize = a4Size) -> Bool {
        return createMultiPagePDF(at: url, pageSizes: [pageSize])
    }

    /// Creates a multi-page PDF with different page sizes.
    @discardableResult
    static func createMultiPagePDF(at url: URL, pageSizes: [CGSize]) -> Bool {
        guard !pageSizes.isEmpty else { return false }

        var mediaBox = CGRect(origin: .zero, size: pageSizes[0])
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            return false
        }

        for size in pageSizes {
            var pageBox = CGRect(origin: .zero, size: size)
            context.beginPage(mediaBox: &pageBox)
            // Draw a simple rectangle so the page isn't empty
            context.setFillColor(gray: 0.9, alpha: 1.0)
            context.fill(CGRect(x: 10, y: 10, width: size.width - 20, height: size.height - 20))
            context.endPage()
        }

        context.closePDF()
        return true
    }

    /// Creates a PDF with text drawn on the page (generates font resource entries).
    @discardableResult
    static func createPDFWithText(at url: URL, text: String = "Hello, TaxiwayCore!",
                                   fontName: String = "Helvetica", fontSize: CGFloat = 24) -> Bool {
        let pageSize = a4Size
        var mediaBox = CGRect(origin: .zero, size: pageSize)

        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            return false
        }

        context.beginPage(mediaBox: &mediaBox)

        // Draw text using Core Text to create proper font entries
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: CGColor(gray: 0, alpha: 1)
        ]
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attrString)

        context.textPosition = CGPoint(x: 72, y: pageSize.height - 72)
        CTLineDraw(line, context)

        context.endPage()
        context.closePDF()

        return true
    }

    /// Creates a PDF with an embedded image XObject.
    @discardableResult
    static func createPDFWithImage(at url: URL, imageSize: CGSize = CGSize(width: 200, height: 150)) -> Bool {
        let pageSize = a4Size
        var mediaBox = CGRect(origin: .zero, size: pageSize)

        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            return false
        }

        context.beginPage(mediaBox: &mediaBox)

        // Create a bitmap image
        let imgWidth = Int(imageSize.width)
        let imgHeight = Int(imageSize.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let imgContext = CGContext(
            data: nil,
            width: imgWidth,
            height: imgHeight,
            bitsPerComponent: 8,
            bytesPerRow: imgWidth * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            context.endPage()
            context.closePDF()
            return false
        }

        // Draw something on the image
        imgContext.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        imgContext.fill(CGRect(x: 0, y: 0, width: imgWidth, height: imgHeight))
        imgContext.setFillColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        imgContext.fillEllipse(in: CGRect(x: 20, y: 20, width: imgWidth - 40, height: imgHeight - 40))

        guard let image = imgContext.makeImage() else {
            context.endPage()
            context.closePDF()
            return false
        }

        // Draw the image on the PDF page
        let drawRect = CGRect(x: 72, y: pageSize.height - 72 - imageSize.height,
                              width: imageSize.width, height: imageSize.height)
        context.draw(image, in: drawRect)

        context.endPage()
        context.closePDF()

        return true
    }

    /// Creates a PDF with multiple colour types: gray fill rect, RGB stroke rect, CMYK text.
    @discardableResult
    static func createPDFWithColours(at url: URL) -> Bool {
        let pageSize = a4Size
        var mediaBox = CGRect(origin: .zero, size: pageSize)

        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            return false
        }

        context.beginPage(mediaBox: &mediaBox)

        // 1. Gray fill rectangle
        context.setFillColor(gray: 0.5, alpha: 1.0)
        context.fill(CGRect(x: 50, y: 600, width: 100, height: 80))

        // 2. RGB stroke rectangle
        context.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        context.setLineWidth(2.0)
        context.stroke(CGRect(x: 200, y: 600, width: 100, height: 80))

        // 3. Text using Core Text (will use DeviceGray/DeviceRGB depending on system)
        let font = CTFontCreateWithName("Helvetica" as CFString, 18, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        ]
        let attrString = NSAttributedString(string: "Colour Test", attributes: attributes)
        let line = CTLineCreateWithAttributedString(attrString)

        context.textPosition = CGPoint(x: 72, y: pageSize.height - 72)
        CTLineDraw(line, context)

        context.endPage()
        context.closePDF()

        return true
    }

    /// Creates a temporary directory for test PDFs and returns its URL.
    static func createTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TaxiwayCoreTests_\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    /// Cleans up a temporary directory.
    static func cleanupTempDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
