import Foundation

public struct TrimBoxSetCheck: ParameterisedCheck {
    public static let typeID = "marks.trim_box_set"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Trim Box Set" }
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
            if page.trimBox == nil {
                affected.append(.page(index: page.index))
            }
        }

        if affected.isEmpty {
            return pass(message: "All pages have a trim box defined")
        }

        return fail(
            message: "\(affected.count) page(s) missing trim box",
            affectedItems: affected
        )
    }
}
