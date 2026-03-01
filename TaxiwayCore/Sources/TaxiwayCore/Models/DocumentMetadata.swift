import Foundation

public struct OutputIntent: Codable, Sendable, Equatable {
    public let subtype: String
    public let outputCondition: String?
    public let outputConditionIdentifier: String?
    public let registryName: String?

    public init(subtype: String, outputCondition: String?, outputConditionIdentifier: String?, registryName: String?) {
        self.subtype = subtype
        self.outputCondition = outputCondition
        self.outputConditionIdentifier = outputConditionIdentifier
        self.registryName = registryName
    }
}

public struct DocumentMetadata: Codable, Sendable, Equatable {
    public let title: String?
    public let author: String?
    public let subject: String?
    public let keywords: String?
    public let creationDate: Date?
    public let modificationDate: Date?
    public let trapped: String?
    public let outputIntents: [OutputIntent]
    public let xmpRaw: String?
    public let hasC2PA: Bool
    public let hasGenAIMetadata: Bool

    public init(title: String?, author: String?, subject: String?, keywords: String?,
                creationDate: Date?, modificationDate: Date?, trapped: String?,
                outputIntents: [OutputIntent], xmpRaw: String?, hasC2PA: Bool, hasGenAIMetadata: Bool) {
        self.title = title
        self.author = author
        self.subject = subject
        self.keywords = keywords
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.trapped = trapped
        self.outputIntents = outputIntents
        self.xmpRaw = xmpRaw
        self.hasC2PA = hasC2PA
        self.hasGenAIMetadata = hasGenAIMetadata
    }
}
