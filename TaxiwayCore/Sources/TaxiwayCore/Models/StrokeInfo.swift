import Foundation

public struct StrokeInfo: Codable, Sendable, Equatable {
    public let pageIndex: Int
    public let lineWidth: Double

    public init(pageIndex: Int, lineWidth: Double) {
        self.pageIndex = pageIndex
        self.lineWidth = lineWidth
    }
}
