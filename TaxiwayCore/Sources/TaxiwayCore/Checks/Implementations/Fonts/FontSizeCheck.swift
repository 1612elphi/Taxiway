import Foundation

public struct FontSizeCheck: ParameterisedCheck {
    public static let typeID = "fonts.size"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Font Size" }
    public var category: CheckCategory { .fonts }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var threshold: Double
        public var `operator`: NumericOperator
        public init(threshold: Double, operator: NumericOperator) {
            self.threshold = threshold
            self.operator = `operator`
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        return skip(message: "Font size detection requires content stream parsing (deferred)")
    }
}
