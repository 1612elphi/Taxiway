import Foundation

public struct ParseWarning: Codable, Sendable, Equatable {
    public let domain: String
    public let message: String
    public let pageIndex: Int?

    public init(domain: String, message: String, pageIndex: Int? = nil) {
        self.domain = domain
        self.message = message
        self.pageIndex = pageIndex
    }
}
