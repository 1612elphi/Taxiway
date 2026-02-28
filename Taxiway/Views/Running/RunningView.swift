import SwiftUI
import TaxiwayCore

struct RunningView: View {
    let url: URL
    let profile: PreflightProfile
    @Environment(AppCoordinator.self) var coordinator
    @State private var statusText = "Parsing PDF..."
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        VStack(spacing: TaxiwayTheme.sectionSpacing) {
            Spacer()

            ProgressView()
                .controlSize(.large)

            Text(statusText)
                .font(TaxiwayTheme.monoFont)
                .foregroundStyle(.secondary)

            Button("Cancel") {
                coordinator.backToDashboard()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            do {
                let parser = PDFDocumentParser()
                let document = try parser.parse(url: url)
                statusText = "Running checks..."
                let engine = PreflightEngine()
                let report = try engine.run(profile: profile, on: document, documentURL: url)
                coordinator.showReport(report)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                coordinator.backToDashboard()
            }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }
}
