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
        let thin = document.strokeInfos.filter { $0.lineWidth > 0 && $0.lineWidth < parameters.thresholdPt }

        if thin.isEmpty {
            return pass(message: "No strokes below \(formatted(parameters.thresholdPt)) pt")
        }

        let pages = Set(thin.map(\.pageIndex)).sorted()
        let thinnest = thin.map(\.lineWidth).min()!

        return fail(
            message: "\(thin.count) stroke(s) below \(formatted(parameters.thresholdPt)) pt",
            detail: "Thinnest: \(formatted(thinnest)) pt on \(pages.map { "page \($0 + 1)" }.joined(separator: ", "))",
            affectedItems: pages.map { .page(index: $0) }
        )
    }

    private func formatted(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.3f", value)
    }
}
