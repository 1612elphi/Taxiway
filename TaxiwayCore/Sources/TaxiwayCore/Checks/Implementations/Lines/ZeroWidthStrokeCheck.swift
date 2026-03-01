import Foundation

public struct ZeroWidthStrokeCheck: ParameterisedCheck {
    public static let typeID = "lines.zero_width"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Zero-Width Strokes" }
    public var category: CheckCategory { .lines }
    public var defaultSeverity: CheckSeverity { .warning }

    public init(id: UUID = UUID(), parameters: EmptyParameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let zeroWidth = document.strokeInfos.filter { $0.lineWidth == 0 }

        if zeroWidth.isEmpty {
            return pass(message: "No zero-width strokes detected")
        }

        let pages = Set(zeroWidth.map(\.pageIndex)).sorted()

        return fail(
            message: "\(zeroWidth.count) zero-width stroke(s) detected",
            detail: "Found on: \(pages.map { "page \($0 + 1)" }.joined(separator: ", "))",
            affectedItems: pages.map { .page(index: $0) }
        )
    }
}
