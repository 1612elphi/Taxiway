import Testing
import Foundation
@testable import TaxiwayCore

@Suite("PreflightProfile")
struct PreflightProfileTests {

    // MARK: - Codable

    @Test("Profile round-trips through JSON encoding and decoding")
    func codableRoundTrip() throws {
        let profile = PreflightProfile.pdfX1a
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(PreflightProfile.self, from: data)

        #expect(decoded.id == profile.id)
        #expect(decoded.name == profile.name)
        #expect(decoded.description == profile.description)
        #expect(decoded.origin == profile.origin)
        #expect(decoded.checks.count == profile.checks.count)
        #expect(decoded == profile)
    }

    @Test("Custom user profile round-trips through JSON")
    func customProfileCodableRoundTrip() throws {
        let entry = try CheckEntry(typeID: "file.size.max",
                                    enabled: true,
                                    parameters: FileSizeMaxCheck.Parameters(maxSizeMB: 50),
                                    severityOverride: .warning)
        let profile = PreflightProfile(name: "Custom", description: "My custom profile", checks: [entry])
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(PreflightProfile.self, from: data)

        #expect(decoded.name == "Custom")
        #expect(decoded.origin == .user)
        #expect(decoded.checks.count == 1)
        #expect(decoded.checks[0].typeID == "file.size.max")
    }

    // MARK: - Built-in Profiles

    @Test("Built-in profiles have origin .builtIn")
    func builtInProfilesAreBuiltIn() {
        #expect(PreflightProfile.pdfX1a.origin == .builtIn)
        #expect(PreflightProfile.pdfX4.origin == .builtIn)
        #expect(PreflightProfile.screenDigital.origin == .builtIn)
        #expect(PreflightProfile.loose.origin == .builtIn)
    }

    @Test("allBuiltIn contains exactly 4 profiles")
    func allBuiltInCount() {
        #expect(PreflightProfile.allBuiltIn.count == 4)
    }

    @Test("PDF/X-1a has fonts.not_embedded check enabled")
    func pdfX1aHasFontsNotEmbedded() {
        let hasCheck = PreflightProfile.pdfX1a.checks.contains { $0.typeID == "fonts.not_embedded" && $0.enabled }
        #expect(hasCheck)
    }

    @Test("PDF/X-1a has marks.trim_box_set check enabled")
    func pdfX1aHasTrimBoxSet() {
        let hasCheck = PreflightProfile.pdfX1a.checks.contains { $0.typeID == "marks.trim_box_set" && $0.enabled }
        #expect(hasCheck)
    }

    @Test("PDF/X-1a has marks.bleed_zero check enabled")
    func pdfX1aHasBleedZero() {
        let hasCheck = PreflightProfile.pdfX1a.checks.contains { $0.typeID == "marks.bleed_zero" && $0.enabled }
        #expect(hasCheck)
    }

    @Test("PDF/X-1a has colour.space_used check for DeviceRGB")
    func pdfX1aHasRGBCheck() {
        let hasCheck = PreflightProfile.pdfX1a.checks.contains { $0.typeID == "colour.space_used" && $0.enabled }
        #expect(hasCheck)
    }

    @Test("PDF/X-4 has fonts.not_embedded and encryption checks")
    func pdfX4HasExpectedChecks() {
        let checks = PreflightProfile.pdfX4.checks
        #expect(checks.contains { $0.typeID == "fonts.not_embedded" && $0.enabled })
        #expect(checks.contains { $0.typeID == "file.encryption" && $0.enabled })
    }

    @Test("Screen/Digital has file size max check")
    func screenDigitalHasFileSizeMax() {
        let hasCheck = PreflightProfile.screenDigital.checks.contains { $0.typeID == "file.size.max" && $0.enabled }
        #expect(hasCheck)
    }

    @Test("Loose has page count check")
    func looseHasPageCount() {
        let hasCheck = PreflightProfile.loose.checks.contains { $0.typeID == "pages.count" && $0.enabled }
        #expect(hasCheck)
    }

    @Test("Built-in profile entries can be instantiated from default registry")
    func builtInEntriesInstantiable() throws {
        let registry = CheckRegistry.default
        for profile in PreflightProfile.allBuiltIn {
            for entry in profile.checks {
                let check = try registry.instantiate(from: entry)
                #expect(type(of: check).typeID == entry.typeID)
            }
        }
    }

    // MARK: - Duplicate

    @Test("Duplicate creates a non-built-in copy with a new ID")
    func duplicateCreatesUserCopy() {
        let original = PreflightProfile.pdfX1a
        let copy = original.duplicate(name: "My X-1a Copy")

        #expect(copy.id != original.id)
        #expect(copy.name == "My X-1a Copy")
        #expect(copy.description == original.description)
        #expect(copy.origin == .user)
        #expect(copy.checks.count == original.checks.count)
    }

    @Test("Duplicate preserves all check entries")
    func duplicatePreservesChecks() {
        let original = PreflightProfile.pdfX1a
        let copy = original.duplicate(name: "Copy")

        for (orig, dup) in zip(original.checks, copy.checks) {
            #expect(orig.typeID == dup.typeID)
            #expect(orig.enabled == dup.enabled)
            #expect(orig.severityOverride == dup.severityOverride)
            #expect(orig.parametersJSON == dup.parametersJSON)
        }
    }

    // MARK: - Built-in profile IDs are deterministic

    @Test("Built-in profiles have stable UUIDs")
    func builtInProfilesHaveStableIDs() {
        #expect(PreflightProfile.pdfX1a.id == UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        #expect(PreflightProfile.pdfX4.id == UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)
        #expect(PreflightProfile.screenDigital.id == UUID(uuidString: "00000000-0000-0000-0000-000000000003")!)
        #expect(PreflightProfile.loose.id == UUID(uuidString: "00000000-0000-0000-0000-000000000004")!)
    }
}
