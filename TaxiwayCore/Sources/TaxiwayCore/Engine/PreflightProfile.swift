import Foundation

/// Describes the origin of a preflight profile.
public enum ProfileOrigin: String, Codable, Sendable, Equatable {
    /// A built-in profile shipped with the app.
    case builtIn
    /// A user-created or imported profile.
    case user
}

/// A named collection of check entries that defines what a preflight run should verify.
public struct PreflightProfile: Codable, Sendable, Equatable, Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var description: String
    public var origin: ProfileOrigin
    public var checks: [CheckEntry]

    public init(id: UUID = UUID(), name: String, description: String, origin: ProfileOrigin = .user, checks: [CheckEntry]) {
        self.id = id
        self.name = name
        self.description = description
        self.origin = origin
        self.checks = checks
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Creates a user-owned copy of this profile with a new name and ID.
    public func duplicate(name: String) -> PreflightProfile {
        PreflightProfile(name: name, description: description, origin: .user, checks: checks)
    }
}

// MARK: - Built-in Profiles

extension PreflightProfile {
    /// PDF/X-1a compliance profile — strict press-ready checks.
    public static let pdfX1a = PreflightProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "PDF/X-1a",
        description: "Strict print-production profile for PDF/X-1a compliance.",
        origin: .builtIn,
        checks: [
            // Fonts must be embedded (error)
            try! CheckEntry(typeID: "fonts.not_embedded", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            // RGB colour space not allowed (error) — using .is operator flags presence as failure
            try! CheckEntry(typeID: "colour.space_used", enabled: true,
                            parameters: ColourSpaceUsedCheck.Parameters(colourSpace: .deviceRGB, operator: .is),
                            severityOverride: .error),
            // Trim box must be set (error)
            try! CheckEntry(typeID: "marks.trim_box_set", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            // Zero bleed is an error (error)
            try! CheckEntry(typeID: "marks.bleed_zero", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            // Encryption must be off (error)
            try! CheckEntry(typeID: "file.encryption", enabled: true,
                            parameters: EncryptionCheck.Parameters(expected: false),
                            severityOverride: .error),
            // Page size mismatch (warning) — A4 as default target
            try! CheckEntry(typeID: "pages.size", enabled: true,
                            parameters: PageSizeCheck.Parameters(targetWidthPt: 595.276, targetHeightPt: 841.89, tolerancePt: 1.0),
                            severityOverride: .warning),
            // Image resolution below 200 PPI (warning)
            try! CheckEntry(typeID: "images.resolution_below", enabled: true,
                            parameters: ResolutionBelowCheck.Parameters(thresholdPPI: 200),
                            severityOverride: .warning),
        ]
    )

    /// PDF/X-4 compliance profile — modern press with transparency support.
    public static let pdfX4 = PreflightProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "PDF/X-4",
        description: "Modern print-production profile for PDF/X-4 compliance with transparency support.",
        origin: .builtIn,
        checks: [
            // Fonts must be embedded (error)
            try! CheckEntry(typeID: "fonts.not_embedded", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            // Trim box must be set (error)
            try! CheckEntry(typeID: "marks.trim_box_set", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            // Zero bleed is an error (error)
            try! CheckEntry(typeID: "marks.bleed_zero", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            // Encryption must be off (error)
            try! CheckEntry(typeID: "file.encryption", enabled: true,
                            parameters: EncryptionCheck.Parameters(expected: false),
                            severityOverride: .error),
            // Image resolution below 150 PPI (warning)
            try! CheckEntry(typeID: "images.resolution_below", enabled: true,
                            parameters: ResolutionBelowCheck.Parameters(thresholdPPI: 150),
                            severityOverride: .warning),
        ]
    )

    /// Screen / digital distribution profile.
    public static let screenDigital = PreflightProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Screen / Digital",
        description: "Profile for screen-optimised PDFs and digital distribution.",
        origin: .builtIn,
        checks: [
            // File size max 100 MB (warning)
            try! CheckEntry(typeID: "file.size.max", enabled: true,
                            parameters: FileSizeMaxCheck.Parameters(maxSizeMB: 100),
                            severityOverride: .warning),
            // Encryption must be off (error)
            try! CheckEntry(typeID: "file.encryption", enabled: true,
                            parameters: EncryptionCheck.Parameters(expected: false),
                            severityOverride: .error),
            // Resolution below 72 PPI (warning)
            try! CheckEntry(typeID: "images.resolution_below", enabled: true,
                            parameters: ResolutionBelowCheck.Parameters(thresholdPPI: 72),
                            severityOverride: .warning),
            // Fonts not embedded (warning)
            try! CheckEntry(typeID: "fonts.not_embedded", enabled: true, parameters: EmptyParameters(), severityOverride: .warning),
        ]
    )

    /// Loose / minimal checks profile.
    public static let loose = PreflightProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "Loose",
        description: "Minimal checks — warnings only for the most critical issues.",
        origin: .builtIn,
        checks: [
            // File size max 500 MB (warning)
            try! CheckEntry(typeID: "file.size.max", enabled: true,
                            parameters: FileSizeMaxCheck.Parameters(maxSizeMB: 500),
                            severityOverride: .warning),
            // Encryption (warning)
            try! CheckEntry(typeID: "file.encryption", enabled: true,
                            parameters: EncryptionCheck.Parameters(expected: false),
                            severityOverride: .warning),
            // Page count must be > 0 (error)
            try! CheckEntry(typeID: "pages.count", enabled: true,
                            parameters: PageCountCheck.Parameters(operator: .moreThan, value: 0),
                            severityOverride: .error),
        ]
    )

    /// PDF/X-3 compliance profile — European print with ICC-based colour management.
    public static let pdfX3 = PreflightProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        name: "PDF/X-3",
        description: "European print-production profile for PDF/X-3 compliance with ICC-based colour management.",
        origin: .builtIn,
        checks: [
            try! CheckEntry(typeID: "pdf.conformance", enabled: true,
                            parameters: PDFConformanceCheck.Parameters(standard: .x3),
                            severityOverride: .error),
            try! CheckEntry(typeID: "fonts.not_embedded", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "marks.trim_box_set", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "marks.bleed_zero", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "file.encryption", enabled: true,
                            parameters: EncryptionCheck.Parameters(expected: false),
                            severityOverride: .error),
            try! CheckEntry(typeID: "pdf.output_intent", enabled: true,
                            parameters: OutputIntentCheck.Parameters(expected: true),
                            severityOverride: .error),
            try! CheckEntry(typeID: "images.resolution_below", enabled: true,
                            parameters: ResolutionBelowCheck.Parameters(thresholdPPI: 150),
                            severityOverride: .warning),
        ]
    )

    /// PDF/A-2b archival profile — long-term preservation with accessibility tagging.
    public static let pdfA2b = PreflightProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
        name: "PDF/A-2b",
        description: "Long-term archival profile for PDF/A-2b compliance — tagged, no encryption or JavaScript.",
        origin: .builtIn,
        checks: [
            try! CheckEntry(typeID: "pdf.conformance", enabled: true,
                            parameters: PDFConformanceCheck.Parameters(standard: .a2b),
                            severityOverride: .error),
            try! CheckEntry(typeID: "fonts.not_embedded", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "file.encryption", enabled: true,
                            parameters: EncryptionCheck.Parameters(expected: false),
                            severityOverride: .error),
            try! CheckEntry(typeID: "file.javascript", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "file.embedded_files", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "pdf.tagged", enabled: true,
                            parameters: TaggedCheck.Parameters(expected: true),
                            severityOverride: .error),
            try! CheckEntry(typeID: "pdf.transparency", enabled: true,
                            parameters: TransparencyCheck.Parameters(operator: .is),
                            severityOverride: .warning),
        ]
    )

