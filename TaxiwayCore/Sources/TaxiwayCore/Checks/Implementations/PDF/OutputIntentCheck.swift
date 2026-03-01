import Foundation

public struct OutputIntentCheck: ParameterisedCheck {
    public static let typeID = "pdf.output_intent"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Output Intent" }
    public var category: CheckCategory { .pdf }
    public var defaultSeverity: CheckSeverity { .info }

    public struct Parameters: CheckParameters {
        public var expected: Bool
        public init(expected: Bool) { self.expected = expected }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let identifier = document.documentInfo.outputIntentIdentifier
        let isPresent = identifier != nil

        if isPresent == parameters.expected {
            if parameters.expected {
                return pass(message: "Output intent present: \(identifier!)")
            } else {
                return pass(message: "No output intent set")
            }
        }

        if parameters.expected {
            return fail(
                message: "No output intent set",
                detail: "Expected an output intent to be present",
                affectedItems: [.document]
            )
        } else {
            return fail(
                message: "Output intent present: \(identifier!)",
                detail: "Expected no output intent",
                affectedItems: [.document]
            )
        }
    }
}
