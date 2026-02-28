import Foundation

public struct LinearizedCheck: ParameterisedCheck {
    public static let typeID = "pdf.linearized"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Linearized" }
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
        let isLinearized = document.documentInfo.isLinearized
        if isLinearized == parameters.expected {
            if parameters.expected {
                return pass(message: "Document is linearized")
            } else {
                return pass(message: "Document is not linearized")
            }
        }
        if parameters.expected {
            return fail(
                message: "Document is not linearized",
                detail: "Expected document to be linearized",
                affectedItems: [.document]
            )
        } else {
            return fail(
                message: "Document is linearized",
                detail: "Expected document to not be linearized",
                affectedItems: [.document]
            )
        }
    }
}
