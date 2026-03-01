import Foundation

public struct FixRegistry: Sendable {
    private let descriptors: [FixDescriptor]

    public init(descriptors: [FixDescriptor]) {
        self.descriptors = descriptors
    }

    public var allDescriptors: [FixDescriptor] { descriptors }

    public func availableFix(for checkTypeID: String) -> FixDescriptor? {
        descriptors.first { $0.addressesCheckTypeIDs.contains(checkTypeID) }
    }

    public static let `default` = FixRegistry(descriptors: [
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
    ])
}
