import Foundation

public struct PDFVersionCheck: ParameterisedCheck {
    public static let typeID = "pdf.version"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "PDF Version" }
    public var category: CheckCategory { .pdf }
    public var defaultSeverity: CheckSeverity { .error }

    public struct Parameters: CheckParameters {
        public var `operator`: ComparisonOperator
        public var version: String
        public init(operator: ComparisonOperator, version: String) {
            self.operator = `operator`
            self.version = version
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let actual = document.documentInfo.pdfVersion
        switch parameters.operator {
        case .is:
            if actual == parameters.version {
                return pass(message: "PDF version is \(actual)")
            }
            return fail(
                message: "PDF version mismatch",
                detail: "Expected \(parameters.version), found \(actual)",
                affectedItems: [.document]
            )
        case .isNot:
            if actual != parameters.version {
                return pass(message: "PDF version is \(actual) (not \(parameters.version))")
            }
            return fail(
                message: "PDF version should not be \(parameters.version)",
                detail: "Found \(actual)",
                affectedItems: [.document]
            )
        }
    }
}
