import Foundation

public struct SpotColourUsedCheck: ParameterisedCheck {
    public static let typeID = "colour.spot_used"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Spot Colour Used" }
    public var category: CheckCategory { .colour }
    public var defaultSeverity: CheckSeverity { .info }

    public typealias Parameters = EmptyParameters

    public init(id: UUID = UUID(), parameters: Parameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        if document.spotColours.isEmpty {
            return pass(message: "No spot colours found")
        }
        let names = document.spotColours.map { $0.name }
        return fail(
            message: "\(document.spotColours.count) spot colour(s) detected",
            detail: "Spot colours: \(names.joined(separator: ", "))",
            affectedItems: [.document]
        )
    }
}
