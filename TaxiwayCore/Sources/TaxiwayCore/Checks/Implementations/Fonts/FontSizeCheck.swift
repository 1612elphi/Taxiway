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
        if document.textFrames.isEmpty {
            return pass(message: "No text frames found")
        }

        let offending = document.textFrames.filter { frame in
            switch parameters.operator {
            case .lessThan:
                return frame.fontSize < parameters.threshold
            case .moreThan:
                return frame.fontSize > parameters.threshold
            case .equals:
                return abs(frame.fontSize - parameters.threshold) < 0.01
            }
        }

        if offending.isEmpty {
            return pass(message: "All text sizes within threshold (\(String(format: "%.1f", parameters.threshold)) pt)")
        }

        let details = offending.map {
            "\($0.fontName) at \(String(format: "%.1f", $0.fontSize)) pt (page \($0.pageIndex + 1))"
        }
        return fail(
            message: "\(offending.count) text frame(s) outside font size threshold",
            detail: details.joined(separator: ", "),
            affectedItems: offending.map {
                .textFrame(id: $0.id, page: $0.pageIndex, bounds: $0.bounds)
            }
        )
    }
}
