import Foundation

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

    public init(type: AnnotationType, pageIndex: Int, subtype: String? = nil) {
        self.type = type
        self.pageIndex = pageIndex
        self.subtype = subtype
    }
}
