import Foundation

public struct PageRotationCheck: ParameterisedCheck {
    public static let typeID = "pages.rotation"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Page Rotation" }
    public var category: CheckCategory { .pages }
    public var defaultSeverity: CheckSeverity { .warning }

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
            if page.rotation != 0 {
                affected.append(.page(index: page.index))
            }
        }

        if affected.isEmpty {
            return pass(message: "No pages are rotated")
        }

        return fail(
            message: "\(affected.count) page(s) have non-zero rotation",
            affectedItems: affected
        )
    }
}
