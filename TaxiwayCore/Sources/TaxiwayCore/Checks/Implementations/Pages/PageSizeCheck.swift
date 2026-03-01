import Foundation
import CoreGraphics

public struct PageSizeCheck: ParameterisedCheck {
    public static let typeID = "pages.size"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Page Size" }
    public var category: CheckCategory { .pages }
    public var defaultSeverity: CheckSeverity { .error }

    public struct Parameters: CheckParameters {
        public var targetWidthPt: Double
        public var targetHeightPt: Double
        public var tolerancePt: Double

        public init(targetWidthPt: Double, targetHeightPt: Double, tolerancePt: Double) {
            self.targetWidthPt = targetWidthPt
            self.targetHeightPt = targetHeightPt
            self.tolerancePt = tolerancePt
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

        let targetW = parameters.targetWidthPt
        let targetH = parameters.targetHeightPt
        let tol = parameters.tolerancePt

        var affected: [AffectedItem] = []

        for page in document.pages {
            let trim = page.effectiveTrimBox
            let w = Double(trim.width)
            let h = Double(trim.height)

            // Check normal orientation
            let normalMatch = abs(w - targetW) <= tol && abs(h - targetH) <= tol
            // Check rotated orientation (width/height swapped)
            let rotatedMatch = abs(w - targetH) <= tol && abs(h - targetW) <= tol

            if !normalMatch && !rotatedMatch {
                affected.append(.page(index: page.index))
            }
        }

        if affected.isEmpty {
            return pass(message: "All pages match target size (\(String(format: "%.1f", targetW)) x \(String(format: "%.1f", targetH)) pt)")
        }

        return fail(
            message: "\(affected.count) page(s) do not match target size (\(String(format: "%.1f", targetW)) x \(String(format: "%.1f", targetH)) pt)",
            affectedItems: affected
        )
    }
}
