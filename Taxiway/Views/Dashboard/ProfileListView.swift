import SwiftUI
import TaxiwayCore

struct ProfileListView: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var profiles: [PreflightProfile] = []

    private var selectedID: Binding<UUID?> {
        Binding(
            get: { coordinator.selectedProfile.id },
            set: { newID in
                if let newID, let profile = profiles.first(where: { $0.id == newID }) {
                    coordinator.selectedProfile = profile
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            List(profiles, selection: selectedID) { profile in
                HStack(spacing: 10) {
                    Image(systemName: profile.origin == .builtIn
                          ? "checklist.checked" : "checklist")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        Text(profile.origin == .builtIn ? "Built-in" : "Custom")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(profile.id)
                .padding(.vertical, 2)
            }
            .listStyle(.inset)

            Divider()

            // Bottom toolbar
            HStack(spacing: 0) {
                toolbarButton(icon: "plus") {
                    coordinator.createProfile()
                }

                Divider().frame(height: 14)

                toolbarButton(icon: "doc.on.doc") {
                    cloneSelectedProfile()
                }

                Divider().frame(height: 14)

                toolbarButton(icon: "pencil") {
                    coordinator.editProfile(coordinator.selectedProfile)
                }
                .disabled(coordinator.selectedProfile.origin == .builtIn)

                Divider().frame(height: 14)

                toolbarButton(icon: "minus") {
                    deleteSelectedProfile()
                }
                .disabled(coordinator.selectedProfile.origin == .builtIn)

                Spacer()
            }
            .padding(.horizontal, 4)
            .frame(height: 26)
        }
        .onAppear { loadProfiles() }
        .onChange(of: coordinator.showingProfileEditor) { _, isShowing in
            if !isShowing { loadProfiles() }
        }
    }

    // MARK: - Toolbar

    private func toolbarButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .frame(width: 28, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Profile Actions

    private func loadProfiles() {
        profiles = (try? ProfileStorage().listAllProfiles()) ?? PreflightProfile.allBuiltIn
        if !profiles.contains(where: { $0.id == coordinator.selectedProfile.id }) {
            coordinator.selectedProfile = profiles.first ?? .loose
        }
    }

    private func cloneSelectedProfile() {
        let source = coordinator.selectedProfile
        let clone = source.duplicate(name: "\(source.name) Copy")
        do {
            try ProfileStorage().save(clone)
            loadProfiles()
            coordinator.selectedProfile = clone
            coordinator.editProfile(clone)
        } catch {}
    }

    private func deleteSelectedProfile() {
        let profile = coordinator.selectedProfile
        guard profile.origin != .builtIn else { return }
        do {
            try ProfileStorage().delete(id: profile.id)
            loadProfiles()
        } catch {}
    }
}
