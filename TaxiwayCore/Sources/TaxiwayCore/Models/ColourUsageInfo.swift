import Foundation

public enum ColourMode: String, Codable, Sendable, Equatable {
    case gray
    case rgb
    case cmyk
}

public enum ColourType: String, Codable, Sendable, Equatable {
    case process
    case spot
}

public struct ColourUsageContext: OptionSet, Codable, Sendable, Equatable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let textFill   = ColourUsageContext(rawValue: 1 << 0)
    public static let pathFill   = ColourUsageContext(rawValue: 1 << 1)
    public static let pathStroke = ColourUsageContext(rawValue: 1 << 2)
}

public struct ColourUsageInfo: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let colourType: ColourType
    public let mode: ColourMode
    public let components: [Double]
    public let inkSum: Double?
    public let usageContexts: ColourUsageContext
    public let pagesUsedOn: [Int]

    public init(id: String, name: String, colourType: ColourType, mode: ColourMode,
                components: [Double], inkSum: Double?, usageContexts: ColourUsageContext,
                pagesUsedOn: [Int]) {
        self.id = id
        self.name = name
        self.colourType = colourType
        self.mode = mode
        self.components = components
        self.inkSum = inkSum
        self.usageContexts = usageContexts
        self.pagesUsedOn = pagesUsedOn
    }

    /// Generates a display name from colour components and mode.
    public static func displayName(mode: ColourMode, components: [Double], spotName: String?) -> String {
        if let spotName = spotName {
            return spotName
        }

        switch mode {
        case .cmyk:
            guard components.count == 4 else { return "CMYK" }
            let c = components[0], m = components[1], y = components[2], k = components[3]
            if c == 0 && m == 0 && y == 0 && k == 1 { return "[Black]" }
            if c == 0 && m == 0 && y == 0 && k == 0 { return "[Paper]" }
            return String(format: "C=%d M=%d Y=%d K=%d",
                          Int(round(c * 100)), Int(round(m * 100)),
                          Int(round(y * 100)), Int(round(k * 100)))

        case .rgb:
            guard components.count == 3 else { return "RGB" }
            return String(format: "R=%d G=%d B=%d",
                          Int(round(components[0] * 255)),
                          Int(round(components[1] * 255)),
                          Int(round(components[2] * 255)))

        case .gray:
            guard let g = components.first else { return "Gray" }
            if g == 0 { return "[Black]" }
            if g == 1 { return "[White]" }
            return String(format: "Gray %d%%", Int(round(g * 100)))
        }
    }

    /// Generates a quantized ID for deduplication (rounds components to 2 decimal places).
    public static func quantizedID(mode: ColourMode, components: [Double], spotName: String?) -> String {
        if let spotName = spotName {
            return "spot:\(spotName)"
        }
        let quantized = components.map { Int(round($0 * 100)) }
        return "\(mode.rawValue):\(quantized.map(String.init).joined(separator: ","))"
    }
}
