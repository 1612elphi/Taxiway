import Testing
import Foundation
@testable import TaxiwayCore

@Suite("PreflightEngine")
struct PreflightEngineTests {

    let engine = PreflightEngine()

    // MARK: - Basic execution

    @Test("Engine runs all enabled checks")
    func runsAllEnabledChecks() throws {
        let profile = PreflightProfile.loose
        let document = TaxiwayDocument.sample

        let report = try engine.run(profile: profile, on: document)

        // Loose has 3 enabled checks
        let enabledCount = profile.checks.filter(\.enabled).count
        #expect(report.results.count == enabledCount)
        #expect(report.results.count == 3)
    }

    @Test("Engine skips disabled checks — all disabled yields empty results")
    func skipsDisabledChecks() throws {
        // Create a profile with all checks disabled
        var profile = PreflightProfile.loose
        profile.checks = profile.checks.map { entry in
            CheckEntry(typeID: entry.typeID, enabled: false, parametersJSON: entry.parametersJSON, severityOverride: entry.severityOverride)
        }

        let document = TaxiwayDocument.sample
        let report = try engine.run(profile: profile, on: document)

        #expect(report.results.isEmpty)
    }

    @Test("Engine with empty profile produces empty results")
    func emptyProfileProducesEmptyResults() throws {
        let profile = PreflightProfile(name: "Empty", description: "No checks", checks: [])
        let document = TaxiwayDocument.sample

        let report = try engine.run(profile: profile, on: document)

        #expect(report.results.isEmpty)
        #expect(report.overallStatus == .pass)
    }

    // MARK: - Overall status logic

    @Test("Overall status is fail when any error-severity check fails")
    func overallFailWhenErrorExists() throws {
        // The sample document has an unembedded font (TimesNewRoman) and the loose profile
        // uses page count > 0 with error severity, which will pass.
        // Use PDF/X-1a profile which checks fonts.not_embedded with error severity
        // and the sample doc has an unembedded font.
        let profile = PreflightProfile.pdfX1a
        let document = TaxiwayDocument.sample

        let report = try engine.run(profile: profile, on: document)

        #expect(report.overallStatus == .fail)
    }

    @Test("Overall status is pass when only warnings exist (no error-severity failures)")
    func overallPassWhenOnlyWarnings() throws {
        // Create a profile with a single warning-severity check that will fail.
        // File size max 1 MB with warning severity — the sample is 5 MB so it'll fail.
        let entry = try CheckEntry(
            typeID: "file.size.max",
            enabled: true,
            parameters: FileSizeMaxCheck.Parameters(maxSizeMB: 1),
            severityOverride: .warning
        )
        let profile = PreflightProfile(name: "Warn Only", description: "Only warnings", checks: [entry])
        let document = TaxiwayDocument.sample

        let report = try engine.run(profile: profile, on: document)

        // The check should fail (5 MB > 1 MB) but at warning severity
        let failResults = report.results.filter { $0.status == .fail }
        #expect(!failResults.isEmpty)
        // All failures are warning-level, not error
        let errorFailures = report.results.filter { $0.status == .fail && $0.severity == .error }
        #expect(errorFailures.isEmpty)
        // Overall should be pass because no error-severity failures
        #expect(report.overallStatus == .pass)
    }

    @Test("Overall status is pass when all checks pass")
    func overallPassWhenAllChecksPass() throws {
        // File size max 100 MB — sample is 5 MB, so it passes
        let entry = try CheckEntry(
            typeID: "file.size.max",
            enabled: true,
            parameters: FileSizeMaxCheck.Parameters(maxSizeMB: 100),
            severityOverride: .error
        )
        let profile = PreflightProfile(name: "Pass All", description: "Should pass", checks: [entry])
        let document = TaxiwayDocument.sample

        let report = try engine.run(profile: profile, on: document)

        #expect(report.results.allSatisfy { $0.status == .pass })
        #expect(report.overallStatus == .pass)
    }

    // MARK: - Report metadata

    @Test("Report includes document snapshot")
    func reportIncludesDocumentSnapshot() throws {
        let profile = PreflightProfile.loose
        let document = TaxiwayDocument.sample

        let report = try engine.run(profile: profile, on: document)

        #expect(report.documentSnapshot == document)
    }

    @Test("Report records timing (duration >= 0)")
    func reportRecordsTiming() throws {
        let profile = PreflightProfile.loose
        let document = TaxiwayDocument.sample

        let report = try engine.run(profile: profile, on: document)

        #expect(report.duration >= 0)
    }

