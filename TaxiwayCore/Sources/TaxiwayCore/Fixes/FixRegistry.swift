import Foundation

public struct FixRegistry: Sendable {
    private let descriptors: [FixDescriptor]

    public init(descriptors: [FixDescriptor]) {
        self.descriptors = descriptors
    }

    public var allDescriptors: [FixDescriptor] { descriptors }

    public var proactiveDescriptors: [FixDescriptor] {
        descriptors.filter(\.isProactive)
    }

    public func availableFix(for checkTypeID: String) -> FixDescriptor? {
        descriptors.first { $0.addressesCheckTypeIDs.contains(checkTypeID) }
    }

    public static let `default` = FixRegistry(descriptors: [
        // Reactive fixes (triggered by failed checks)
        FixDescriptor(
            id: "fix.convert_cmyk",
            name: "Convert to CMYK",
            description: "Converts all colours to CMYK using Ghostscript colour conversion.",
            addressesCheckTypeIDs: ["colour.space_used", "colour.text_mode"],
            category: .ghostscript
        ),
        FixDescriptor(
            id: "fix.embed_fonts",
            name: "Embed Fonts",
            description: "Embeds and subsets all fonts in the document using Ghostscript.",
            addressesCheckTypeIDs: ["fonts.not_embedded"],
            category: .ghostscript
        ),
        FixDescriptor(
            id: "fix.downsample_images",
            name: "Downsample Images",
            description: "Downsamples colour, gray, and mono images to 300 PPI using Ghostscript.",
            addressesCheckTypeIDs: ["images.resolution_above"],
            category: .ghostscript
        ),
        FixDescriptor(
            id: "fix.flatten_transparency",
            name: "Flatten Transparency",
            description: "Flattens all transparency and outputs a PDF 1.4 compatible file.",
            addressesCheckTypeIDs: ["pdf.transparency"],
            category: .ghostscript
        ),
        FixDescriptor(
            id: "fix.remove_annotations",
            name: "Remove Annotations",
            description: "Removes all annotations (comments, sticky notes, markup) using PDFKit.",
            addressesCheckTypeIDs: ["pdf.annotations"],
            category: .pdfkit
        ),

        // Proactive fixes (available as tools regardless of check results)
        FixDescriptor(
            id: "fix.add_bleed",
            name: "Add/Change Bleed",
            description: "Enlarges the page and offsets content to add bleed area around the trim edge.",
            addressesCheckTypeIDs: [],
            category: .ghostscript,
            isProactive: true,
            defaultParametersJSON: #"{"bleedMM":3.0,"pageWidthPt":595.0,"pageHeightPt":842.0}"#
        ),
        FixDescriptor(
            id: "fix.change_page_size",
            name: "Change Page Size",
            description: "Rescales the document to a fixed output page size.",
            addressesCheckTypeIDs: [],
            category: .ghostscript,
            isProactive: true,
            defaultParametersJSON: #"{"widthMM":210.0,"heightMM":297.0}"#
        ),
        FixDescriptor(
            id: "fix.set_pdf_version",
            name: "Set PDF Version",
            description: "Re-distills the PDF at a specific PDF version compatibility level.",
            addressesCheckTypeIDs: [],
            category: .ghostscript,
            isProactive: true,
            defaultParametersJSON: #"{"version":"1.4"}"#
        ),
        FixDescriptor(
            id: "fix.add_trim_marks",
            name: "Add Trim Marks",
            description: "Draws crop marks at the four corners of each page to indicate the trim edge.",
            addressesCheckTypeIDs: [],
            category: .ghostscript,
            isProactive: true,
            defaultParametersJSON: #"{"offsetMM":3.0,"lengthMM":6.0}"#
        ),
    ])
}
