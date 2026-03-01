import Foundation

public enum CheckSeverity: Int, Codable, Sendable, Equatable, Comparable, CaseIterable {
    case error = 0
    case warning = 1
    case info = 2

    public static func < (lhs: CheckSeverity, rhs: CheckSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum CheckStatus: String, Codable, Sendable, Equatable {
    case pass
    case fail
    case warning
    case skipped
}
