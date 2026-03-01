import Foundation

public struct ResolutionRangeCheck: ParameterisedCheck {
    public static let typeID = "images.resolution_range"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Resolution Range" }
    public var category: CheckCategory { .images }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var minPPI: Double
        public var maxPPI: Double

        public init(minPPI: Double, maxPPI: Double) {
            self.minPPI = minPPI
            self.maxPPI = maxPPI
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let images = document.images
        if images.isEmpty {
            return pass(message: "No images in document")
        }

        let minThreshold = parameters.minPPI
        let maxThreshold = parameters.maxPPI

        let affected = images.filter { img in
            let minPPI = min(img.effectivePPIHorizontal, img.effectivePPIVertical)
            let maxPPI = max(img.effectivePPIHorizontal, img.effectivePPIVertical)
            return minPPI < minThreshold || maxPPI > maxThreshold
        }

        if affected.isEmpty {
            return pass(message: "All images within \(String(format: "%.0f", minThreshold))–\(String(format: "%.0f", maxThreshold)) PPI range")
        }

        let affectedItems = affected.map { AffectedItem.image(id: $0.id, page: $0.pageIndex, bounds: $0.bounds) }
        let details = affected.map { img in
            let hPPI = img.effectivePPIHorizontal
            let vPPI = img.effectivePPIVertical
            return "\(img.id): \(String(format: "%.0f", hPPI))×\(String(format: "%.0f", vPPI)) PPI"
        }.joined(separator: ", ")

        return fail(
            message: "\(affected.count) image(s) outside \(String(format: "%.0f", minThreshold))–\(String(format: "%.0f", maxThreshold)) PPI range",
            detail: details,
            affectedItems: affectedItems
        )
    }
}
