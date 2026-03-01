import Foundation
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
        "pdf.transparency": Info(
            displayName: "Transparency",
            description: "Detects transparency features (blend modes, soft masks, reduced opacity) in the document.",
            category: .pdf
        ),
        "pdf.all_text_outlined": Info(
            displayName: "All Text Outlined",
            description: "Checks whether all text in the document has been converted to outlines.",
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
        "marks.art_slug_box": Info(
            displayName: "Art/Slug Box",
            description: "Detects pages with an art box set (slug box is not exposed by PDFKit).",
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
        "colour.unnamed_spot": Info(
            displayName: "Unnamed Spot Colour",
            description: "Flags spot colours with empty or whitespace-only names.",
            category: .colour
        ),
        "colour.rich_black": Info(
            displayName: "Rich Black",
            description: "Detects CMYK colours where K is 100% and any of C/M/Y is non-zero.",
            category: .colour
        ),
        "colour.ink_coverage": Info(
            displayName: "Ink Coverage",
            description: "Checks total ink coverage (sum of CMYK components) against a percentage threshold.",
            category: .colour
        ),
        "colour.overprint": Info(
            displayName: "Overprint",
            description: "Detects overprint usage in fill, stroke, text, or white overprint contexts.",
            category: .colour
        ),
        "colour.named_gradient": Info(
            displayName: "Named Colour in Gradient",
            description: "Detects spot (named) colours used in shading/gradient definitions.",
            category: .colour
        ),
        "colour.text_mode": Info(
            displayName: "Text Colour Mode",
            description: "Detects text set in a specific colour mode (RGB, CMYK, Gray).",
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

    /// All known typeIDs for a given category, sorted by display name.
    static func typeIDs(for category: CheckCategory) -> [String] {
        entries
            .filter { $0.value.category == category }
            .sorted { displayName(for: $0.key) < displayName(for: $1.key) }
            .map(\.key)
    }

    /// Creates a default IGNORE entry for a typeID with proper default parameters.
    static func defaultEntry(for typeID: String) -> CheckEntry {
        CheckEntry(
            typeID: typeID,
            enabled: false,
            parametersJSON: defaultParametersJSON(for: typeID),
            severityOverride: .warning
        )
    }

    // MARK: - Assertion Text

    /// Generates a plain-English assertion sentence for the current check state.
    /// Example: "If interactive elements are present, throw a FAULT."
    static func assertionText(for typeID: String, entry: CheckEntry) -> String {
        let severity: String
        if !entry.enabled {
            severity = "IGNORE"
        } else {
            switch entry.severityOverride {
            case .error: severity = "FAULT"
            case .warning, .info, nil: severity = "WARN"
            }
        }

        func decode<P: Decodable>(_ type: P.Type) -> P? {
            try? JSONDecoder().decode(type, from: entry.parametersJSON)
        }

        let condition: String
        switch typeID {

        // MARK: File
        case "file.encryption":
            let p = decode(EncryptionCheck.Parameters.self)
            condition = p?.expected == true
                ? "the file is not encrypted"
                : "the file is encrypted"
        case "file.size.max":
            let p = decode(FileSizeMaxCheck.Parameters.self)
            condition = "the file exceeds \(fmt(p?.maxSizeMB ?? 100)) MB"
        case "file.size.min":
            let p = decode(FileSizeMinCheck.Parameters.self)
            condition = "the file is smaller than \(fmt(p?.minSizeMB ?? 0.01)) MB"
        case "file.interactive_elements":
            condition = "interactive elements are present"
        case "file.metadata.present":
            let p = decode(MetadataFieldPresentCheck.Parameters.self)
            let field = (p?.fieldName).flatMap { $0.isEmpty ? nil : $0 } ?? "..."
            condition = "the \(field) metadata field is missing or empty"
        case "file.metadata.matches":
            let p = decode(MetadataFieldMatchesCheck.Parameters.self)
            let field = (p?.fieldName).flatMap { $0.isEmpty ? nil : $0 } ?? "..."
            let val = (p?.expectedValue).flatMap { $0.isEmpty ? nil : $0 } ?? "..."
            condition = "the \(field) metadata field does not match \"\(val)\""

        // MARK: PDF
        case "pdf.version":
            let p = decode(PDFVersionCheck.Parameters.self)
            let ver = (p?.version).flatMap { $0.isEmpty ? nil : $0 } ?? "..."
            condition = p?.operator == .isNot
                ? "the PDF version is not \(ver)"
                : "the PDF version is \(ver)"
        case "pdf.conformance":
            let p = decode(PDFConformanceCheck.Parameters.self)
            condition = "the document does not conform to \(standardLabel(p?.standard ?? .x1a))"
        case "pdf.annotations":
            condition = "annotations are present"
        case "pdf.layers":
            condition = "layers are present"
        case "pdf.linearized":
            let p = decode(LinearizedCheck.Parameters.self)
            condition = p?.expected == true
                ? "the PDF is not linearized"
                : "the PDF is linearized"
        case "pdf.tagged":
            let p = decode(TaggedCheck.Parameters.self)
            condition = p?.expected == true
                ? "the PDF is not tagged"
                : "the PDF is tagged"
        case "pdf.transparency":
            let p = decode(TransparencyCheck.Parameters.self)
            condition = p?.operator == .isNot
                ? "no transparency is used"
                : "transparency is used"
        case "pdf.all_text_outlined":
            let p = decode(AllTextOutlinedCheck.Parameters.self)
            condition = p?.operator == .isNot
                ? "all text is outlined (no live text)"
                : "any live text is found (not outlined)"

        // MARK: Pages
        case "pages.count":
            let p = decode(PageCountCheck.Parameters.self)
            condition = "the page count is \(numericLabel(p?.operator ?? .equals)) \(p?.value ?? 1)"
        case "pages.size":
            let p = decode(PageSizeCheck.Parameters.self)
            let w = fmt(p?.targetWidthPt ?? 595)
            let h = fmt(p?.targetHeightPt ?? 842)
            let t = fmt(p?.tolerancePt ?? 1)
            condition = "any page is not \(w) \u{00D7} \(h) pt (\u{00B1}\(t) pt)"
        case "pages.mixed_sizes":
            condition = "pages have different sizes"
        case "pages.rotation":
            condition = "any page is rotated"

        // MARK: Marks
        case "marks.trim_box_set":
            condition = "any page is missing a trim box"
        case "marks.bleed_zero":
            condition = "any page has zero bleed"
        case "marks.bleed_nonzero":
            condition = "any page has bleed"
        case "marks.bleed_greater_than":
            let p = decode(BleedGreaterThanCheck.Parameters.self)
            condition = "any bleed margin exceeds \(fmt(p?.thresholdMM ?? 5)) mm"
        case "marks.bleed_less_than":
            let p = decode(BleedLessThanCheck.Parameters.self)
            condition = "any bleed margin is less than \(fmt(p?.thresholdMM ?? 3)) mm"
        case "marks.bleed_non_uniform":
            let p = decode(BleedNonUniformCheck.Parameters.self)
            condition = "bleed margins differ by more than \(fmt(p?.toleranceMM ?? 0.5)) mm"
        case "marks.art_slug_box":
            let p = decode(ArtSlugBoxCheck.Parameters.self)
            condition = p?.operator == .isNot
                ? "any page is missing an art box"
                : "any page has an art box set"

        // MARK: Colour
        case "colour.space_used":
            let p = decode(ColourSpaceUsedCheck.Parameters.self)
            let cs = colourSpaceLabel(p?.colourSpace ?? .deviceRGB)
            condition = p?.operator == .isNot
                ? "\(cs) is not used"
                : "\(cs) is used"
        case "colour.spot_used":
            condition = "spot colours are used"
        case "colour.spot_count":
            let p = decode(SpotColourCountCheck.Parameters.self)
            condition = "there are more than \(p?.maxCount ?? 4) spot colours"
        case "colour.registration":
            condition = "registration colour is used"
        case "colour.unnamed_spot":
            condition = "any spot colour has no name"
        case "colour.rich_black":
            condition = "rich black (CMY + K100%) is used"
        case "colour.ink_coverage":
            let p = decode(InkCoverageCheck.Parameters.self)
            condition = "total ink coverage is \(numericLabel(p?.operator ?? .moreThan)) \(fmt(p?.thresholdPercent ?? 300))%"
        case "colour.overprint":
            let p = decode(OverprintCheck.Parameters.self)
            switch p?.context ?? .fill {
            case .fill: condition = "fill overprint is used"
            case .stroke: condition = "stroke overprint is used"
            case .text: condition = "text overprint is used"
            case .white: condition = "white overprint is used"
            }
        case "colour.text_mode":
            let p = decode(TextColourModeCheck.Parameters.self)
            let cm = colourModeLabel(p?.colourMode ?? .rgb)
            condition = p?.operator == .isNot
                ? "no text uses \(cm)"
                : "any text uses \(cm)"
        case "colour.named_gradient":
            condition = "spot colours are used in gradients"

        // MARK: Fonts
        case "fonts.not_embedded":
            condition = "any font is not embedded"
        case "fonts.type":
            let p = decode(FontTypeCheck.Parameters.self)
            let ft = fontTypeLabel(p?.fontType ?? .type1)
            condition = p?.operator == .isNot
                ? "no \(ft) font is found"
                : "any \(ft) font is found"
        case "fonts.size":
            let p = decode(FontSizeCheck.Parameters.self)
            condition = "any font size is \(numericLabel(p?.operator ?? .lessThan)) \(fmt(p?.threshold ?? 6)) pt"

        // MARK: Images
        case "images.alpha":
            condition = "any image has an alpha channel"
        case "images.blend_mode":
            condition = "any image uses a non-normal blend mode or reduced opacity"
        case "images.colour_mode":
            let p = decode(ImageColourModeCheck.Parameters.self)
            let cm = imageColourModeLabel(p?.colourMode ?? .deviceRGB)
            condition = p?.operator == .isNot
                ? "no image uses \(cm)"
                : "any image uses \(cm)"
        case "images.type":
            let p = decode(ImageTypeCheck.Parameters.self)
            let ct = compressionLabel(p?.compressionType ?? .jpeg)
            condition = p?.operator == .isNot
                ? "no image uses \(ct) compression"
                : "any image uses \(ct) compression"
        case "images.icc_missing":
            condition = "any image lacks an ICC profile"
        case "images.scaled":
            let p = decode(ImageScaledCheck.Parameters.self)
            condition = "any image is scaled beyond \(fmt(p?.tolerancePercent ?? 5))% of native size"
        case "images.scaled_non_proportional":
            let p = decode(ImageScaledNonProportionallyCheck.Parameters.self)
            condition = "any image is scaled non-proportionally beyond \(fmt(p?.tolerancePercent ?? 2))%"
        case "images.resolution_below":
            let p = decode(ResolutionBelowCheck.Parameters.self)
            condition = "any image resolution is below \(fmt(p?.thresholdPPI ?? 150)) PPI"
        case "images.resolution_above":
            let p = decode(ResolutionAboveCheck.Parameters.self)
            condition = "any image resolution exceeds \(fmt(p?.thresholdPPI ?? 1200)) PPI"
        case "images.resolution_range":
            let p = decode(ResolutionRangeCheck.Parameters.self)
            condition = "any image resolution is outside \(fmt(p?.minPPI ?? 150))\u{2013}\(fmt(p?.maxPPI ?? 600)) PPI"
        case "images.c2pa":
            condition = "C2PA content credentials are present"
        case "images.genai":
            condition = "generative AI metadata is present"

        // MARK: Lines
        case "lines.zero_width":
            condition = "any stroke has zero width"
        case "lines.stroke_below":
            let p = decode(StrokeWeightBelowCheck.Parameters.self)
            condition = "any stroke is thinner than \(fmt(p?.thresholdPt ?? 0.25)) pt"

        default:
            condition = "this condition is met"
        }

        if !entry.enabled {
            return "IGNORE whether \(condition)."
        } else {
            return "If \(condition), throw a \(severity)."
        }
    }

    // MARK: - Display Helpers

    private static func fmt(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.2g", value)
    }

    private static func numericLabel(_ op: NumericOperator) -> String {
        switch op {
        case .lessThan: "less than"
        case .moreThan: "more than"
        case .equals: "equal to"
        }
    }

    private static func standardLabel(_ std: PDFStandard) -> String {
        switch std {
        case .x1a: "PDF/X-1a"
        case .x3: "PDF/X-3"
        case .x4: "PDF/X-4"
        case .a1b: "PDF/A-1b"
        case .a2b: "PDF/A-2b"
        case .a3b: "PDF/A-3b"
        }
    }

    private static func colourSpaceLabel(_ cs: ColourSpaceName) -> String {
        switch cs {
        case .deviceGray: "DeviceGray"
        case .deviceRGB: "DeviceRGB"
        case .deviceCMYK: "DeviceCMYK"
        case .iccBased: "ICCBased"
        case .calGray: "CalGray"
        case .calRGB: "CalRGB"
        case .lab: "Lab"
        case .indexed: "Indexed"
        case .separation: "Separation"
        case .deviceN: "DeviceN"
        case .pattern: "Pattern"
        case .unknown: "Unknown"
        }
    }

    private static func fontTypeLabel(_ ft: FontType) -> String {
        switch ft {
        case .type1: "Type1"
        case .trueType: "TrueType"
        case .openTypeCFF: "OpenType CFF"
        case .cidFontType0: "CIDFontType0"
        case .cidFontType2: "CIDFontType2"
        case .type3: "Type3"
        case .mmType1: "MMType1"
        case .unknown: "Unknown"
        }
    }

    private static func imageColourModeLabel(_ cm: ImageColourMode) -> String {
        switch cm {
        case .deviceGray: "DeviceGray"
        case .deviceRGB: "DeviceRGB"
        case .deviceCMYK: "DeviceCMYK"
        case .iccBased: "ICCBased"
        case .indexed: "Indexed"
        case .separation: "Separation"
        case .deviceN: "DeviceN"
        case .unknown: "Unknown"
        }
    }

    private static func colourModeLabel(_ cm: ColourMode) -> String {
        switch cm {
        case .gray: "Gray"
        case .rgb: "RGB"
        case .cmyk: "CMYK"
        }
    }

    private static func compressionLabel(_ ct: ImageCompressionType) -> String {
        switch ct {
        case .jpeg: "JPEG"
        case .jpeg2000: "JPEG 2000"
        case .jbig2: "JBIG2"
        case .ccitt: "CCITT"
        case .flate: "Flate"
        case .lzw: "LZW"
        case .runLength: "RunLength"
        case .none: "None"
        case .unknown: "Unknown"
        }
    }

    // MARK: - Default Parameters

    private static func defaultParametersJSON(for typeID: String) -> Data {
        let empty = Data("{}".utf8)
        func encode<P: Encodable>(_ p: P) -> Data {
            (try? JSONEncoder().encode(p)) ?? empty
        }
        switch typeID {
        // File
        case "file.encryption":
            return encode(EncryptionCheck.Parameters(expected: false))
        case "file.size.max":
            return encode(FileSizeMaxCheck.Parameters(maxSizeMB: 100))
        case "file.size.min":
            return encode(FileSizeMinCheck.Parameters(minSizeMB: 0.01))
        case "file.metadata.present":
            return encode(MetadataFieldPresentCheck.Parameters(fieldName: ""))
        case "file.metadata.matches":
            return encode(MetadataFieldMatchesCheck.Parameters(fieldName: "", expectedValue: ""))
        // PDF
        case "pdf.version":
            return encode(PDFVersionCheck.Parameters(operator: .is, version: "1.4"))
        case "pdf.conformance":
            return encode(PDFConformanceCheck.Parameters(standard: .x1a))
        case "pdf.transparency":
            return encode(TransparencyCheck.Parameters(operator: .is))
        case "pdf.all_text_outlined":
            return encode(AllTextOutlinedCheck.Parameters(operator: .is))
        case "pdf.linearized":
            return encode(LinearizedCheck.Parameters(expected: true))
        case "pdf.tagged":
            return encode(TaggedCheck.Parameters(expected: true))
        // Pages
        case "pages.count":
            return encode(PageCountCheck.Parameters(operator: .moreThan, value: 0))
        case "pages.size":
            return encode(PageSizeCheck.Parameters(targetWidthPt: 595.276, targetHeightPt: 841.89, tolerancePt: 1.0))
        // Marks
        case "marks.bleed_greater_than":
            return encode(BleedGreaterThanCheck.Parameters(thresholdMM: 5.0))
        case "marks.bleed_less_than":
            return encode(BleedLessThanCheck.Parameters(thresholdMM: 3.0))
        case "marks.bleed_non_uniform":
            return encode(BleedNonUniformCheck.Parameters(toleranceMM: 0.5))
        case "marks.art_slug_box":
            return encode(ArtSlugBoxCheck.Parameters(operator: .is))
        // Colour
        case "colour.space_used":
            return encode(ColourSpaceUsedCheck.Parameters(colourSpace: .deviceRGB, operator: .is))
        case "colour.spot_count":
            return encode(SpotColourCountCheck.Parameters(maxCount: 4))
        case "colour.ink_coverage":
            return encode(InkCoverageCheck.Parameters(thresholdPercent: 300, operator: .moreThan))
        case "colour.text_mode":
            return encode(TextColourModeCheck.Parameters(colourMode: .rgb, operator: .is))
        case "colour.overprint":
            return encode(OverprintCheck.Parameters(context: .fill))
        // Fonts
        case "fonts.type":
            return encode(FontTypeCheck.Parameters(fontType: .type1, operator: .is))
        case "fonts.size":
            return encode(FontSizeCheck.Parameters(threshold: 6.0, operator: .lessThan))
        // Images
        case "images.colour_mode":
            return encode(ImageColourModeCheck.Parameters(colourMode: .deviceRGB, operator: .is))
        case "images.type":
            return encode(ImageTypeCheck.Parameters(compressionType: .jpeg, operator: .is))
        case "images.scaled":
            return encode(ImageScaledCheck.Parameters(tolerancePercent: 5.0))
        case "images.scaled_non_proportional":
            return encode(ImageScaledNonProportionallyCheck.Parameters(tolerancePercent: 2.0))
        case "images.resolution_below":
            return encode(ResolutionBelowCheck.Parameters(thresholdPPI: 150))
        case "images.resolution_above":
            return encode(ResolutionAboveCheck.Parameters(thresholdPPI: 1200))
        case "images.resolution_range":
            return encode(ResolutionRangeCheck.Parameters(minPPI: 150, maxPPI: 600))
        // Lines
        case "lines.stroke_below":
            return encode(StrokeWeightBelowCheck.Parameters(thresholdPt: 0.25))
        // EmptyParameters checks
        default:
            return empty
        }
    }
}
