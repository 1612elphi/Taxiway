import Foundation

public struct LayersPresentCheck: ParameterisedCheck {
    public static let typeID = "pdf.layers"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Layers Present" }
    public var category: CheckCategory { .pdf }
    public var defaultSeverity: CheckSeverity { .info }

    public typealias Parameters = EmptyParameters

    public init(id: UUID = UUID(), parameters: Parameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        if document.documentInfo.hasLayers {
            return fail(
                message: "Document contains layers",
                affectedItems: [.document]
            )
        }
        return pass(message: "Document does not contain layers")
    }
}
