import SwiftUI
import TaxiwayCore

struct ContentView: View {
    @Environment(AppCoordinator.self) var coordinator

    var body: some View {
        switch coordinator.currentScreen {
        case .dashboard:
            DashboardView()
        case .running(let url, let profile):
            RunningView(url: url, profile: profile)
        case .report(let report):
            ReportView(report: report)
        }
    }
}
