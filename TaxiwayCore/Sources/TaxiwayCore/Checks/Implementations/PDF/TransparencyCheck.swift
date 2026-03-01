import Foundation

public struct TransparencyCheck: ParameterisedCheck {
    public static let typeID = "pdf.transparency"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Transparency" }
    public var category: CheckCategory { .pdf }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var `operator`: ComparisonOperator
        public init(operator: ComparisonOperator) {
            self.operator = `operator`
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let hasTransparency = document.documentInfo.transparencyDetected

        switch parameters.operator {
        case .is:
            // Fail if transparency IS used
            if hasTransparency {
                return fail(
                    message: "Transparency detected in document",
                    affectedItems: [.document]
                )
            }
            return pass(message: "No transparency detected")

        case .isNot:
            // Fail if transparency is NOT used
            if !hasTransparency {
                return fail(
                    message: "No transparency detected in document",
                    affectedItems: [.document]
                )
            }
            return pass(message: "Transparency is present in document")
        }
    }
}
