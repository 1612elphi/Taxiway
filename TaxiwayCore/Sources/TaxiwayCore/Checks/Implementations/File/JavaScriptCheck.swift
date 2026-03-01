import Foundation

public struct JavaScriptCheck: ParameterisedCheck {
    public static let typeID = "file.javascript"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "JavaScript" }
    public var category: CheckCategory { .file }
    public var defaultSeverity: CheckSeverity { .error }

    public typealias Parameters = EmptyParameters

    public init(id: UUID = UUID(), parameters: Parameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        if document.documentInfo.hasJavaScript {
            return fail(
                message: "Document contains JavaScript",
                detail: "JavaScript actions were found in the PDF",
                affectedItems: [.document]
            )
        }
        return pass(message: "No JavaScript found")
    }
}
