import SwiftUI
import TaxiwayCore

struct SettingsView: View {
    @Environment(AppCoordinator.self) var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        Form {
            Section("Default Profile") {
                Picker("Profile", selection: $coordinator.selectedProfile) {
                    ForEach(PreflightProfile.allBuiltIn) { profile in
                        Text(profile.name).tag(profile)
                    }
                }
            }

            Section("Recent Files") {
                Button("Clear Recent Files", role: .destructive) {
                    coordinator.clearRecentFiles()
                }
            }
        }
        .formStyle(.grouped)
    }
}
