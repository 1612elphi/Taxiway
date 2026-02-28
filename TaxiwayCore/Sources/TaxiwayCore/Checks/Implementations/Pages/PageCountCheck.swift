import Foundation

public struct PageCountCheck: ParameterisedCheck {
    public static let typeID = "pages.count"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Page Count" }
    public var category: CheckCategory { .pages }
    public var defaultSeverity: CheckSeverity { .error }

    public struct Parameters: CheckParameters {
        public var `operator`: NumericOperator
        public var value: Int

        public init(operator: NumericOperator, value: Int) {
            self.operator = `operator`
            self.value = value
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let count = document.fileInfo.pageCount
        let op = parameters.operator
        let target = parameters.value

        let passed: Bool
        switch op {
        case .equals:
            passed = count == target
        case .lessThan:
            passed = count < target
        case .moreThan:
            passed = count > target
        }

        if passed {
            return pass(message: "Page count is \(count)")
        }

        let opDescription: String
        switch op {
        case .equals:
            opDescription = "equal to \(target)"
        case .lessThan:
            opDescription = "less than \(target)"
        case .moreThan:
            opDescription = "more than \(target)"
        }

        return fail(
            message: "Page count \(count) is not \(opDescription)",
            affectedItems: [.document]
        )
    }
}
