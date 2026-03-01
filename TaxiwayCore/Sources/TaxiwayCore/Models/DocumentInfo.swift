import Foundation

public struct DocumentInfo: Codable, Sendable, Equatable {
    public let pdfVersion: String
    public let producer: String?
    public let creator: String?
    public let isLinearized: Bool
    public let isTagged: Bool
    public let hasLayers: Bool
    public let transparencyDetected: Bool

    public init(pdfVersion: String, producer: String?, creator: String?, isLinearized: Bool, isTagged: Bool, hasLayers: Bool,
                transparencyDetected: Bool = false) {
        self.pdfVersion = pdfVersion
        self.producer = producer
        self.creator = creator
        self.isLinearized = isLinearized
        self.isTagged = isTagged
        self.hasLayers = hasLayers
        self.transparencyDetected = transparencyDetected
    }
}
