import Foundation

public struct CheckResult: Codable, Sendable, Equatable, Identifiable {
    public let checkID: UUID
    public let checkTypeID: String
    public let status: CheckStatus
    public let severity: CheckSeverity
    public let message: String
    public let detail: String?
    public let affectedItems: [AffectedItem]

    public var id: UUID { checkID }

    public init(checkID: UUID, checkTypeID: String, status: CheckStatus, severity: CheckSeverity,
                message: String, detail: String? = nil, affectedItems: [AffectedItem] = []) {
        self.checkID = checkID
        self.checkTypeID = checkTypeID
        self.status = status
        self.severity = severity
        self.message = message
        self.detail = detail
        self.affectedItems = affectedItems
    }
}
