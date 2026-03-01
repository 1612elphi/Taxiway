import Foundation

public struct OverprintInfo: Codable, Sendable, Equatable {
    public let pageIndex: Int
    public let context: OverprintContext
    public let isWhiteOverprint: Bool

    public init(pageIndex: Int, context: OverprintContext, isWhiteOverprint: Bool) {
        self.pageIndex = pageIndex
        self.context = context
        self.isWhiteOverprint = isWhiteOverprint
    }
}

public enum OverprintContext: String, Codable, Sendable, Equatable {
    case fill, stroke, text
}
