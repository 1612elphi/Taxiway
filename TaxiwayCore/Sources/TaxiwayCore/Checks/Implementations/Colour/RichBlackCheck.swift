import Foundation

public struct RichBlackCheck: ParameterisedCheck {
    public static let typeID = "colour.rich_black"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Rich Black" }
    public var category: CheckCategory { .colour }
    public var defaultSeverity: CheckSeverity { .info }

    public init(id: UUID = UUID(), parameters: EmptyParameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let richBlacks = document.colourUsages.filter { usage in
            guard usage.mode == .cmyk, usage.components.count == 4 else { return false }
            let k = usage.components[3]
            guard k >= 0.99 else { return false }
            return usage.components[0...2].contains { $0 > 0.001 }
        }

        if richBlacks.isEmpty {
            return pass(message: "No rich black colours detected")
        }

        let names = richBlacks.map { $0.name }
        return fail(
            message: "\(richBlacks.count) rich black colour(s) detected",
            detail: "Colours: \(names.joined(separator: ", "))",
            affectedItems: [.document]
        )
    }
}
