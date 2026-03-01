import Testing
import Foundation
@testable import TaxiwayCore

@Suite("ProfileStorage")
struct ProfileStorageTests {
    /// Creates a temporary directory and returns a storage instance pointed at it.
    private func makeTempStorage() throws -> (ProfileStorage, URL) {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TaxiwayTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let storage = ProfileStorage(storageURL: tmpDir)
        return (storage, tmpDir)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// A minimal user profile for testing.
    private func sampleProfile(name: String = "Test Profile") -> PreflightProfile {
        PreflightProfile(
            name: name,
            description: "A test profile",
            origin: .user,
            checks: [
                CheckEntry(typeID: "file.sizeMax", enabled: true, parametersJSON: Data("{}".utf8)),
                CheckEntry(typeID: "pdf.version", enabled: false, parametersJSON: Data("{}".utf8)),
            ]
        )
    }

    // MARK: - Save & Load Round-Trip

    @Test("Save and load a profile round-trip")
    func saveAndLoadRoundTrip() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        let original = sampleProfile()
        try storage.save(original)

        let loaded = try storage.load(id: original.id)
        #expect(loaded == original)
        #expect(loaded.name == "Test Profile")
        #expect(loaded.checks.count == 2)
    }

    // MARK: - List User Profiles

    @Test("List user profiles returns saved profiles")
    func listUserProfiles() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        let profileA = sampleProfile(name: "Alpha")
        let profileB = sampleProfile(name: "Beta")
        try storage.save(profileA)
        try storage.save(profileB)

        let profiles = try storage.listUserProfiles()
        #expect(profiles.count == 2)
        // Sorted alphabetically
        #expect(profiles[0].name == "Alpha")
        #expect(profiles[1].name == "Beta")
    }

    @Test("List user profiles returns empty when no profiles exist")
    func listUserProfilesEmpty() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        let profiles = try storage.listUserProfiles()
        #expect(profiles.isEmpty)
    }

    // MARK: - List All Profiles

    @Test("List all profiles includes built-ins and user profiles")
    func listAllProfiles() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        let userProfile = sampleProfile(name: "User Custom")
        try storage.save(userProfile)

        let all = try storage.listAllProfiles()
        // 10 built-ins + 1 user
        #expect(all.count == 11)
        #expect(all[0].name == "PDF/X-1a")
        #expect(all[1].name == "PDF/X-4")
        #expect(all[2].name == "PDF/X-3")
        #expect(all[3].name == "PDF/A-2b")
        #expect(all[4].name == "Screen / Digital")
        #expect(all[5].name == "Digital Print")
        #expect(all[6].name == "Newspaper")
        #expect(all[7].name == "Large Format")
        #expect(all[8].name == "Loose")
        #expect(all[9].name == "AI Content Audit")
        #expect(all[10].name == "User Custom")
    }

    // MARK: - Delete

    @Test("Delete removes a profile")
    func deleteProfile() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        let profile = sampleProfile()
        try storage.save(profile)
        #expect(try storage.listUserProfiles().count == 1)

        try storage.delete(id: profile.id)
        #expect(try storage.listUserProfiles().isEmpty)
    }

    @Test("Delete non-existent ID throws profileNotFound")
    func deleteNonExistent() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        let bogusID = UUID()
        #expect(throws: ProfileStorageError.profileNotFound(bogusID)) {
            try storage.delete(id: bogusID)
        }
    }

    @Test("Delete built-in profile throws cannotDeleteBuiltIn")
    func deleteBuiltIn() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        #expect(throws: ProfileStorageError.cannotDeleteBuiltIn) {
            try storage.delete(id: PreflightProfile.pdfX1a.id)
        }
    }

    // MARK: - Load Errors

    @Test("Load non-existent ID throws profileNotFound")
    func loadNonExistent() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        let bogusID = UUID()
        #expect(throws: ProfileStorageError.profileNotFound(bogusID)) {
            try storage.load(id: bogusID)
        }
    }

    @Test("Load corrupt JSON throws corruptProfile")
    func loadCorruptJSON() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        let fakeID = UUID()
        let filePath = tmpDir.appendingPathComponent("\(fakeID.uuidString).json")
        try Data("not valid json {{{{".utf8).write(to: filePath)

        #expect(throws: ProfileStorageError.corruptProfile(fakeID.uuidString)) {
            try storage.load(id: fakeID)
        }
    }

    // MARK: - Save Errors

    @Test("Save built-in profile throws cannotSaveBuiltIn")
    func saveBuiltIn() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        #expect(throws: ProfileStorageError.cannotSaveBuiltIn) {
            try storage.save(PreflightProfile.pdfX1a)
        }
    }

    // MARK: - Import / Export

    @Test("Import and export .taxiprofile round-trip")
    func importExportRoundTrip() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        let original = sampleProfile(name: "Exportable")

        // Export to a .taxiprofile file
        let exportURL = tmpDir.appendingPathComponent("export.taxiprofile")
        try storage.exportProfile(original, to: exportURL)

        // Verify the file exists
        #expect(FileManager.default.fileExists(atPath: exportURL.path))

        // Create a second storage to import into
        let importDir = tmpDir.appendingPathComponent("import")
        let importStorage = ProfileStorage(storageURL: importDir)

        let imported = try importStorage.importProfile(from: exportURL)
        #expect(imported.id == original.id)
        #expect(imported.name == "Exportable")
        #expect(imported.origin == .user)
        #expect(imported.checks.count == original.checks.count)

        // Verify it was persisted
        let loaded = try importStorage.load(id: imported.id)
        #expect(loaded == imported)
    }

    @Test("Import corrupt file throws corruptProfile")
    func importCorruptFile() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        let badFile = tmpDir.appendingPathComponent("corrupt.taxiprofile")
        try Data("not json".utf8).write(to: badFile)

        #expect {
            try storage.importProfile(from: badFile)
        } throws: { error in
            guard let storageError = error as? ProfileStorageError else { return false }
            if case .corruptProfile = storageError { return true }
            return false
        }
    }

    @Test("Import converts built-in origin to user")
    func importConvertsOriginToUser() throws {
        let (_, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        // Create a profile with built-in origin
        let builtInProfile = PreflightProfile(
            name: "Fake Built-in",
            description: "Should become user on import",
            origin: .builtIn,
            checks: []
        )

        // Export it manually (bypassing the save restriction)
        let exportURL = tmpDir.appendingPathComponent("builtin-export.taxiprofile")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(builtInProfile)
        try data.write(to: exportURL)

        // Import into a fresh storage
        let importDir = tmpDir.appendingPathComponent("import2")
        let importStorage = ProfileStorage(storageURL: importDir)
        let imported = try importStorage.importProfile(from: exportURL)

        #expect(imported.origin == .user)
    }

    // MARK: - Overwrite

    @Test("Saving a profile with the same ID overwrites it")
    func overwriteExistingProfile() throws {
        let (storage, tmpDir) = try makeTempStorage()
        defer { cleanup(tmpDir) }

        var profile = sampleProfile(name: "Original")
        try storage.save(profile)

        profile = PreflightProfile(
            id: profile.id,
            name: "Updated",
            description: profile.description,
            origin: .user,
            checks: profile.checks
        )
        try storage.save(profile)

        let loaded = try storage.load(id: profile.id)
        #expect(loaded.name == "Updated")
        #expect(try storage.listUserProfiles().count == 1)
    }
}
