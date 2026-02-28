import SwiftUI
import TaxiwayCore

struct ReportView: View {
    let report: PreflightReport

    @Environment(AppCoordinator.self) var coordinator
    @State private var selectedResult: CheckResult?
    @State private var showInspector = false

    var body: some View {
        VStack(spacing: 0) {
            StatusHeaderView(report: report)

            Divider()

            NavigationSplitView {
                VStack(spacing: 0) {
                    CategoryTilesView(results: report.results)
                        .padding(.vertical, TaxiwayTheme.panelPadding)

                    Divider()

                    ResultsListView(
                        results: report.results,
                        selectedResult: $selectedResult
                    )
                }
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
            } detail: {
                if let selected = selectedResult {
                    ResultDetailView(result: selected)
                } else {
                    ContentUnavailableView(
                        "Select a Check",
                        systemImage: "checklist",
                        description: Text("Choose a check result from the sidebar to view details.")
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    coordinator.backToDashboard()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showInspector.toggle()
                } label: {
                    Label("Inspector", systemImage: "info.circle")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                ExportControlsView(report: report)
            }
        }
        .inspector(isPresented: $showInspector) {
            InspectorView(document: report.documentSnapshot)
                .inspectorColumnWidth(min: 280, ideal: 320, max: 400)
        }
    }
}