    @Test("Report contains profile metadata")
    func reportContainsProfileMetadata() throws {
        let profile = PreflightProfile.loose
        let document = TaxiwayDocument.sample

        let report = try engine.run(profile: profile, on: document)

        #expect(report.profileID == profile.id)
        #expect(report.profileName == profile.name)
    }

    @Test("Report stores document URL when provided")
    func reportStoresDocumentURL() throws {
        let profile = PreflightProfile.loose
        let document = TaxiwayDocument.sample
        let url = URL(fileURLWithPath: "/tmp/test.pdf")

        let report = try engine.run(profile: profile, on: document, documentURL: url)

        #expect(report.documentURL == url)
    }

    @Test("Report has nil documentURL when not provided")
    func reportNilDocumentURL() throws {
        let profile = PreflightProfile.loose
        let document = TaxiwayDocument.sample

        let report = try engine.run(profile: profile, on: document)

        #expect(report.documentURL == nil)
    }

    // MARK: - Integration with sample document

    @Test("Running loose profile on sample document produces results")
    func looseProfileOnSampleDocument() throws {
        let report = try engine.run(profile: .loose, on: .sample)

        #expect(!report.results.isEmpty)
        // Page count > 0 should pass (sample has 2 pages)
        let pageCountResult = report.results.first { $0.checkTypeID == "pages.count" }
        #expect(pageCountResult != nil)
        #expect(pageCountResult?.status == .pass)
    }

    @Test("Running PDF/X-1a profile on sample document detects unembedded fonts")
    func pdfX1aDetectsUnembeddedFonts() throws {
        let report = try engine.run(profile: .pdfX1a, on: .sample)

        let fontResult = report.results.first { $0.checkTypeID == "fonts.not_embedded" }
        #expect(fontResult != nil)
        #expect(fontResult?.status == .fail)
    }

    @Test("Running PDF/X-1a profile on sample document detects RGB colour space")
    func pdfX1aDetectsRGB() throws {
        let report = try engine.run(profile: .pdfX1a, on: .sample)

        let colourResult = report.results.first { $0.checkTypeID == "colour.space_used" }
        #expect(colourResult != nil)
        #expect(colourResult?.status == .fail)
    }

    // MARK: - Async variant

    @Test("Async engine reports progress for each check")
    func asyncEngineReportsProgress() async throws {
        let profile = PreflightProfile.loose
        let document = TaxiwayDocument.sample
        let enabledCount = profile.checks.filter(\.enabled).count

        let collector = ProgressCollector()
        let report = try await engine.run(profile: profile, on: document) { p in
            collector.append(p)
        }

        let progressReports = collector.reports
        #expect(progressReports.count == enabledCount)
        #expect(report.results.count == enabledCount)

        // Last progress report should have completedChecks == totalChecks
        if let last = progressReports.last {
            #expect(last.completedChecks == last.totalChecks)
            #expect(last.lastResult != nil)
        }
    }

    @Test("Async engine produces same results as sync engine")
    func asyncMatchesSync() async throws {
        let profile = PreflightProfile.pdfX1a
        let document = TaxiwayDocument.sample

        let syncReport = try engine.run(profile: profile, on: document)
        let asyncReport = try await engine.run(profile: profile, on: document) { _ in }

        #expect(syncReport.results.count == asyncReport.results.count)
        #expect(syncReport.overallStatus == asyncReport.overallStatus)

        // Same check type IDs in same order
        let syncIDs = syncReport.results.map(\.checkTypeID)
        let asyncIDs = asyncReport.results.map(\.checkTypeID)
        #expect(syncIDs == asyncIDs)
    }

    // MARK: - Error handling

    @Test("Engine throws for unknown typeID")
    func throwsForUnknownTypeID() {
        let entry = CheckEntry(typeID: "nonexistent.check", enabled: true, parametersJSON: Data("{}".utf8))

        #expect(throws: CheckRegistryError.self) {
            _ = try engine.run(profile: .init(name: "Bad", description: "", checks: [entry]), on: .sample)
        }
    }
}

// MARK: - Helpers

/// Thread-safe collector for progress reports, usable from @Sendable closures.
private final class ProgressCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var _reports: [CheckProgress] = []

    func append(_ progress: CheckProgress) {
        lock.lock()
        defer { lock.unlock() }
        _reports.append(progress)
    }

    var reports: [CheckProgress] {
        lock.lock()
        defer { lock.unlock() }
        return _reports
    }
}
