import Foundation

public struct ImageScaledCheck: ParameterisedCheck {
    public static let typeID = "images.scaled"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Image Scaled" }
    public var category: CheckCategory { .images }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var tolerancePercent: Double
        public init(tolerancePercent: Double) { self.tolerancePercent = tolerancePercent }
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

        let tolerance = parameters.tolerancePercent / 100.0
        var affected: [(ImageInfo, Double)] = []

        for img in images {
            guard img.widthPixels > 0, img.effectiveWidthPoints > 0 else { continue }
            // Scale factor: ratio of placed size to native pixel size
            // At 1:1, each pixel occupies 1 point (72 PPI), so native width in points = widthPixels
            let scaleFactor = img.effectiveWidthPoints / Double(img.widthPixels)
            if abs(1.0 - scaleFactor) > tolerance {
                let scalePercent = scaleFactor * 100.0
                affected.append((img, scalePercent))
            }
        }

        if affected.isEmpty {
            return pass(message: "No images are scaled beyond \(String(format: "%.0f", parameters.tolerancePercent))% tolerance")
        }

        let affectedItems = affected.map { AffectedItem.image(id: $0.0.id, page: $0.0.pageIndex) }
        let details = affected.map { img, pct in
            "\(img.id): \(String(format: "%.1f", pct))%"
        }.joined(separator: ", ")

        return fail(
            message: "\(affected.count) image(s) are scaled",
            detail: details,
            affectedItems: affectedItems
        )
    }
}
