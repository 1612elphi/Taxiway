import Foundation

public struct FontNotEmbeddedCheck: ParameterisedCheck {
    public static let typeID = "fonts.not_embedded"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Font Not Embedded" }
    public var category: CheckCategory { .fonts }
    public var defaultSeverity: CheckSeverity { .error }

    public typealias Parameters = EmptyParameters

    public init(id: UUID = UUID(), parameters: Parameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let unembedded = document.fonts.filter { !$0.isEmbedded }
        if unembedded.isEmpty {
            return pass(message: "All fonts are embedded")
        }
        let names = unembedded.map { $0.name }
        let affectedItems = unembedded.map {
            AffectedItem.font(name: $0.name, pages: $0.pagesUsedOn)
        }
        return fail(
            message: "\(unembedded.count) font(s) not embedded",
            detail: "Unembedded fonts: \(names.joined(separator: ", "))",
            affectedItems: affectedItems
        )
    }
}
