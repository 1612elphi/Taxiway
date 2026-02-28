import Foundation

public struct AnnotationsPresentCheck: ParameterisedCheck {
    public static let typeID = "pdf.annotations"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Annotations Present" }
    public var category: CheckCategory { .pdf }
    public var defaultSeverity: CheckSeverity { .warning }

    public typealias Parameters = EmptyParameters

    public init(id: UUID = UUID(), parameters: Parameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        if document.annotations.isEmpty {
            return pass(message: "No annotations found")
        }
        let typeGroups = Dictionary(grouping: document.annotations, by: \.type)
        let summary = typeGroups.map { "\($0.value.count) \($0.key.rawValue)" }
            .sorted()
            .joined(separator: ", ")
        let affectedItems = document.annotations.map {
            AffectedItem.annotation(type: $0.type.rawValue, page: $0.pageIndex)
        }
        return fail(
            message: "Document contains \(document.annotations.count) annotation(s)",
            detail: summary,
            affectedItems: affectedItems
        )
    }
}
