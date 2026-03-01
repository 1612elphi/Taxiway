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

    public init(id: String, name: String, description: String,
                addressesCheckTypeIDs: Set<String>, category: FixCategory) {
        self.id = id
        self.name = name
        self.description = description
        self.addressesCheckTypeIDs = addressesCheckTypeIDs
        self.category = category
    }
}
