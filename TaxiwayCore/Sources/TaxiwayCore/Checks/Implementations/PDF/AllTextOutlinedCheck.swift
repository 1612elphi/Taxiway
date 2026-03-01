import Foundation

public struct AllTextOutlinedCheck: ParameterisedCheck {
    public static let typeID = "pdf.all_text_outlined"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "All Text Outlined" }
    public var category: CheckCategory { .pdf }
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
        let hasLiveText = !document.textFrames.isEmpty

        switch parameters.operator {
        case .is:
            // Check that text IS outlined (no live text)
            if hasLiveText {
                return fail(
                    message: "\(document.textFrames.count) live text frame(s) found — text is not fully outlined",
                    affectedItems: [.document]
                )
            }
            return pass(message: "All text is outlined (no live text operators found)")

        case .isNot:
            // Check that text is NOT outlined (live text exists)
            if !hasLiveText {
                return fail(
                    message: "No live text found — all text appears to be outlined",
                    affectedItems: [.document]
                )
            }
            return pass(message: "Live text is present (\(document.textFrames.count) text frame(s))")
        }
    }
}
