import Foundation

public struct FileSizeMinCheck: ParameterisedCheck {
    public static let typeID = "file.size.min"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "File Size (min)" }
    public var category: CheckCategory { .file }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var minSizeMB: Double
        public init(minSizeMB: Double) { self.minSizeMB = minSizeMB }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let sizeMB = document.fileInfo.fileSizeMB
        if sizeMB < parameters.minSizeMB {
            return fail(
                message: "File is below \(String(format: "%.1f", parameters.minSizeMB)) MB minimum",
                detail: String(format: "File is %.1f MB", sizeMB),
                affectedItems: [.document]
            )
        }
        return pass(message: String(format: "File size OK (%.1f MB)", sizeMB))
    }
}
