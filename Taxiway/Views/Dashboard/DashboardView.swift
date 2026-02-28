import SwiftUI
import TaxiwayCore

struct DashboardView: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var selectedURL: URL?

    var body: some View {
        @Bindable var coordinator = coordinator

        VStack(spacing: TaxiwayTheme.sectionSpacing) {
            Spacer()

            // Header
            VStack(spacing: 4) {
                Text("TAXIWAY")
                    .font(TaxiwayTheme.monoTitle)
                Text("PDF Preflight")
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)
            }

            // Drop zone
            DropZoneView(selectedURL: $selectedURL)

            // Profile picker
            ProfilePickerView()

            // Action buttons
            HStack(spacing: 12) {
                Button("Run Preflight") {
                    if let url = selectedURL {
                        coordinator.startPreflight(url: url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedURL == nil)

                Button("Edit Profile") {
                    coordinator.editProfile(coordinator.selectedProfile)
                }
            }

            // Recent files
            if !coordinator.recentFiles.isEmpty {
                RecentFilesView(selectedURL: $selectedURL)
            }

            Spacer()
        }
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
        .padding()
        .sheet(isPresented: $coordinator.showingProfileEditor) {
            ProfileEditorView()
        }
    }
}
