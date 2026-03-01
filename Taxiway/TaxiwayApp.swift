import SwiftUI
import TaxiwayCore

@main
struct TaxiwayApp: App {
    @NSApplicationDelegateAdaptor(TaxiwayAppDelegate.self) var appDelegate
    @State private var coordinator = AppCoordinator()
    @State private var sessionStore = SessionStore()

    var body: some Scene {
        Window("Taxiway", id: "dashboard") {
            DashboardView()
                .environment(coordinator)
                .environment(sessionStore)
                .environment(appDelegate)
                .frame(minWidth: 800, minHeight: 600)
        }
        .defaultSize(width: 1100, height: 750)

        WindowGroup("Preflight", for: UUID.self) { $sessionID in
            if let id = sessionID, let session = sessionStore.sessions[id] {
                PreflightWindowView(session: session)
                    .environment(coordinator)
                    .environment(sessionStore)
                    .frame(minWidth: 800, minHeight: 600)
            }
        }
        .defaultSize(width: 1100, height: 750)

        Settings {
            SettingsView()
                .environment(coordinator)
        }
    }
}
