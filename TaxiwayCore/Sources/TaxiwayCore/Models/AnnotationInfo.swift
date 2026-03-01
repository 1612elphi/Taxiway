import Foundation

public struct AnnotationBounds: Codable, Sendable, Equatable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public enum AnnotationType: String, Codable, Sendable, Equatable {
    case link = "Link"
    case widget = "Widget"
    case text = "Text"
    case freeText = "FreeText"
    case highlight = "Highlight"
    case underline = "Underline"
    case strikeOut = "StrikeOut"
    case stamp = "Stamp"
    case ink = "Ink"
    case popup = "Popup"
    case fileAttachment = "FileAttachment"
    case other = "Other"
}

public struct AnnotationInfo: Codable, Sendable, Equatable {
    public let type: AnnotationType
    public let pageIndex: Int
    public let subtype: String?
    public let bounds: AnnotationBounds?

    public init(type: AnnotationType, pageIndex: Int, subtype: String? = nil, bounds: AnnotationBounds? = nil) {
        self.type = type
        self.pageIndex = pageIndex
        self.subtype = subtype
        self.bounds = bounds
    }
}
