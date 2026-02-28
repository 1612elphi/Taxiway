import Foundation

public struct ColourSpaceUsedCheck: ParameterisedCheck {
    public static let typeID = "colour.space_used"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Colour Space Used" }
    public var category: CheckCategory { .colour }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var colourSpace: ColourSpaceName
        public var `operator`: ComparisonOperator
        public init(colourSpace: ColourSpaceName, operator: ComparisonOperator) {
            self.colourSpace = colourSpace
            self.operator = `operator`
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let matching = document.colourSpaces.filter { $0.name == parameters.colourSpace }
        let found = !matching.isEmpty

        switch parameters.operator {
        case .is:
            if found {
                let pages = matching.flatMap { $0.pagesUsedOn }
                let uniquePages = Set(pages).sorted()
                let affectedItems = matching.map {
                    AffectedItem.colourSpace(name: $0.name.rawValue, pages: $0.pagesUsedOn)
                }
                return fail(
                    message: "\(parameters.colourSpace.rawValue) colour space detected",
                    detail: "Found on page(s): \(uniquePages.map { String($0 + 1) }.joined(separator: ", "))",
                    affectedItems: affectedItems
                )
            }
            return pass(message: "\(parameters.colourSpace.rawValue) colour space not found")

        case .isNot:
            if !found {
                return fail(
                    message: "\(parameters.colourSpace.rawValue) colour space not found",
                    affectedItems: [.document]
                )
            }
            return pass(message: "\(parameters.colourSpace.rawValue) colour space is present")
        }
    }
}
