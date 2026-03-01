import Foundation

public struct C2PACheck: ParameterisedCheck {
    public static let typeID = "images.c2pa"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "C2PA Content Credentials" }
    public var category: CheckCategory { .images }
    public var defaultSeverity: CheckSeverity { .info }

    public init(id: UUID = UUID(), parameters: EmptyParameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        if document.metadata.hasC2PA {
            return fail(
                message: "C2PA content credentials detected",
                affectedItems: [.document]
            )
        }
        return pass(message: "No C2PA content credentials found")
    }
}
