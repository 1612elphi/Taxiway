import SwiftUI
import TaxiwayCore

struct ReportView: View {
    let session: PreflightSession
    let report: PreflightReport

    @State private var selectedResult: CheckResult?
    @State private var showInspector = true
    @State private var inspectorHighlight: [AffectedItem]?
    @State private var inspectorTab: InspectorTab = .report

    enum InspectorTab: String, CaseIterable {
        case report = "Report"
        case fix = "Fix"
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                SolariStatusView(outcome: report.displayOutcome, results: report.results)
                    .padding(TaxiwayTheme.panelPadding)

                ReportMetadataView(report: report)

                Divider()

                CategoryTilesView(results: report.results)
                    .padding(.vertical, TaxiwayTheme.panelPadding)

                Divider()

                ResultsListView(
                    results: report.results,
                    session: session,
                    selectedResult: $selectedResult
                )
            }
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
        } detail: {
            PDFPreviewView(
                pdfURL: report.documentURL,
                affectedItems: activeHighlightItems,
                highlightColor: activeHighlightColor
            )
        }
        .inspector(isPresented: $showInspector) {
            VStack(spacing: 0) {
                Picker("", selection: $inspectorTab) {
                    ForEach(InspectorTab.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .padding(TaxiwayTheme.panelPadding)

                Divider()

                ScrollView {
                    switch inspectorTab {
                    case .report:
                        VStack(alignment: .leading, spacing: TaxiwayTheme.sectionSpacing) {
                            if let selected = selectedResult {
                                ResultDetailView(result: selected, session: session)
                                Divider()
                            }
                            InspectorView(document: report.documentSnapshot) { items in
                                inspectorHighlight = items
                            }
                        }
                        .padding(TaxiwayTheme.panelPadding)
                    case .fix:
                        FixPanelView(session: session)
                            .padding(TaxiwayTheme.panelPadding)
                    }
                }
            }
            .inspectorColumnWidth(min: 280, ideal: 320, max: 400)
        }
        .onChange(of: selectedResult) { _, _ in
            inspectorHighlight = nil
        }
        .overlay {
            if session.isFixing {
                fixProgressOverlay
            }
        }
        .alert("Fix Error", isPresented: Binding(
            get: { session.fixError != nil },
            set: { if !$0 { session.fixError = nil } }
        )) {
            Button("OK") { session.fixError = nil }
        } message: {
            Text(session.fixError ?? "")
        }
        .toolbar {
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
    }

    // MARK: - Highlight Resolution

    private var activeHighlightItems: [AffectedItem] {
        inspectorHighlight ?? selectedResult?.affectedItems ?? []
    }

    private var activeHighlightColor: Color {
        if inspectorHighlight != nil {
            return .blue
        }
        guard let result = selectedResult else { return .clear }
        switch result.status {
        case .fail: return TaxiwayTheme.statusError
        case .warning: return TaxiwayTheme.statusWarning
        case .pass: return TaxiwayTheme.statusPass
        case .skipped: return TaxiwayTheme.statusSkipped
        }
    }

    // MARK: - Fix Progress Overlay

    @ViewBuilder
    private var fixProgressOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text(session.fixProgress ?? "Applying fixes...")
                    .font(TaxiwayTheme.monoFont)
                    .foregroundStyle(.secondary)
            }
            .padding(40)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
