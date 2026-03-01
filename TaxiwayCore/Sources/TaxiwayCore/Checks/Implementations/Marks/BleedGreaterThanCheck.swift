import Foundation

public struct BleedGreaterThanCheck: ParameterisedCheck {
    public static let typeID = "marks.bleed_greater_than"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Bleed Greater Than" }
    public var category: CheckCategory { .marks }
    public var defaultSeverity: CheckSeverity { .warning }

    private static let mmToPoints = 72.0 / 25.4

    public struct Parameters: CheckParameters {
        public var thresholdMM: Double

        public init(thresholdMM: Double) {
            self.thresholdMM = thresholdMM
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        if document.pages.isEmpty {
            return pass(message: "No pages to check")
        }

        let thresholdPt = parameters.thresholdMM * Self.mmToPoints
        var affected: [AffectedItem] = []

        for page in document.pages {
            let margins = page.bleedMargins
            let sides = [margins.left, margins.right, margins.top, margins.bottom]

            let hasExcessiveBleed = sides.contains { side in
                side > thresholdPt
            }

            if hasExcessiveBleed {
                affected.append(.page(index: page.index))
            }
        }

        if affected.isEmpty {
            return pass(message: "All bleed margins within \(String(format: "%.1f", parameters.thresholdMM)) mm")
        }

        return fail(
            message: "\(affected.count) page(s) have bleed greater than \(String(format: "%.1f", parameters.thresholdMM)) mm",
            affectedItems: affected
        )
    }
}
