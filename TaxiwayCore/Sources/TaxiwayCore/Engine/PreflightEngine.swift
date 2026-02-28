import Foundation

/// Reports progress as checks are executed.
public struct CheckProgress: Sendable {
    public let completedChecks: Int
    public let totalChecks: Int
    public let lastResult: CheckResult?

    public init(completedChecks: Int, totalChecks: Int, lastResult: CheckResult?) {
        self.completedChecks = completedChecks
        self.totalChecks = totalChecks
        self.lastResult = lastResult
    }
}

/// Runs a preflight profile against a document, producing a report.
public struct PreflightEngine: Sendable {
    private let registry: CheckRegistry

    public init(registry: CheckRegistry = .default) {
        self.registry = registry
    }

    /// Runs all enabled checks in the profile against the document synchronously.
    public func run(profile: PreflightProfile, on document: TaxiwayDocument, documentURL: URL? = nil) throws -> PreflightReport {
        let start = Date()
        let enabledEntries = profile.checks.filter(\.enabled)
        var results: [CheckResult] = []

        for entry in enabledEntries {
            let check = try registry.instantiate(from: entry)
            results.append(check.run(on: document))
        }

        let duration = Date().timeIntervalSince(start)
        let hasError = results.contains { $0.status == .fail && $0.severity == .error }

        return PreflightReport(
            profileID: profile.id,
            profileName: profile.name,
            documentURL: documentURL,
            documentSnapshot: document,
            results: results,
            overallStatus: hasError ? .fail : .pass,
            runAt: start,
            duration: duration
        )
    }

    /// Runs all enabled checks with an async progress callback.
    public func run(
        profile: PreflightProfile,
        on document: TaxiwayDocument,
        documentURL: URL? = nil,
        progress: @Sendable (CheckProgress) -> Void
    ) async throws -> PreflightReport {
        let start = Date()
        let enabledEntries = profile.checks.filter(\.enabled)
        let totalChecks = enabledEntries.count
        var results: [CheckResult] = []

        for (index, entry) in enabledEntries.enumerated() {
            let check = try registry.instantiate(from: entry)
            let result = check.run(on: document)
            results.append(result)
            progress(CheckProgress(completedChecks: index + 1, totalChecks: totalChecks, lastResult: result))
        }

        let duration = Date().timeIntervalSince(start)
        let hasError = results.contains { $0.status == .fail && $0.severity == .error }

        return PreflightReport(
            profileID: profile.id,
            profileName: profile.name,
            documentURL: documentURL,
            documentSnapshot: document,
            results: results,
            overallStatus: hasError ? .fail : .pass,
            runAt: start,
            duration: duration
        )
    }
}
