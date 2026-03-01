import Foundation

public struct MetadataFieldPresentCheck: ParameterisedCheck {
    public static let typeID = "file.metadata.present"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Metadata Field Present" }
    public var category: CheckCategory { .file }
    public var defaultSeverity: CheckSeverity { .info }

    public struct Parameters: CheckParameters {
        public var fieldName: String
        public init(fieldName: String) { self.fieldName = fieldName }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let value = metadataValue(for: parameters.fieldName, in: document)
        if let value, !value.isEmpty {
            return pass(message: "\(parameters.fieldName) is set")
        }
        return fail(
            message: "\(parameters.fieldName) is missing or empty",
            affectedItems: [.document]
        )
    }

    private func metadataValue(for field: String, in doc: TaxiwayDocument) -> String? {
        switch field.lowercased() {
        case "title": return doc.metadata.title
        case "author": return doc.metadata.author
        case "subject": return doc.metadata.subject
        case "keywords": return doc.metadata.keywords
        case "producer": return doc.documentInfo.producer
        case "creator": return doc.documentInfo.creator
        default: return nil
        }
    }
}
