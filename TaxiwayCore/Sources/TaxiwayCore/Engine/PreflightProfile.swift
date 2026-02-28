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

    /// All built-in profiles.
    public static let allBuiltIn: [PreflightProfile] = [.pdfX1a, .pdfX4, .screenDigital, .loose]
}
