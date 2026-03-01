import Foundation

public enum FontType: String, Codable, Sendable, Equatable {
    case type1 = "Type1"
    case trueType = "TrueType"
    case openTypeCFF = "OpenType CFF"
    case cidFontType0 = "CIDFontType0"
    case cidFontType2 = "CIDFontType2"
    case type3 = "Type3"
    case mmType1 = "MMType1"
    case unknown = "Unknown"
}

public struct FontInfo: Codable, Sendable, Equatable {
    public let name: String
    public let type: FontType
    public let isEmbedded: Bool
    public let isSubset: Bool
    public let pagesUsedOn: [Int]

    public init(name: String, type: FontType, isEmbedded: Bool, isSubset: Bool, pagesUsedOn: [Int]) {
        self.name = name
        self.type = type
        self.isEmbedded = isEmbedded
        self.isSubset = isSubset
        self.pagesUsedOn = pagesUsedOn
    }
}
