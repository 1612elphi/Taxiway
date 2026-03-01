import Foundation

public struct FontTypeCheck: ParameterisedCheck {
    public static let typeID = "fonts.type"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Font Type" }
    public var category: CheckCategory { .fonts }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var fontType: FontType
        public var `operator`: ComparisonOperator
        public init(fontType: FontType, operator: ComparisonOperator) {
            self.fontType = fontType
            self.operator = `operator`
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        switch parameters.operator {
        case .is:
            let matching = document.fonts.filter { $0.type == parameters.fontType }
            if matching.isEmpty {
                return pass(message: "No \(parameters.fontType.rawValue) fonts found")
            }
            let names = matching.map { $0.name }
            let affectedItems = matching.map {
                AffectedItem.font(name: $0.name, pages: $0.pagesUsedOn)
            }
            return fail(
                message: "\(matching.count) \(parameters.fontType.rawValue) font(s) detected",
                detail: "Fonts: \(names.joined(separator: ", "))",
                affectedItems: affectedItems
            )

        case .isNot:
            let nonMatching = document.fonts.filter { $0.type != parameters.fontType }
            if nonMatching.isEmpty {
                return pass(message: "All fonts are \(parameters.fontType.rawValue)")
            }
            let names = nonMatching.map { $0.name }
            let affectedItems = nonMatching.map {
                AffectedItem.font(name: $0.name, pages: $0.pagesUsedOn)
            }
            return fail(
                message: "\(nonMatching.count) font(s) are not \(parameters.fontType.rawValue)",
                detail: "Fonts: \(names.joined(separator: ", "))",
                affectedItems: affectedItems
            )
        }
    }
}
