import Foundation

public enum FixCategory: String, Codable, Sendable, Equatable {
    case ghostscript
    case pdfkit
}

public struct FixDescriptor: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let addressesCheckTypeIDs: Set<String>
    public let category: FixCategory
    public let isProactive: Bool
    public let defaultParametersJSON: String?

    public init(id: String, name: String, description: String,
                addressesCheckTypeIDs: Set<String>, category: FixCategory,
                isProactive: Bool = false, defaultParametersJSON: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.addressesCheckTypeIDs = addressesCheckTypeIDs
        self.category = category
        self.isProactive = isProactive
        self.defaultParametersJSON = defaultParametersJSON
    }
}
