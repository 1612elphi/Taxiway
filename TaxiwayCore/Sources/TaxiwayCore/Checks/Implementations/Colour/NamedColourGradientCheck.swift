import Foundation

public struct NamedColourGradientCheck: ParameterisedCheck {
    public static let typeID = "colour.named_gradient"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Named Colour in Gradient" }
    public var category: CheckCategory { .colour }
    public var defaultSeverity: CheckSeverity { .warning }

    public init(id: UUID = UUID(), parameters: EmptyParameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let spots = document.gradientSpotColours

        if spots.isEmpty {
            return pass(message: "No named colours used in gradients")
        }

        let names = spots.map(\.name).sorted()
        let pages = Set(spots.flatMap(\.pagesUsedOn)).sorted()

        return fail(
            message: "\(spots.count) named colour(s) used in gradients",
            detail: names.joined(separator: ", "),
            affectedItems: pages.map { .page(index: $0) }
        )
    }
}
