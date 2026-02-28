import Foundation

public struct AlphaChannelCheck: ParameterisedCheck {
    public static let typeID = "images.alpha"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Alpha Channel" }
    public var category: CheckCategory { .images }
    public var defaultSeverity: CheckSeverity { .warning }

    public init(id: UUID = UUID(), parameters: EmptyParameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let images = document.images
        if images.isEmpty {
            return pass(message: "No images in document")
        }

        let affected = images.filter { $0.hasAlphaChannel }

        if affected.isEmpty {
            return pass(message: "No images have alpha channels")
        }

        let affectedItems = affected.map { AffectedItem.image(id: $0.id, page: $0.pageIndex) }
        return fail(
            message: "\(affected.count) image(s) contain alpha channel",
            detail: "Affected: \(affected.map(\.id).joined(separator: ", "))",
            affectedItems: affectedItems
        )
    }
}
