import Foundation

public struct TextFrameInfo: Codable, Sendable, Equatable {
    public let id: String
    public let pageIndex: Int
    public let fontName: String
    public let fontSize: Double
    public let bounds: AnnotationBounds

    public init(id: String, pageIndex: Int, fontName: String, fontSize: Double, bounds: AnnotationBounds) {
        self.id = id
        self.pageIndex = pageIndex
        self.fontName = fontName
        self.fontSize = fontSize
        self.bounds = bounds
    }
}
