import Foundation

/// The overall outcome of a preflight run.
public enum PreflightOutcome: String, Codable, Sendable, Equatable {
    case pass
    case fail
}

/// The result of running a preflight profile against a document.
public struct PreflightReport: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let profileID: UUID
    public let profileName: String
    public let documentURL: URL?
    public let documentSnapshot: TaxiwayDocument
    public let results: [CheckResult]
    public let overallStatus: PreflightOutcome
    public let runAt: Date
    public let duration: TimeInterval

    public init(
        id: UUID = UUID(),
        profileID: UUID,
        profileName: String,
        documentURL: URL? = nil,
        documentSnapshot: TaxiwayDocument,
        results: [CheckResult],
        overallStatus: PreflightOutcome,
        runAt: Date = Date(),
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.profileID = profileID
        self.profileName = profileName
        self.documentURL = documentURL
        self.documentSnapshot = documentSnapshot
        self.results = results
        self.overallStatus = overallStatus
        self.runAt = runAt
        self.duration = duration
    }
}
