import Foundation

/// Errors that can occur during profile storage operations.
public enum ProfileStorageError: Error, Equatable {
    case profileNotFound(UUID)
    case cannotSaveBuiltIn
    case cannotDeleteBuiltIn
    case corruptProfile(String)
}

/// Handles CRUD for user preflight profiles stored as JSON files.
///
/// Profiles are stored in `~/Library/Application Support/Taxiway/Profiles/`
/// (or a custom directory for testing). Each profile is a JSON file named `{uuid}.json`.
public final class ProfileStorage: Sendable {
    private let storageURL: URL

    public init(storageURL: URL? = nil) {
        if let url = storageURL {
            self.storageURL = url
        } else {
            self.storageURL = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("Taxiway")
                .appendingPathComponent("Profiles")
        }
    }

    // MARK: - Directory Management

    /// Ensure the storage directory exists, creating it if needed.
    private func ensureDirectory() throws {
        try FileManager.default.createDirectory(
            at: storageURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    // MARK: - CRUD

    /// Save a user profile. Built-in profiles cannot be saved.
    public func save(_ profile: PreflightProfile) throws {
        guard profile.origin != .builtIn else {
            throw ProfileStorageError.cannotSaveBuiltIn
        }
        try ensureDirectory()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(profile)
        let fileURL = storageURL.appendingPathComponent("\(profile.id.uuidString).json")
        try data.write(to: fileURL, options: .atomic)
    }

    /// Load a profile by its UUID.
    public func load(id: UUID) throws -> PreflightProfile {
        let fileURL = storageURL.appendingPathComponent("\(id.uuidString).json")
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw ProfileStorageError.profileNotFound(id)
        }
        do {
            return try JSONDecoder().decode(PreflightProfile.self, from: data)
        } catch {
            throw ProfileStorageError.corruptProfile(id.uuidString)
        }
    }

    /// List all user profiles (excluding built-ins) from the storage directory.
    public func listUserProfiles() throws -> [PreflightProfile] {
        try ensureDirectory()
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: storageURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        var profiles: [PreflightProfile] = []
        for url in contents where url.pathExtension == "json" {
            let data = try Data(contentsOf: url)
            let profile = try JSONDecoder().decode(PreflightProfile.self, from: data)
            profiles.append(profile)
        }
        return profiles.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// List all profiles: built-in profiles first, then user profiles.
    public func listAllProfiles() throws -> [PreflightProfile] {
        let userProfiles = try listUserProfiles()
        return PreflightProfile.allBuiltIn + userProfiles
    }

    /// Delete a user profile by its UUID. Built-in profiles cannot be deleted.
    public func delete(id: UUID) throws {
        // Prevent deletion of built-in profiles
        if PreflightProfile.allBuiltIn.contains(where: { $0.id == id }) {
            throw ProfileStorageError.cannotDeleteBuiltIn
        }
        let fileURL = storageURL.appendingPathComponent("\(id.uuidString).json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw ProfileStorageError.profileNotFound(id)
        }
        try FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Import / Export

    /// Import a profile from a `.taxiprofile` file. The imported profile always becomes a user profile.
    public func importProfile(from url: URL) throws -> PreflightProfile {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ProfileStorageError.corruptProfile(url.lastPathComponent)
        }
        var profile: PreflightProfile
        do {
            profile = try JSONDecoder().decode(PreflightProfile.self, from: data)
        } catch {
            throw ProfileStorageError.corruptProfile(url.lastPathComponent)
        }
        // Force imported profiles to be user profiles
        profile = PreflightProfile(
            id: profile.id,
            name: profile.name,
            description: profile.description,
            origin: .user,
            checks: profile.checks
        )
        try save(profile)
        return profile
    }

    /// Export a profile to a `.taxiprofile` file.
    public func exportProfile(_ profile: PreflightProfile, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(profile)
        try data.write(to: url, options: .atomic)
    }
}
