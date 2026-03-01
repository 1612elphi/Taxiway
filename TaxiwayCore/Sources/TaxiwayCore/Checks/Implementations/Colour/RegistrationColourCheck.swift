import Foundation

public struct RegistrationColourCheck: ParameterisedCheck {
    public static let typeID = "colour.registration"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Registration Colour" }
    public var category: CheckCategory { .colour }
    public var defaultSeverity: CheckSeverity { .warning }

    public typealias Parameters = EmptyParameters

    public init(id: UUID = UUID(), parameters: Parameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let registrationSpots = document.spotColours.filter { $0.name == "All" }
        if registrationSpots.isEmpty {
            return pass(message: "No registration colour found")
        }
        let pages = registrationSpots.flatMap { $0.pagesUsedOn }
        let uniquePages = Set(pages).sorted()
        return fail(
            message: "Registration colour detected",
            detail: "Found on page(s): \(uniquePages.map { String($0 + 1) }.joined(separator: ", "))",
            affectedItems: [.document]
        )
    }
}
