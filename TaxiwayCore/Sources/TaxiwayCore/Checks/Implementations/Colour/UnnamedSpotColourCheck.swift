import Foundation

public struct UnnamedSpotColourCheck: ParameterisedCheck {
    public static let typeID = "colour.unnamed_spot"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Unnamed Spot Colour" }
    public var category: CheckCategory { .colour }
    public var defaultSeverity: CheckSeverity { .warning }

    public init(id: UUID = UUID(), parameters: EmptyParameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let unnamed = document.spotColours.filter {
            $0.name.trimmingCharacters(in: .whitespaces).isEmpty
        }

        if unnamed.isEmpty {
            return pass(message: "No unnamed spot colours found")
        }

        let pages = Set(unnamed.flatMap { $0.pagesUsedOn }).sorted()
        let pageNumbers = pages.map { String($0 + 1) }.joined(separator: ", ")
        return fail(
            message: "\(unnamed.count) unnamed spot colour(s) detected",
            detail: "Found on page(s): \(pageNumbers)",
            affectedItems: [.document]
        )
    }
}
