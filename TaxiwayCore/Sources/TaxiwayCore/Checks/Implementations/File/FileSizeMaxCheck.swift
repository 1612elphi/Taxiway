import Foundation

public struct FileSizeMaxCheck: ParameterisedCheck {
    public static let typeID = "file.size.max"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "File Size (max)" }
    public var category: CheckCategory { .file }
    public var defaultSeverity: CheckSeverity { .error }

    public struct Parameters: CheckParameters {
        public var maxSizeMB: Double
        public init(maxSizeMB: Double) { self.maxSizeMB = maxSizeMB }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let sizeMB = document.fileInfo.fileSizeMB
        if sizeMB > parameters.maxSizeMB {
            return fail(
                message: "File exceeds \(String(format: "%.1f", parameters.maxSizeMB)) MB",
                detail: String(format: "File is %.1f MB", sizeMB),
                affectedItems: [.document]
            )
        }
        return pass(message: String(format: "File size OK (%.1f MB)", sizeMB))
    }
}
