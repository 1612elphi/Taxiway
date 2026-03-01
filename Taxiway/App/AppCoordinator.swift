import SwiftUI
import TaxiwayCore

@Observable
final class AppCoordinator {
    var selectedProfile: PreflightProfile = .loose
    var recentFiles: [URL] = []
    var showingProfileEditor = false
    var editingProfile: PreflightProfile?

    private let maxRecentFiles = 10

    init() {
        loadRecentFiles()
    }

    func editProfile(_ profile: PreflightProfile) {
        editingProfile = profile
        showingProfileEditor = true
    }

    func createProfile() {
        let newProfile = PreflightProfile(
            name: "New Profile",
            description: "",
            origin: .user,
            checks: []
        )
        editingProfile = newProfile
        showingProfileEditor = true
    }

    // MARK: - Recent Files

    func addRecentFile(_ url: URL) {
        recentFiles.removeAll { $0 == url }
        recentFiles.insert(url, at: 0)
        if recentFiles.count > maxRecentFiles {
            recentFiles = Array(recentFiles.prefix(maxRecentFiles))
        }
        saveRecentFiles()
    }

    func clearRecentFiles() {
        recentFiles = []
        UserDefaults.standard.removeObject(forKey: "recentFiles")
    }

    private func loadRecentFiles() {
        guard let paths = UserDefaults.standard.stringArray(forKey: "recentFiles") else { return }
        recentFiles = paths.compactMap { URL(fileURLWithPath: $0) }.filter {
            FileManager.default.fileExists(atPath: $0.path)
        }
    }

    private func saveRecentFiles() {
        let paths = recentFiles.map(\.path)
        UserDefaults.standard.set(paths, forKey: "recentFiles")
    }
}
