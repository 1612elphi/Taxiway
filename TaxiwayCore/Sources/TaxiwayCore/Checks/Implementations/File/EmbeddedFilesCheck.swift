import Foundation

public struct EmbeddedFilesCheck: ParameterisedCheck {
    public static let typeID = "file.embedded_files"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Embedded Files" }
    public var category: CheckCategory { .file }
    public var defaultSeverity: CheckSeverity { .warning }

    public typealias Parameters = EmptyParameters

    public init(id: UUID = UUID(), parameters: Parameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        if document.documentInfo.hasEmbeddedFiles {
            return fail(
                message: "Document contains embedded files",
                detail: "Embedded file attachments are present in the PDF",
                affectedItems: [.document]
            )
        }
        return pass(message: "No embedded files found")
    }
}
