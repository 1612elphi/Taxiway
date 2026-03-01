import Foundation

public struct MetadataFieldMatchesCheck: ParameterisedCheck {
    public static let typeID = "file.metadata.matches"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Metadata Field Matches" }
    public var category: CheckCategory { .file }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var fieldName: String
        public var expectedValue: String
        public init(fieldName: String, expectedValue: String) {
            self.fieldName = fieldName
            self.expectedValue = expectedValue
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let value = metadataValue(for: parameters.fieldName, in: document)
        guard let value, !value.isEmpty else {
            return fail(
                message: "\(parameters.fieldName) is missing or empty",
                detail: "Expected: \"\(parameters.expectedValue)\"",
                affectedItems: [.document]
            )
        }
        if value == parameters.expectedValue {
            return pass(message: "\(parameters.fieldName) matches expected value")
        }
        return fail(
            message: "\(parameters.fieldName) does not match expected value",
            detail: "Expected: \"\(parameters.expectedValue)\", found: \"\(value)\"",
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
