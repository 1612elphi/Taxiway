import Foundation

public enum AffectedItem: Codable, Sendable, Equatable {
    case document
    case page(index: Int)
    case font(name: String, pages: [Int])
    case image(id: String, page: Int)
    case colourSpace(name: String, pages: [Int])
    case annotation(type: String, page: Int)
}