    /// Digital print profile — short-run digital / toner production.
    public static let digitalPrint = PreflightProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
        name: "Digital Print",
        description: "Short-run digital and toner print profile — 3mm bleed, no overprint, no rich black on text.",
        origin: .builtIn,
        checks: [
            try! CheckEntry(typeID: "fonts.not_embedded", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "marks.trim_box_set", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "marks.bleed_less_than", enabled: true,
                            parameters: BleedLessThanCheck.Parameters(thresholdMM: 3.0),
                            severityOverride: .warning),
            try! CheckEntry(typeID: "colour.overprint", enabled: true,
                            parameters: OverprintCheck.Parameters(context: .white),
                            severityOverride: .error),
            try! CheckEntry(typeID: "colour.overprint", enabled: true,
                            parameters: OverprintCheck.Parameters(context: .fill),
                            severityOverride: .warning),
            try! CheckEntry(typeID: "colour.rich_black", enabled: true, parameters: EmptyParameters(), severityOverride: .warning),
            try! CheckEntry(typeID: "images.resolution_below", enabled: true,
                            parameters: ResolutionBelowCheck.Parameters(thresholdPPI: 150),
                            severityOverride: .warning),
            try! CheckEntry(typeID: "file.encryption", enabled: true,
                            parameters: EncryptionCheck.Parameters(expected: false),
                            severityOverride: .error),
            try! CheckEntry(typeID: "pdf.transparency", enabled: true,
                            parameters: TransparencyCheck.Parameters(operator: .is),
                            severityOverride: .warning),
        ]
    )

    /// Newspaper profile — web-offset / newsprint with strict ink limits.
    public static let newspaper = PreflightProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
        name: "Newspaper",
        description: "Web-offset and newsprint profile — strict ink limits, CMYK only, no transparency or spot colours.",
        origin: .builtIn,
        checks: [
            try! CheckEntry(typeID: "fonts.not_embedded", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "colour.space_used", enabled: true,
                            parameters: ColourSpaceUsedCheck.Parameters(colourSpace: .deviceRGB, operator: .is),
                            severityOverride: .error),
            try! CheckEntry(typeID: "colour.ink_coverage", enabled: true,
                            parameters: InkCoverageCheck.Parameters(thresholdPercent: 240, operator: .moreThan),
                            severityOverride: .error),
            try! CheckEntry(typeID: "colour.spot_used", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "pdf.transparency", enabled: true,
                            parameters: TransparencyCheck.Parameters(operator: .is),
                            severityOverride: .error),
            try! CheckEntry(typeID: "images.resolution_below", enabled: true,
                            parameters: ResolutionBelowCheck.Parameters(thresholdPPI: 150),
                            severityOverride: .warning),
            try! CheckEntry(typeID: "images.resolution_above", enabled: true,
                            parameters: ResolutionAboveCheck.Parameters(thresholdPPI: 400),
                            severityOverride: .warning),
            try! CheckEntry(typeID: "lines.stroke_below", enabled: true,
                            parameters: StrokeWeightBelowCheck.Parameters(thresholdPt: 0.25),
                            severityOverride: .warning),
        ]
    )

    /// Large format profile — signage, posters, banners with relaxed resolution.
    public static let largeFormat = PreflightProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
        name: "Large Format",
        description: "Signage, poster, and banner profile — relaxed resolution thresholds, CMYK preferred.",
        origin: .builtIn,
        checks: [
            try! CheckEntry(typeID: "fonts.not_embedded", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "colour.space_used", enabled: true,
                            parameters: ColourSpaceUsedCheck.Parameters(colourSpace: .deviceRGB, operator: .is),
                            severityOverride: .warning),
            try! CheckEntry(typeID: "images.resolution_below", enabled: true,
                            parameters: ResolutionBelowCheck.Parameters(thresholdPPI: 100),
                            severityOverride: .warning),
            try! CheckEntry(typeID: "file.encryption", enabled: true,
                            parameters: EncryptionCheck.Parameters(expected: false),
                            severityOverride: .error),
            try! CheckEntry(typeID: "lines.stroke_below", enabled: true,
                            parameters: StrokeWeightBelowCheck.Parameters(thresholdPt: 0.5),
                            severityOverride: .warning),
            try! CheckEntry(typeID: "marks.trim_box_set", enabled: true, parameters: EmptyParameters(), severityOverride: .warning),
            try! CheckEntry(typeID: "pdf.transparency", enabled: true,
                            parameters: TransparencyCheck.Parameters(operator: .is),
                            severityOverride: .warning),
        ]
    )

    /// AI content audit profile — flags AI-generated content and checks provenance metadata.
    public static let aiContentAudit = PreflightProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!,
        name: "AI Content Audit",
        description: "Editorial and news profile — flags AI-generated content, checks C2PA provenance metadata.",
        origin: .builtIn,
        checks: [
            try! CheckEntry(typeID: "images.genai", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "images.c2pa", enabled: true, parameters: EmptyParameters(), severityOverride: .warning),
            try! CheckEntry(typeID: "file.encryption", enabled: true,
                            parameters: EncryptionCheck.Parameters(expected: false),
                            severityOverride: .error),
            try! CheckEntry(typeID: "file.javascript", enabled: true, parameters: EmptyParameters(), severityOverride: .error),
            try! CheckEntry(typeID: "pdf.annotations", enabled: true, parameters: EmptyParameters(), severityOverride: .warning),
            try! CheckEntry(typeID: "images.resolution_below", enabled: true,
                            parameters: ResolutionBelowCheck.Parameters(thresholdPPI: 72),
                            severityOverride: .warning),
        ]
    )

    /// All built-in profiles.
    public static let allBuiltIn: [PreflightProfile] = [
        .pdfX1a, .pdfX4, .pdfX3, .pdfA2b, .screenDigital,
        .digitalPrint, .newspaper, .largeFormat, .loose, .aiContentAudit,
    ]
}
