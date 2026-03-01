import Foundation

public enum ImageColourMode: String, Codable, Sendable, Equatable {
    case deviceGray = "DeviceGray"
    case deviceRGB = "DeviceRGB"
    case deviceCMYK = "DeviceCMYK"
    case iccBased = "ICCBased"
    case indexed = "Indexed"
    case separation = "Separation"
    case deviceN = "DeviceN"
    case unknown = "Unknown"
}

public enum ImageCompressionType: String, Codable, Sendable, Equatable {
    case jpeg = "JPEG"
    case jpeg2000 = "JPEG2000"
    case jbig2 = "JBIG2"
    case ccitt = "CCITT"
    case flate = "Flate"
    case lzw = "LZW"
    case runLength = "RunLength"
    case none = "None"
    case unknown = "Unknown"
}

public enum BlendMode: String, Codable, Sendable, Equatable {
    case normal = "Normal"
    case multiply = "Multiply"
    case screen = "Screen"
    case overlay = "Overlay"
    case darken = "Darken"
    case lighten = "Lighten"
    case colorDodge = "ColorDodge"
    case colorBurn = "ColorBurn"
    case hardLight = "HardLight"
    case softLight = "SoftLight"
    case difference = "Difference"
    case exclusion = "Exclusion"
    case unknown = "Unknown"
}

public struct ImageInfo: Codable, Sendable, Equatable {
    public let id: String
    public let pageIndex: Int
    public let widthPixels: Int
    public let heightPixels: Int
    public let effectiveWidthPoints: Double
    public let effectiveHeightPoints: Double
    public let colourMode: ImageColourMode
    public let compressionType: ImageCompressionType
    public let bitsPerComponent: Int
    public let hasICCProfile: Bool
    public let hasICCOverride: Bool
    public let hasAlphaChannel: Bool
    public let blendMode: BlendMode
    public let opacity: Double
    public let bounds: AnnotationBounds?

    public var effectivePPIHorizontal: Double {
        guard effectiveWidthPoints > 0 else { return 0 }
        return Double(widthPixels) / (effectiveWidthPoints / 72.0)
    }

    public var effectivePPIVertical: Double {
        guard effectiveHeightPoints > 0 else { return 0 }
        return Double(heightPixels) / (effectiveHeightPoints / 72.0)
    }

    public var isScaledProportionally: Bool {
        guard widthPixels > 0, heightPixels > 0, effectiveWidthPoints > 0, effectiveHeightPoints > 0 else { return true }
        let originalRatio = Double(widthPixels) / Double(heightPixels)
        let effectiveRatio = effectiveWidthPoints / effectiveHeightPoints
        return abs(originalRatio - effectiveRatio) / originalRatio < 0.01
    }

    public init(id: String, pageIndex: Int, widthPixels: Int, heightPixels: Int,
                effectiveWidthPoints: Double, effectiveHeightPoints: Double,
                colourMode: ImageColourMode, compressionType: ImageCompressionType,
                bitsPerComponent: Int, hasICCProfile: Bool, hasICCOverride: Bool,
                hasAlphaChannel: Bool, blendMode: BlendMode, opacity: Double,
                bounds: AnnotationBounds? = nil) {
        self.id = id
        self.pageIndex = pageIndex
        self.widthPixels = widthPixels
        self.heightPixels = heightPixels
        self.effectiveWidthPoints = effectiveWidthPoints
        self.effectiveHeightPoints = effectiveHeightPoints
        self.colourMode = colourMode
        self.compressionType = compressionType
        self.bitsPerComponent = bitsPerComponent
        self.hasICCProfile = hasICCProfile
        self.hasICCOverride = hasICCOverride
        self.hasAlphaChannel = hasAlphaChannel
        self.blendMode = blendMode
        self.opacity = opacity
        self.bounds = bounds
    }
}
