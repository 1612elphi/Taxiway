import Foundation

public struct TaggedCheck: ParameterisedCheck {
    public static let typeID = "pdf.tagged"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Tagged PDF" }
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
        let isTagged = document.documentInfo.isTagged
        if isTagged == parameters.expected {
            if parameters.expected {
                return pass(message: "Document is tagged")
            } else {
                return pass(message: "Document is not tagged")
            }
        }
        if parameters.expected {
            return fail(
                message: "Document is not tagged",
                detail: "Expected document to be tagged",
                affectedItems: [.document]
            )
        } else {
            return fail(
                message: "Document is tagged",
                detail: "Expected document to not be tagged",
                affectedItems: [.document]
            )
        }
    }
}
