import Foundation
import CoreGraphics

public struct MixedPageSizesCheck: ParameterisedCheck {
    public static let typeID = "pages.mixed_sizes"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Mixed Page Sizes" }
    public var category: CheckCategory { .pages }
    public var defaultSeverity: CheckSeverity { .warning }

    public init(id: UUID = UUID(), parameters: EmptyParameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let pages = document.pages
        if pages.count <= 1 {
            return pass(message: "Not enough pages to compare")
        }

        let referenceTrim = pages[0].effectiveTrimBox
        let refW = Double(referenceTrim.width)
        let refH = Double(referenceTrim.height)
        let tolerance = 1.0

        var affected: [AffectedItem] = []

        for page in pages {
            let trim = page.effectiveTrimBox
            let w = Double(trim.width)
            let h = Double(trim.height)

            if abs(w - refW) > tolerance || abs(h - refH) > tolerance {
                affected.append(.page(index: page.index))
            }
        }

        if affected.isEmpty {
            return pass(message: "All pages have the same size")
        }

        // Also include the first page as a reference point in affected items
        affected.insert(.page(index: pages[0].index), at: 0)

        return fail(
            message: "Pages have mixed sizes",
            detail: "\(affected.count) page(s) involved",
            affectedItems: affected
        )
    }
}
