import PDFKit
import SwiftUI
import TaxiwayCore

/// Full-document PDF preview with annotation-based highlighting.
/// Uses native PDFKit zoom/scroll — no SwiftUI overlay hacks.
struct PDFPreviewView: View {
    let pdfURL: URL?
    let affectedItems: [AffectedItem]
    let highlightColor: Color

    var body: some View {
        if pdfURL != nil {
            PDFKitView(pdfURL: pdfURL, affectedItems: affectedItems, highlightColor: highlightColor)
        } else {
            ContentUnavailableView("No PDF available", systemImage: "doc.richtext")
        }
    }
}

// MARK: - PDFKit NSViewRepresentable

private struct PDFKitView: NSViewRepresentable {
    let pdfURL: URL?
    let affectedItems: [AffectedItem]
    let highlightColor: Color

    class Coordinator {
        var highlightAnnotations: [PDFAnnotation] = []
        var loadedURL: URL?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysPageBreaks = true
        pdfView.interpolationQuality = .high
        pdfView.backgroundColor = .windowBackgroundColor

        if let url = pdfURL {
            pdfView.document = PDFDocument(url: url)
            context.coordinator.loadedURL = url
        }

        applyHighlights(to: pdfView, coordinator: context.coordinator)
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // Reload document if URL changed
        if pdfURL != context.coordinator.loadedURL {
            if let url = pdfURL {
                pdfView.document = PDFDocument(url: url)
            } else {
                pdfView.document = nil
            }
            context.coordinator.loadedURL = pdfURL
        }

        applyHighlights(to: pdfView, coordinator: context.coordinator)
    }

    private func applyHighlights(to pdfView: PDFView, coordinator: Coordinator) {
        // Remove old highlights
        for ann in coordinator.highlightAnnotations {
            ann.page?.removeAnnotation(ann)
        }
        coordinator.highlightAnnotations = []

        guard let document = pdfView.document else { return }
        guard !affectedItems.isEmpty else { return }

        let nsColor = NSColor(highlightColor)
        var firstPage: PDFPage?

        for item in affectedItems {
            for (pageIndex, rect) in highlightEntries(for: item) {
                guard pageIndex < document.pageCount,
                      let page = document.page(at: pageIndex) else { continue }

                let bounds = rect ?? page.bounds(for: .mediaBox)
                let annotation = PDFAnnotation(bounds: bounds, forType: .square, withProperties: nil)
                annotation.color = nsColor.withAlphaComponent(0.6)
                annotation.interiorColor = nsColor.withAlphaComponent(0.15)
                let border = PDFBorder()
                border.lineWidth = 2
                annotation.border = border

                page.addAnnotation(annotation)
                coordinator.highlightAnnotations.append(annotation)

                if firstPage == nil { firstPage = page }
            }
        }

        // Navigate to first affected page
        if let page = firstPage {
            pdfView.go(to: page)
        }
    }

    private func highlightEntries(for item: AffectedItem) -> [(pageIndex: Int, rect: CGRect?)] {
        switch item {
        case .document:
            return [(0, nil)]
        case .page(let index):
            return [(index, nil)]
        case .font(_, let pages):
            return pages.map { ($0, nil) }
        case .image(_, let page, let bounds):
            if let b = bounds {
                return [(page, CGRect(x: b.x, y: b.y, width: b.width, height: b.height))]
            } else {
                return [(page, nil)]
            }
        case .colourSpace(_, let pages):
            return pages.map { ($0, nil) }
        case .annotation(_, let page, let bounds):
            if let b = bounds {
                return [(page, CGRect(x: b.x, y: b.y, width: b.width, height: b.height))]
            } else {
                return [(page, nil)]
            }
        case .textFrame(_, let page, let bounds):
            if let b = bounds {
                return [(page, CGRect(x: b.x, y: b.y, width: b.width, height: b.height))]
            } else {
                return [(page, nil)]
            }
        }
    }
}
