import Foundation

public struct SpotColourCountCheck: ParameterisedCheck {
    public static let typeID = "colour.spot_count"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Spot Colour Count" }
    public var category: CheckCategory { .colour }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var maxCount: Int
        public init(maxCount: Int) { self.maxCount = maxCount }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let count = document.spotColours.count
        if count > parameters.maxCount {
            let names = document.spotColours.map { $0.name }
            return fail(
                message: "Too many spot colours (\(count), max \(parameters.maxCount))",
                detail: "Spot colours: \(names.joined(separator: ", "))",
                affectedItems: [.document]
            )
        }
        return pass(message: "Spot colour count OK (\(count) of \(parameters.maxCount) max)")
    }
}
