import Foundation

public struct GenAIMetadataCheck: ParameterisedCheck {
    public static let typeID = "images.genai"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Generative AI Metadata" }
    public var category: CheckCategory { .images }
    public var defaultSeverity: CheckSeverity { .warning }

    public init(id: UUID = UUID(), parameters: EmptyParameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        if document.metadata.hasGenAIMetadata {
            return fail(
                message: "Generative AI metadata detected",
                affectedItems: [.document]
            )
        }
        return pass(message: "No generative AI metadata found")
    }
}
