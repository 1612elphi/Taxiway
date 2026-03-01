import Foundation

public struct InkCoverageCheck: ParameterisedCheck {
    public static let typeID = "colour.ink_coverage"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Ink Coverage" }
    public var category: CheckCategory { .colour }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var thresholdPercent: Double
        public var `operator`: NumericOperator
        public init(thresholdPercent: Double, operator: NumericOperator) {
            self.thresholdPercent = thresholdPercent
            self.operator = `operator`
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let offending = document.colourUsages.filter { usage in
            guard let inkSum = usage.inkSum else { return false }
            switch parameters.operator {
            case .moreThan:
                return inkSum > parameters.thresholdPercent
            case .lessThan:
                return inkSum < parameters.thresholdPercent
            case .equals:
                return abs(inkSum - parameters.thresholdPercent) < 0.01
            }
        }

        if offending.isEmpty {
            return pass(message: "All ink coverage values within threshold (\(Int(parameters.thresholdPercent))%)")
        }

        let details = offending.map { "\($0.name) (\(String(format: "%.0f", $0.inkSum ?? 0))%)" }
        return fail(
            message: "\(offending.count) colour(s) exceed ink coverage threshold",
            detail: details.joined(separator: ", "),
            affectedItems: [.document]
        )
    }
}
