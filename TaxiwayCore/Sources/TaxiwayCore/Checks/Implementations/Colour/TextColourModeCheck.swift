import Foundation

public struct TextColourModeCheck: ParameterisedCheck {
    public static let typeID = "colour.text_mode"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Text Colour Mode" }
    public var category: CheckCategory { .colour }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var colourMode: ColourMode
        public var `operator`: ComparisonOperator
        public init(colourMode: ColourMode, operator: ComparisonOperator) {
            self.colourMode = colourMode
            self.operator = `operator`
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let textUsages = document.colourUsages.filter { $0.usageContexts.contains(.textFill) }
        let matching = textUsages.filter { $0.mode == parameters.colourMode }
        let found = !matching.isEmpty

        switch parameters.operator {
        case .is:
            if found {
                let pages = matching.flatMap { $0.pagesUsedOn }
                let uniquePages = Set(pages).sorted()
                let affectedItems = matching.map {
                    AffectedItem.colourSpace(
                        name: ColourUsageInfo.displayName(mode: $0.mode, components: $0.components, spotName: nil),
                        pages: $0.pagesUsedOn
                    )
                }
                return fail(
                    message: "\(parameters.colourMode.rawValue.uppercased()) text colour detected",
                    detail: "Found on page(s): \(uniquePages.map { String($0 + 1) }.joined(separator: ", "))",
                    affectedItems: affectedItems
                )
            }
            return pass(message: "No \(parameters.colourMode.rawValue.uppercased()) text colour found")

        case .isNot:
            if !found {
                return fail(
                    message: "No \(parameters.colourMode.rawValue.uppercased()) text colour found",
                    affectedItems: [.document]
                )
            }
            return pass(message: "\(parameters.colourMode.rawValue.uppercased()) text colour is present")
        }
    }
}
