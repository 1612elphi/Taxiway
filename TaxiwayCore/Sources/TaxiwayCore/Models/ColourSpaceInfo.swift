import Foundation

public enum ColourSpaceName: String, Codable, Sendable, Equatable {
    case deviceGray = "DeviceGray"
    case deviceRGB = "DeviceRGB"
    case deviceCMYK = "DeviceCMYK"
    case iccBased = "ICCBased"
    case calGray = "CalGray"
    case calRGB = "CalRGB"
    case lab = "Lab"
    case indexed = "Indexed"
    case separation = "Separation"
    case deviceN = "DeviceN"
    case pattern = "Pattern"
    case unknown = "Unknown"
}

public struct ColourSpaceInfo: Codable, Sendable, Equatable {
    public let name: ColourSpaceName
    public let pagesUsedOn: [Int]
    public let iccProfileName: String?

    public init(name: ColourSpaceName, pagesUsedOn: [Int], iccProfileName: String? = nil) {
        self.name = name
        self.pagesUsedOn = pagesUsedOn
        self.iccProfileName = iccProfileName
    }
}
