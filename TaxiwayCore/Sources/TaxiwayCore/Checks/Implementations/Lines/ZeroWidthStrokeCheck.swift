import Foundation

public struct ZeroWidthStrokeCheck: ParameterisedCheck {
    public static let typeID = "lines.zero_width"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Zero-Width Strokes" }
    public var category: CheckCategory { .lines }
    public var defaultSeverity: CheckSeverity { .warning }

    public init(id: UUID = UUID(), parameters: EmptyParameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        return skip(message: "Zero-width stroke detection requires content stream parsing (deferred)")
    }
}
