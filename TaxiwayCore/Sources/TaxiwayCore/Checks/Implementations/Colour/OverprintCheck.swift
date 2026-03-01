import Foundation

public struct OverprintCheck: ParameterisedCheck {
    public static let typeID = "colour.overprint"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Overprint" }
    public var category: CheckCategory { .colour }
    public var defaultSeverity: CheckSeverity { .warning }

    public enum OverprintCheckContext: String, Codable, Sendable, Equatable {
        case fill
        case stroke
        case text
        case white
    }

    public struct Parameters: CheckParameters {
        public var context: OverprintCheckContext
        public init(context: OverprintCheckContext) {
            self.context = context
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let matching: [OverprintInfo]

        switch parameters.context {
        case .fill:
            matching = document.overprintUsages.filter { $0.context == .fill }
        case .stroke:
            matching = document.overprintUsages.filter { $0.context == .stroke }
        case .text:
            matching = document.overprintUsages.filter { $0.context == .text }
        case .white:
            matching = document.overprintUsages.filter { $0.isWhiteOverprint }
        }

        if matching.isEmpty {
            let label: String
            switch parameters.context {
            case .fill: label = "fill overprint"
            case .stroke: label = "stroke overprint"
            case .text: label = "text overprint"
            case .white: label = "white overprint"
            }
            return pass(message: "No \(label) detected")
        }

        let pages = Set(matching.map(\.pageIndex)).sorted()
        let pageList = pages.map { "page \($0 + 1)" }.joined(separator: ", ")

        let label: String
        switch parameters.context {
        case .fill: label = "Fill overprint"
        case .stroke: label = "Stroke overprint"
        case .text: label = "Text overprint"
        case .white: label = "White overprint"
        }

        return fail(
            message: "\(label) detected on \(matching.count) usage(s)",
            detail: "Found on: \(pageList)",
            affectedItems: pages.map { .page(index: $0) }
        )
    }
}
