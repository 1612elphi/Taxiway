import Foundation

public enum PDFStandard: String, Codable, Sendable, Equatable, CaseIterable {
    case x1a = "X-1a"
    case x3 = "X-3"
    case x4 = "X-4"
    case a1b = "A-1b"
    case a2b = "A-2b"
    case a3b = "A-3b"

    /// The output intent subtype to match for this standard.
    var expectedSubtype: String {
        switch self {
        case .x1a, .x3, .x4:
            return "GTS_PDFX"
        case .a1b, .a2b, .a3b:
            return "GTS_PDFA1"
        }
    }

    /// A human-readable label such as "PDF/X-1a".
    var displayName: String {
        switch self {
        case .x1a: return "PDF/X-1a"
        case .x3: return "PDF/X-3"
        case .x4: return "PDF/X-4"
        case .a1b: return "PDF/A-1b"
        case .a2b: return "PDF/A-2b"
        case .a3b: return "PDF/A-3b"
        }
    }
}

public struct PDFConformanceCheck: ParameterisedCheck {
    public static let typeID = "pdf.conformance"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "PDF Conformance" }
    public var category: CheckCategory { .pdf }
    public var defaultSeverity: CheckSeverity { .error }

    public struct Parameters: CheckParameters {
        public var standard: PDFStandard
        public init(standard: PDFStandard) { self.standard = standard }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let intents = document.metadata.outputIntents
        let matchingIntent = intents.first { $0.subtype == parameters.standard.expectedSubtype }
        if matchingIntent != nil {
            return pass(message: "Document conforms to \(parameters.standard.displayName)")
        }
        if intents.isEmpty {
            return fail(
                message: "No output intents found for \(parameters.standard.displayName)",
                detail: "Document has no output intents",
                affectedItems: [.document]
            )
        }
        let foundSubtypes = intents.map(\.subtype).joined(separator: ", ")
        return fail(
            message: "Document does not conform to \(parameters.standard.displayName)",
            detail: "Expected output intent subtype \"\(parameters.standard.expectedSubtype)\", found: \(foundSubtypes)",
            affectedItems: [.document]
        )
    }
}
