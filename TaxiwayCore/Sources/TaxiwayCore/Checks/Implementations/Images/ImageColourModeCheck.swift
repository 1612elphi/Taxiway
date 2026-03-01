import Foundation

public struct ImageColourModeCheck: ParameterisedCheck {
    public static let typeID = "images.colour_mode"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Image Colour Mode" }
    public var category: CheckCategory { .images }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var colourMode: ImageColourMode
        public var `operator`: ComparisonOperator

        public init(colourMode: ImageColourMode, operator: ComparisonOperator) {
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
        let images = document.images
        if images.isEmpty {
            return pass(message: "No images in document")
        }

        let op = parameters.operator
        let target = parameters.colourMode

        let affected: [ImageInfo]
        switch op {
        case .is:
            affected = images.filter { $0.colourMode == target }
        case .isNot:
            affected = images.filter { $0.colourMode != target }
        }

        if affected.isEmpty {
            switch op {
            case .is:
                return pass(message: "No images use \(target.rawValue) colour mode")
            case .isNot:
                return pass(message: "All images use \(target.rawValue) colour mode")
            }
        }

        let affectedItems = affected.map { AffectedItem.image(id: $0.id, page: $0.pageIndex, bounds: $0.bounds) }
        let verb: String
        switch op {
        case .is:
            verb = "use"
        case .isNot:
            verb = "do not use"
        }
        return fail(
            message: "\(affected.count) image(s) \(verb) \(target.rawValue) colour mode",
            detail: "Affected: \(affected.map(\.id).joined(separator: ", "))",
            affectedItems: affectedItems
        )
    }
}
