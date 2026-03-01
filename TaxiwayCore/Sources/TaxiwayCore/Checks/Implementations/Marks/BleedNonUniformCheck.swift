import Foundation

public struct BleedNonUniformCheck: ParameterisedCheck {
    public static let typeID = "marks.bleed_non_uniform"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Bleed Non-Uniform" }
    public var category: CheckCategory { .marks }
    public var defaultSeverity: CheckSeverity { .warning }

    private static let mmToPoints = 72.0 / 25.4

    public struct Parameters: CheckParameters {
        public var toleranceMM: Double

        public init(toleranceMM: Double = 0.5) {
            self.toleranceMM = toleranceMM
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters = Parameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        if document.pages.isEmpty {
            return pass(message: "No pages to check")
        }

        let tolerancePt = parameters.toleranceMM * Self.mmToPoints
        var affected: [AffectedItem] = []

        for page in document.pages {
            let margins = page.bleedMargins
            let sides = [margins.left, margins.right, margins.top, margins.bottom]

            guard let minSide = sides.min(), let maxSide = sides.max() else { continue }

            if (maxSide - minSide) > tolerancePt {
                affected.append(.page(index: page.index))
            }
        }

        if affected.isEmpty {
            return pass(message: "All pages have uniform bleed margins")
        }

        return fail(
            message: "\(affected.count) page(s) have non-uniform bleed margins",
            affectedItems: affected
        )
    }
}
