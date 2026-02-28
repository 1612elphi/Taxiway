import SwiftUI
import TaxiwayCore

@main
struct TaxiwayApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(coordinator)
                .frame(minWidth: 800, minHeight: 600)
        }
        .defaultSize(width: 1100, height: 750)

        Settings {
            SettingsView()
                .environment(coordinator)
        }
    }
}
