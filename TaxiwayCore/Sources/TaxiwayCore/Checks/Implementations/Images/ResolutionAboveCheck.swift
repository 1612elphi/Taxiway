import Foundation

public struct ResolutionAboveCheck: ParameterisedCheck {
    public static let typeID = "images.resolution_above"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Resolution Above Threshold" }
    public var category: CheckCategory { .images }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var thresholdPPI: Double
        public init(thresholdPPI: Double) { self.thresholdPPI = thresholdPPI }
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

        let threshold = parameters.thresholdPPI
        let affected = images.filter {
            max($0.effectivePPIHorizontal, $0.effectivePPIVertical) > threshold
        }

        if affected.isEmpty {
            return pass(message: "All images within maximum resolution of \(String(format: "%.0f", threshold)) PPI")
        }

        let affectedItems = affected.map { AffectedItem.image(id: $0.id, page: $0.pageIndex) }
        let details = affected.map { img in
            let ppi = max(img.effectivePPIHorizontal, img.effectivePPIVertical)
            return "\(img.id): \(String(format: "%.0f", ppi)) PPI"
        }.joined(separator: ", ")

        return fail(
            message: "\(affected.count) image(s) exceed \(String(format: "%.0f", threshold)) PPI",
            detail: details,
            affectedItems: affectedItems
        )
    }
}
