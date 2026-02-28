import TaxiwayCore

enum CheckMetadata {
    struct Info {
        let displayName: String
        let description: String
        let category: CheckCategory
    }

    private static let entries: [String: Info] = [
        // MARK: - File
        "file.encryption": Info(
            displayName: "Encryption",
            description: "Checks whether the PDF file is encrypted or unencrypted.",
            category: .file
        ),
        "file.size.max": Info(
            displayName: "File Size (Max)",
            description: "Fails if the file exceeds the specified maximum size in megabytes.",
            category: .file
        ),
        "file.size.min": Info(
            displayName: "File Size (Min)",
            description: "Fails if the file is below the specified minimum size in megabytes.",
            category: .file
        ),
        "file.interactive_elements": Info(
            displayName: "Interactive Elements",
            description: "Detects interactive form fields, JavaScript actions, and other interactive content.",
            category: .file
        ),
        "file.metadata.present": Info(
            displayName: "Metadata Field Present",
            description: "Checks that a specific metadata field (title, author, etc.) is present and non-empty.",
            category: .file
        ),
        "file.metadata.matches": Info(
            displayName: "Metadata Field Matches",
            description: "Checks that a specific metadata field matches an expected value.",
            category: .file
        ),

        // MARK: - PDF
        "pdf.version": Info(
            displayName: "PDF Version",
            description: "Checks the PDF version string (e.g. 1.4, 1.7, 2.0) against an expected value.",
            category: .pdf
        ),
        "pdf.conformance": Info(
            displayName: "PDF Conformance",
            description: "Verifies the document conforms to a specific PDF standard (PDF/X, PDF/A).",
            category: .pdf
        ),
        "pdf.annotations": Info(
            displayName: "Annotations",
            description: "Detects annotations such as comments, sticky notes, and markup in the document.",
            category: .pdf
        ),
        "pdf.layers": Info(
            displayName: "Layers Present",
            description: "Detects Optional Content Groups (layers) in the document.",
            category: .pdf
        ),
        "pdf.linearized": Info(
            displayName: "Linearized",
            description: "Checks whether the PDF is linearized (optimized for fast web viewing).",
            category: .pdf
        ),
        "pdf.tagged": Info(
            displayName: "Tagged PDF",
            description: "Checks whether the PDF contains a structure tree for accessibility tagging.",
            category: .pdf
        ),

        // MARK: - Pages
        "pages.count": Info(
            displayName: "Page Count",
            description: "Checks the total number of pages against a numeric condition.",
            category: .pages
        ),
        "pages.size": Info(
            displayName: "Page Size",
            description: "Verifies all pages match a target width and height in points, within a tolerance.",
            category: .pages
        ),
        "pages.mixed_sizes": Info(
            displayName: "Mixed Page Sizes",
            description: "Detects documents where pages have different trim box dimensions.",
            category: .pages
        ),
        "pages.rotation": Info(
            displayName: "Page Rotation",
            description: "Detects pages with a non-zero rotation value.",
            category: .pages
        ),

        // MARK: - Marks
        "marks.bleed_zero": Info(
            displayName: "Bleed Zero",
            description: "Flags pages where the bleed box equals the trim box (no bleed area).",
            category: .marks
        ),
        "marks.bleed_nonzero": Info(
            displayName: "Bleed Non-Zero",
            description: "Flags pages that have any bleed area extending beyond the trim box.",
            category: .marks
        ),
        "marks.bleed_greater_than": Info(
            displayName: "Bleed Greater Than",
            description: "Flags pages where any bleed margin exceeds a threshold in millimetres.",
            category: .marks
        ),
        "marks.bleed_less_than": Info(
            displayName: "Bleed Less Than",
            description: "Flags pages where a non-zero bleed margin is below a minimum in millimetres.",
            category: .marks
        ),
        "marks.bleed_non_uniform": Info(
            displayName: "Bleed Non-Uniform",
            description: "Flags pages where bleed margins differ between sides beyond a tolerance.",
            category: .marks
        ),
        "marks.trim_box_set": Info(
            displayName: "Trim Box Set",
            description: "Checks that every page has a trim box explicitly defined.",
            category: .marks
        ),

        // MARK: - Colour
        "colour.space_used": Info(
            displayName: "Colour Space Used",
            description: "Detects usage of a specific colour space (DeviceRGB, DeviceCMYK, etc.).",
            category: .colour
        ),
        "colour.spot_used": Info(
            displayName: "Spot Colour Used",
            description: "Detects the presence of any spot (separation) colours in the document.",
            category: .colour
        ),
        "colour.spot_count": Info(
            displayName: "Spot Colour Count",
            description: "Fails if the number of spot colours exceeds a maximum count.",
            category: .colour
        ),
        "colour.registration": Info(
            displayName: "Registration Colour",
            description: "Detects usage of registration colour (All separation), which prints on all plates.",
            category: .colour
        ),

        // MARK: - Fonts
        "fonts.not_embedded": Info(
            displayName: "Fonts Not Embedded",
            description: "Flags any fonts in the document that are not embedded or subset.",
            category: .fonts
        ),
        "fonts.type": Info(
            displayName: "Font Type",
            description: "Detects fonts of a specific type (Type1, TrueType, OpenType CFF, etc.).",
            category: .fonts
        ),
        "fonts.size": Info(
            displayName: "Font Size",
            description: "Checks font sizes against a numeric threshold.",
            category: .fonts
        ),

        // MARK: - Images
        "images.alpha": Info(
            displayName: "Alpha Channel",
            description: "Detects images that contain an alpha (transparency) channel.",
            category: .images
        ),
        "images.blend_mode": Info(
            displayName: "Blend Mode",
            description: "Detects images using non-normal blend modes or reduced opacity.",
            category: .images
        ),
        "images.colour_mode": Info(
            displayName: "Image Colour Mode",
            description: "Detects images using a specific colour mode (DeviceRGB, DeviceCMYK, etc.).",
            category: .images
        ),
        "images.type": Info(
            displayName: "Image Compression Type",
            description: "Detects images using a specific compression format (JPEG, Flate, JBIG2, etc.).",
            category: .images
        ),
        "images.icc_missing": Info(
            displayName: "ICC Profile Missing",
            description: "Flags images that lack an embedded ICC colour profile.",
            category: .images
        ),
        "images.scaled": Info(
            displayName: "Image Scaled",
            description: "Detects images scaled beyond a tolerance from their native pixel dimensions.",
            category: .images
        ),
        "images.scaled_non_proportional": Info(
            displayName: "Scaled Non-Proportionally",
            description: "Detects images where horizontal and vertical scale factors differ.",
            category: .images
        ),
        "images.resolution_below": Info(
            displayName: "Resolution Below",
            description: "Flags images with effective resolution below a PPI threshold.",
            category: .images
        ),
        "images.resolution_above": Info(
            displayName: "Resolution Above",
            description: "Flags images with effective resolution above a PPI threshold.",
            category: .images
        ),
        "images.resolution_range": Info(
            displayName: "Resolution Range",
            description: "Flags images with effective resolution outside a min/max PPI range.",
            category: .images
        ),
        "images.c2pa": Info(
            displayName: "C2PA Provenance",
            description: "Detects Content Credentials (C2PA) provenance data in images.",
            category: .images
        ),
        "images.genai": Info(
            displayName: "GenAI Metadata",
            description: "Detects generative AI metadata markers in images.",
            category: .images
        ),

        // MARK: - Lines
        "lines.zero_width": Info(
            displayName: "Zero-Width Strokes",
            description: "Detects strokes with a line width of zero, which render as hairlines.",
            category: .lines
        ),
        "lines.stroke_below": Info(
            displayName: "Stroke Weight Below",
            description: "Flags strokes thinner than a minimum weight in points.",
            category: .lines
        ),
    ]

    static func displayName(for typeID: String) -> String {
        entries[typeID]?.displayName ?? typeID
    }

    static func description(for typeID: String) -> String {
        entries[typeID]?.description ?? "No description available."
    }

    static func category(for typeID: String) -> CheckCategory? {
        entries[typeID]?.category
    }
}
