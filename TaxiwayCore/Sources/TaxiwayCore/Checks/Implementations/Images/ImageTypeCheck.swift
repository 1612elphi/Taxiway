import Foundation

public struct ImageTypeCheck: ParameterisedCheck {
    public static let typeID = "images.type"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Image Compression Type" }
    public var category: CheckCategory { .images }
    public var defaultSeverity: CheckSeverity { .warning }

    public struct Parameters: CheckParameters {
        public var compressionType: ImageCompressionType
        public var `operator`: ComparisonOperator

        public init(compressionType: ImageCompressionType, operator: ComparisonOperator) {
            self.compressionType = compressionType
            self.operator = `operator`
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let images = document.images
        if images.isEmpty {
            return pass(message: "No images in document")
        }

        let op = parameters.operator
        let target = parameters.compressionType

        let affected: [ImageInfo]
        switch op {
        case .is:
            affected = images.filter { $0.compressionType == target }
        case .isNot:
            affected = images.filter { $0.compressionType != target }
        }

        if affected.isEmpty {
            switch op {
            case .is:
                return pass(message: "No images use \(target.rawValue) compression")
            case .isNot:
                return pass(message: "All images use \(target.rawValue) compression")
            }
        }

        let affectedItems = affected.map { AffectedItem.image(id: $0.id, page: $0.pageIndex) }
        let verb: String
        switch op {
        case .is:
            verb = "use"
        case .isNot:
            verb = "do not use"
        }
        return fail(
            message: "\(affected.count) image(s) \(verb) \(target.rawValue) compression",
            detail: "Affected: \(affected.map(\.id).joined(separator: ", "))",
            affectedItems: affectedItems
        )
    }
}
