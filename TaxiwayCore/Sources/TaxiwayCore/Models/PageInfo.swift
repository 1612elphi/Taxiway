import Foundation
import CoreGraphics

public struct PageInfo: Sendable, Equatable {
    public let index: Int
    public let mediaBox: CGRect
    public let trimBox: CGRect?
    public let bleedBox: CGRect?
    public let artBox: CGRect?
    public let rotation: Int

    public var effectiveTrimBox: CGRect {
        trimBox ?? mediaBox
    }

    public var bleedMargins: (left: Double, right: Double, top: Double, bottom: Double) {
        guard let bleed = bleedBox else {
            return (0, 0, 0, 0)
        }
        let trim = effectiveTrimBox
        return (
            left: trim.minX - bleed.minX,
            right: bleed.maxX - trim.maxX,
            top: bleed.maxY - trim.maxY,
            bottom: trim.minY - bleed.minY
        )
    }

    public init(index: Int, mediaBox: CGRect, trimBox: CGRect?, bleedBox: CGRect?, artBox: CGRect?, rotation: Int) {
        self.index = index
        self.mediaBox = mediaBox
        self.trimBox = trimBox
        self.bleedBox = bleedBox
        self.artBox = artBox
        self.rotation = rotation
    }
}

// MARK: - Codable

extension PageInfo: Codable {
    private enum CodingKeys: String, CodingKey {
        case index, rotation
        case mediaBoxX, mediaBoxY, mediaBoxWidth, mediaBoxHeight
        case trimBoxX, trimBoxY, trimBoxWidth, trimBoxHeight
        case bleedBoxX, bleedBoxY, bleedBoxWidth, bleedBoxHeight
        case artBoxX, artBoxY, artBoxWidth, artBoxHeight
        case hasTrimBox, hasBleedBox, hasArtBox
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(rotation, forKey: .rotation)

        try container.encode(mediaBox.origin.x, forKey: .mediaBoxX)
        try container.encode(mediaBox.origin.y, forKey: .mediaBoxY)
        try container.encode(mediaBox.size.width, forKey: .mediaBoxWidth)
        try container.encode(mediaBox.size.height, forKey: .mediaBoxHeight)

        try container.encode(trimBox != nil, forKey: .hasTrimBox)
        if let trimBox {
            try container.encode(trimBox.origin.x, forKey: .trimBoxX)
            try container.encode(trimBox.origin.y, forKey: .trimBoxY)
            try container.encode(trimBox.size.width, forKey: .trimBoxWidth)
            try container.encode(trimBox.size.height, forKey: .trimBoxHeight)
        }

        try container.encode(bleedBox != nil, forKey: .hasBleedBox)
        if let bleedBox {
            try container.encode(bleedBox.origin.x, forKey: .bleedBoxX)
            try container.encode(bleedBox.origin.y, forKey: .bleedBoxY)
            try container.encode(bleedBox.size.width, forKey: .bleedBoxWidth)
            try container.encode(bleedBox.size.height, forKey: .bleedBoxHeight)
        }

        try container.encode(artBox != nil, forKey: .hasArtBox)
        if let artBox {
            try container.encode(artBox.origin.x, forKey: .artBoxX)
            try container.encode(artBox.origin.y, forKey: .artBoxY)
            try container.encode(artBox.size.width, forKey: .artBoxWidth)
            try container.encode(artBox.size.height, forKey: .artBoxHeight)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        rotation = try container.decode(Int.self, forKey: .rotation)

        mediaBox = CGRect(
            x: try container.decode(CGFloat.self, forKey: .mediaBoxX),
            y: try container.decode(CGFloat.self, forKey: .mediaBoxY),
            width: try container.decode(CGFloat.self, forKey: .mediaBoxWidth),
            height: try container.decode(CGFloat.self, forKey: .mediaBoxHeight)
        )

        let hasTrimBox = try container.decode(Bool.self, forKey: .hasTrimBox)
        if hasTrimBox {
            trimBox = CGRect(
                x: try container.decode(CGFloat.self, forKey: .trimBoxX),
                y: try container.decode(CGFloat.self, forKey: .trimBoxY),
                width: try container.decode(CGFloat.self, forKey: .trimBoxWidth),
                height: try container.decode(CGFloat.self, forKey: .trimBoxHeight)
            )
        } else {
            trimBox = nil
        }

        let hasBleedBox = try container.decode(Bool.self, forKey: .hasBleedBox)
        if hasBleedBox {
            bleedBox = CGRect(
                x: try container.decode(CGFloat.self, forKey: .bleedBoxX),
                y: try container.decode(CGFloat.self, forKey: .bleedBoxY),
                width: try container.decode(CGFloat.self, forKey: .bleedBoxWidth),
                height: try container.decode(CGFloat.self, forKey: .bleedBoxHeight)
            )
        } else {
            bleedBox = nil
        }

        let hasArtBox = try container.decode(Bool.self, forKey: .hasArtBox)
        if hasArtBox {
            artBox = CGRect(
                x: try container.decode(CGFloat.self, forKey: .artBoxX),
                y: try container.decode(CGFloat.self, forKey: .artBoxY),
                width: try container.decode(CGFloat.self, forKey: .artBoxWidth),
                height: try container.decode(CGFloat.self, forKey: .artBoxHeight)
            )
        } else {
            artBox = nil
        }
    }
}
