import Foundation

public struct InteractiveElementsCheck: ParameterisedCheck {
    public static let typeID = "file.interactive_elements"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Interactive Elements" }
    public var category: CheckCategory { .file }
    public var defaultSeverity: CheckSeverity { .warning }

    public typealias Parameters = EmptyParameters

    public init(id: UUID = UUID(), parameters: Parameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let widgets = document.annotations.filter { $0.type == .widget }
        if widgets.isEmpty {
            return pass(message: "No interactive elements found")
        }
        let pages = Set(widgets.map { $0.pageIndex }).sorted()
        let affectedItems = widgets.map { AffectedItem.annotation(type: "Widget", page: $0.pageIndex) }
        return fail(
            message: "Document contains \(widgets.count) interactive element(s)",
            detail: "Widget annotations found on page(s): \(pages.map { String($0 + 1) }.joined(separator: ", "))",
            affectedItems: affectedItems
        )
    }
}
