import Foundation

public struct StrokeWeightBelowCheck: ParameterisedCheck {
    public static let typeID = "lines.stroke_below"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Stroke Weight Below Threshold" }
    public var category: CheckCategory { .lines }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var thresholdPt: Double
        public init(thresholdPt: Double) { self.thresholdPt = thresholdPt }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        return skip(message: "Stroke weight detection requires content stream parsing (deferred)")
    }
}
