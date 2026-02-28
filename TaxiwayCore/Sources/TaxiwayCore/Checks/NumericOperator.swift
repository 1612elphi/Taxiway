import Foundation

public enum NumericOperator: String, Codable, Sendable, Equatable {
    case equals
    case lessThan = "less_than"
    case moreThan = "more_than"
}
