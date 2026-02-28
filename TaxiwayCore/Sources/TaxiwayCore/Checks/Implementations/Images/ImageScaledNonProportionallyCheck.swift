import Foundation

public struct ImageScaledNonProportionallyCheck: ParameterisedCheck {
    public static let typeID = "images.scaled_non_proportional"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Image Scaled Non-Proportionally" }
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
        var affected: [ImageInfo] = []

        for img in images {
            guard img.widthPixels > 0, img.heightPixels > 0,
                  img.effectiveWidthPoints > 0, img.effectiveHeightPoints > 0 else { continue }

            let scaleX = img.effectiveWidthPoints / Double(img.widthPixels)
            let scaleY = img.effectiveHeightPoints / Double(img.heightPixels)

            // Non-proportional if the horizontal and vertical scale factors differ
            // by more than the tolerance relative to the larger scale factor.
            let maxScale = max(scaleX, scaleY)
            guard maxScale > 0 else { continue }
            let diff = abs(scaleX - scaleY) / maxScale
            if diff > tolerance {
                affected.append(img)
            }
        }

        if affected.isEmpty {
            return pass(message: "All images are scaled proportionally")
        }

        let affectedItems = affected.map { AffectedItem.image(id: $0.id, page: $0.pageIndex) }
        let details = affected.map { img in
            let scaleX = img.effectiveWidthPoints / Double(img.widthPixels)
            let scaleY = img.effectiveHeightPoints / Double(img.heightPixels)
            return "\(img.id): X=\(String(format: "%.2f", scaleX)), Y=\(String(format: "%.2f", scaleY))"
        }.joined(separator: ", ")

        return fail(
            message: "\(affected.count) image(s) scaled non-proportionally",
            detail: details,
            affectedItems: affectedItems
        )
    }
}
