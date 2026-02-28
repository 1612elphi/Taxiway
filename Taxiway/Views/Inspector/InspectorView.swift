import SwiftUI
import TaxiwayCore

struct InspectorView: View {
    let document: TaxiwayDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TaxiwayTheme.sectionSpacing) {
                documentInfoSection
                pagesSection
                fontsSection
                imagesSection
                colourSpacesSection
                spotColoursSection
                annotationsSection
            }
            .padding(TaxiwayTheme.panelPadding)
        }
        .frame(minWidth: 300, idealWidth: 300)
    }

    // MARK: - Document Info

    @ViewBuilder
    private var documentInfoSection: some View {
        DisclosureGroup("Document Info") {
            VStack(alignment: .leading, spacing: 4) {
                infoRow("PDF Version", document.documentInfo.pdfVersion)
                if let producer = document.documentInfo.producer {
                    infoRow("Producer", producer)
                }
                if let creator = document.documentInfo.creator {
                    infoRow("Creator", creator)
                }
                infoRow("Linearized", document.documentInfo.isLinearized ? "Yes" : "No")
                infoRow("Tagged", document.documentInfo.isTagged ? "Yes" : "No")
                infoRow("Layers", document.documentInfo.hasLayers ? "Yes" : "No")
                infoRow("File Size", String(format: "%.2f MB", document.fileInfo.fileSizeMB))
                infoRow("Pages", "\(document.fileInfo.pageCount)")
                infoRow("Encrypted", document.fileInfo.isEncrypted ? "Yes" : "No")
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Pages

    @ViewBuilder
    private var pagesSection: some View {
        DisclosureGroup("Pages (\(document.pages.count))") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(document.pages, id: \.index) { page in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Page \(page.index + 1)")
                            .font(TaxiwayTheme.monoSmall)
                            .fontWeight(.semibold)
                        Text("Media: \(boxDescription(page.mediaBox))")
                            .font(TaxiwayTheme.monoSmall)
                        if page.trimBox != nil {
                            Text("Trim: \(boxDescription(page.effectiveTrimBox))")
                                .font(TaxiwayTheme.monoSmall)
                                .foregroundStyle(.secondary)
                        }
                        if page.bleedBox != nil {
                            Text("Bleed: present")
                                .font(TaxiwayTheme.monoSmall)
                                .foregroundStyle(.secondary)
                        }
                        if page.artBox != nil {
                            Text("Art: present")
                                .font(TaxiwayTheme.monoSmall)
                                .foregroundStyle(.secondary)
                        }
                        if page.rotation != 0 {
                            Text("Rotation: \(page.rotation)\u{00B0}")
                                .font(TaxiwayTheme.monoSmall)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Fonts

    @ViewBuilder
    private var fontsSection: some View {
        DisclosureGroup("Fonts (\(document.fonts.count))") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(document.fonts, id: \.name) { font in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(font.name)
                            .font(TaxiwayTheme.monoSmall)
                            .fontWeight(.semibold)
                        HStack(spacing: 8) {
                            Text(font.type.rawValue)
                                .font(TaxiwayTheme.monoSmall)
                                .foregroundStyle(.secondary)
                            if font.isEmbedded {
                                Text("Embedded")
                                    .font(TaxiwayTheme.monoSmall)
                                    .foregroundStyle(.green)
                            } else {
                                Text("Not embedded")
                                    .font(TaxiwayTheme.monoSmall)
                                    .foregroundStyle(.red)
                            }
                            if font.isSubset {
                                Text("Subset")
                                    .font(TaxiwayTheme.monoSmall)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text("Pages: \(font.pagesUsedOn.map { String($0 + 1) }.joined(separator: ", "))")
                            .font(TaxiwayTheme.monoSmall)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Images

    @ViewBuilder
    private var imagesSection: some View {
        DisclosureGroup("Images (\(document.images.count))") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(document.images, id: \.id) { image in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(image.id)
                            .font(TaxiwayTheme.monoSmall)
                            .fontWeight(.semibold)
                        Text("\(image.widthPixels)\u{00D7}\(image.heightPixels) px")
                            .font(TaxiwayTheme.monoSmall)
                        Text(String(format: "PPI: %.0f \u{00D7} %.0f",
                                    image.effectivePPIHorizontal, image.effectivePPIVertical))
                            .font(TaxiwayTheme.monoSmall)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Text(image.colourMode.rawValue)
                                .font(TaxiwayTheme.monoSmall)
                                .foregroundStyle(.secondary)
                            Text(image.compressionType.rawValue)
                                .font(TaxiwayTheme.monoSmall)
                                .foregroundStyle(.secondary)
                        }
                        Text("Page \(image.pageIndex + 1)")
                            .font(TaxiwayTheme.monoSmall)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Colour Spaces

    @ViewBuilder
    private var colourSpacesSection: some View {
        DisclosureGroup("Colour Spaces (\(document.colourSpaces.count))") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(document.colourSpaces.enumerated()), id: \.offset) { _, cs in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cs.name.rawValue)
                            .font(TaxiwayTheme.monoSmall)
                            .fontWeight(.semibold)
                        if let icc = cs.iccProfileName {
                            Text("ICC: \(icc)")
                                .font(TaxiwayTheme.monoSmall)
                                .foregroundStyle(.secondary)
                        }
                        Text("Pages: \(cs.pagesUsedOn.map { String($0 + 1) }.joined(separator: ", "))")
                            .font(TaxiwayTheme.monoSmall)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Spot Colours

    @ViewBuilder
    private var spotColoursSection: some View {
        DisclosureGroup("Spot Colours (\(document.spotColours.count))") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(document.spotColours.enumerated()), id: \.offset) { _, spot in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(spot.name)
                            .font(TaxiwayTheme.monoSmall)
                            .fontWeight(.semibold)
                        Text("Pages: \(spot.pagesUsedOn.map { String($0 + 1) }.joined(separator: ", "))")
                            .font(TaxiwayTheme.monoSmall)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Annotations

    @ViewBuilder
    private var annotationsSection: some View {
        DisclosureGroup("Annotations (\(document.annotations.count))") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(document.annotations.enumerated()), id: \.offset) { _, annotation in
                    HStack(spacing: 8) {
                        Text(annotation.type.rawValue)
                            .font(TaxiwayTheme.monoSmall)
                            .fontWeight(.semibold)
                        if let subtype = annotation.subtype {
                            Text("(\(subtype))")
                                .font(TaxiwayTheme.monoSmall)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Page \(annotation.pageIndex + 1)")
                            .font(TaxiwayTheme.monoSmall)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Helpers

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(TaxiwayTheme.monoSmall)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(TaxiwayTheme.monoSmall)
        }
    }

    private func boxDescription(_ rect: CGRect) -> String {
        String(format: "%.0f \u{00D7} %.0f pt", rect.width, rect.height)
    }
}
