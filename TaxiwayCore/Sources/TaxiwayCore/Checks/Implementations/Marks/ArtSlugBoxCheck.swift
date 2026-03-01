import Foundation

public struct ArtSlugBoxCheck: ParameterisedCheck {
    public static let typeID = "marks.art_slug_box"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Art/Slug Box" }
    public var category: CheckCategory { .marks }
    public var defaultSeverity: CheckSeverity { .info }

    public struct Parameters: CheckParameters {
        public var `operator`: ComparisonOperator
        public init(operator: ComparisonOperator) {
            self.operator = `operator`
        }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let pagesWithArtBox = document.pages.filter { $0.artBox != nil }

        switch parameters.operator {
        case .is:
            // Fail if any page HAS an art box set
            if pagesWithArtBox.isEmpty {
                return pass(message: "No art box set on any page")
            }
            let pageNumbers = pagesWithArtBox.map { String($0.index + 1) }.joined(separator: ", ")
            return fail(
                message: "Art box set on \(pagesWithArtBox.count) page(s)",
                detail: "Page(s): \(pageNumbers)",
                affectedItems: pagesWithArtBox.map { .page(index: $0.index) }
            )

        case .isNot:
            // Fail if any page does NOT have an art box
            let pagesWithoutArtBox = document.pages.filter { $0.artBox == nil }
            if pagesWithoutArtBox.isEmpty {
                return pass(message: "All pages have art box set")
            }
            let pageNumbers = pagesWithoutArtBox.map { String($0.index + 1) }.joined(separator: ", ")
            return fail(
                message: "\(pagesWithoutArtBox.count) page(s) missing art box",
                detail: "Page(s): \(pageNumbers)",
                affectedItems: pagesWithoutArtBox.map { .page(index: $0.index) }
            )
        }
    }
}
