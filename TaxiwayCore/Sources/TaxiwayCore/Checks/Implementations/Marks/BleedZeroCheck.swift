import Foundation

public struct BleedZeroCheck: ParameterisedCheck {
    public static let typeID = "marks.bleed_zero"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Bleed is Zero" }
    public var category: CheckCategory { .marks }
    public var defaultSeverity: CheckSeverity { .error }

    public init(id: UUID = UUID(), parameters: EmptyParameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        if document.pages.isEmpty {
            return pass(message: "No pages to check")
        }

        var affected: [AffectedItem] = []

        for page in document.pages {
            let margins = page.bleedMargins
            if margins.left == 0 && margins.right == 0 && margins.top == 0 && margins.bottom == 0 {
                affected.append(.page(index: page.index))
            }
        }

        if affected.isEmpty {
            return pass(message: "All pages have bleed")
        }

        return fail(
            message: "\(affected.count) page(s) have zero bleed",
            affectedItems: affected
        )
    }
}
