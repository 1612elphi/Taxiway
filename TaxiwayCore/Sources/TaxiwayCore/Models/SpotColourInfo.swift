import Foundation

public struct SpotColourInfo: Codable, Sendable, Equatable {
    public let name: String
    public let pagesUsedOn: [Int]

    public init(name: String, pagesUsedOn: [Int]) {
        self.name = name
        self.pagesUsedOn = pagesUsedOn
    }
}
