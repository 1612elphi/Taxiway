import PDFKit
import SwiftUI
import TaxiwayCore

struct PDFPreviewView: View {
    let pdfURL: URL?
    let affectedItems: [AffectedItem]
    let highlightColor: Color

    @State private var currentPageIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            if let pdfURL, let document = PDFDocument(url: pdfURL) {
                if affectedPageIndices.count > 1 {
                    pageNavigationBar
                        .padding(.horizontal, TaxiwayTheme.panelPadding)
                        .padding(.vertical, 6)

                    Divider()
                }

                let pageIndex = effectivePageIndex
                if pageIndex < document.pageCount,
                   let page = document.page(at: pageIndex) {
                    ZStack {
                        PDFPageView(page: page)

                        highlightOverlay(for: page)
                    }
                } else {
                    unavailablePlaceholder("Page not available")
                }
            } else {
                unavailablePlaceholder("No PDF available for preview")
            }
        }
        .onChange(of: affectedItems) {
            jumpToFirstAffectedPage()
        }
        .onAppear {
            jumpToFirstAffectedPage()
        }
    }

    // MARK: - Computed

    private var affectedPageIndices: [Int] {
        var indices = Set<Int>()
        for item in affectedItems {
            switch item {
            case .document:
                indices.insert(0)
            case .page(let index):
                indices.insert(index)
            case .font(_, let pages):
                pages.forEach { indices.insert($0) }
            case .image(_, let page):
                indices.insert(page)
            case .colourSpace(_, let pages):
                pages.forEach { indices.insert($0) }
            case .annotation(_, let page, _):
                indices.insert(page)
            }
        }
        return indices.sorted()
    }

    private var effectivePageIndex: Int {
        let pages = affectedPageIndices
        guard !pages.isEmpty else { return 0 }
        let idx = currentPageIndex.clamped(to: 0...(pages.count - 1))
        return pages[idx]
    }

    // MARK: - Navigation

    private var pageNavigationBar: some View {
        HStack {
            Button {
                if currentPageIndex > 0 { currentPageIndex -= 1 }
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(currentPageIndex <= 0)

            Spacer()

            Text("Page \(effectivePageIndex + 1)")
                .font(TaxiwayTheme.monoSmall)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                if currentPageIndex < affectedPageIndices.count - 1 {
                    currentPageIndex += 1
                }
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(currentPageIndex >= affectedPageIndices.count - 1)
        }
    }

    // MARK: - Highlight overlay

    private func highlightOverlay(for page: PDFPage) -> some View {
        GeometryReader { geo in
            let pageBounds = page.bounds(for: .mediaBox)
            let viewSize = geo.size
            let scale = min(
                viewSize.width / pageBounds.width,
                viewSize.height / pageBounds.height
            )
            let scaledWidth = pageBounds.width * scale
            let scaledHeight = pageBounds.height * scale
            let offsetX = (viewSize.width - scaledWidth) / 2
            let offsetY = (viewSize.height - scaledHeight) / 2

            let rects = highlightRects(
                for: effectivePageIndex,
                pageBounds: pageBounds
            )

            ForEach(Array(rects.enumerated()), id: \.offset) { _, rect in
                // Convert from PDF coords (bottom-left origin) to view coords (top-left origin)
                let viewX = offsetX + rect.origin.x * scale
                let viewY = offsetY + (pageBounds.height - rect.origin.y - rect.size.height) * scale
                let viewW = rect.size.width * scale
                let viewH = rect.size.height * scale

                Rectangle()
                    .fill(highlightColor.opacity(0.25))
                    .border(highlightColor.opacity(0.6), width: 2)
                    .frame(width: viewW, height: viewH)
                    .position(x: viewX + viewW / 2, y: viewY + viewH / 2)
            }
        }
    }

    private func highlightRects(for pageIndex: Int, pageBounds: CGRect) -> [CGRect] {
        var rects: [CGRect] = []
        let fullPage = CGRect(
            x: 0, y: 0,
            width: pageBounds.width,
            height: pageBounds.height
        )

        for item in affectedItems {
            switch item {
            case .document:
                if pageIndex == 0 {
                    rects.append(fullPage)
                }
            case .page(let index):
                if index == pageIndex {
                    rects.append(fullPage)
                }
            case .font(_, let pages):
                if pages.contains(pageIndex) {
                    rects.append(fullPage)
                }
            case .image(_, let page):
                if page == pageIndex {
                    rects.append(fullPage)
                }
            case .colourSpace(_, let pages):
                if pages.contains(pageIndex) {
                    rects.append(fullPage)
                }
            case .annotation(_, let page, let bounds):
                if page == pageIndex {
                    if let b = bounds {
                        rects.append(CGRect(x: b.x, y: b.y, width: b.width, height: b.height))
                    } else {
                        rects.append(fullPage)
                    }
                }
            }
        }
        return rects
    }

    // MARK: - Helpers

    private func jumpToFirstAffectedPage() {
        currentPageIndex = 0
    }

    @ViewBuilder
    private func unavailablePlaceholder(_ message: String) -> some View {
        ContentUnavailableView(
            message,
            systemImage: "doc.richtext"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - PDFPageView (NSViewRepresentable)

struct PDFPageView: NSViewRepresentable {
    let page: PDFPage

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displaysPageBreaks = false
        pdfView.interpolationQuality = .high

        let document = PDFDocument()
        document.insert(page, at: 0)
        pdfView.document = document

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        let document = PDFDocument()
        document.insert(page, at: 0)
        pdfView.document = document
    }
}

// MARK: - Comparable clamped helper

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
