import Foundation

public struct EncryptionCheck: ParameterisedCheck {
    public static let typeID = "file.encryption"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Encryption" }
    public var category: CheckCategory { .file }
    public var defaultSeverity: CheckSeverity { .error }

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
        let isEncrypted = document.fileInfo.isEncrypted
        if isEncrypted != parameters.expected {
            if parameters.expected {
                return fail(
                    message: "File is not encrypted",
                    detail: "Expected file to be encrypted",
                    affectedItems: [.document]
                )
            } else {
                return fail(
                    message: "File is encrypted",
                    detail: "Expected file to not be encrypted",
                    affectedItems: [.document]
                )
            }
        }
        if parameters.expected {
            return pass(message: "File is encrypted")
        } else {
            return pass(message: "File is not encrypted")
        }
    }
}
