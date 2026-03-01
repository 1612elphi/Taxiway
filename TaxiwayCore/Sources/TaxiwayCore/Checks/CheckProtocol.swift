import Foundation

public protocol Check: Identifiable, Sendable {
    static var typeID: String { get }
    var id: UUID { get }
    var name: String { get }
    var category: CheckCategory { get }
    var defaultSeverity: CheckSeverity { get }
    func run(on document: TaxiwayDocument) -> CheckResult
}

public protocol CheckParameters: Codable, Sendable, Equatable {}

/// A Check that has typed parameters and supports severity override.
public protocol ParameterisedCheck: Check {
    associatedtype Parameters: CheckParameters
    var parameters: Parameters { get }
    var severityOverride: CheckSeverity? { get }
    init(id: UUID, parameters: Parameters, severityOverride: CheckSeverity?)
}

extension ParameterisedCheck {
    public var effectiveSeverity: CheckSeverity {
        severityOverride ?? defaultSeverity
    }

    public func pass(message: String) -> CheckResult {
        CheckResult(checkID: id, checkTypeID: Self.typeID, status: .pass, severity: effectiveSeverity, message: message)
    }

    public func fail(message: String, detail: String? = nil, affectedItems: [AffectedItem] = []) -> CheckResult {
        CheckResult(checkID: id, checkTypeID: Self.typeID, status: .fail, severity: effectiveSeverity, message: message, detail: detail, affectedItems: affectedItems)
    }

    public func skip(message: String) -> CheckResult {
        CheckResult(checkID: id, checkTypeID: Self.typeID, status: .skipped, severity: effectiveSeverity, message: message)
    }
}
