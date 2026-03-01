import SwiftUI
import TaxiwayCore

struct RunningView: View {
    let session: PreflightSession
    @Environment(\.dismiss) private var dismiss
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
                dismiss()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            do {
                let parser = PDFDocumentParser()
                let document = try parser.parse(url: session.fileURL)
                statusText = "Running checks..."
                let engine = PreflightEngine()
                let report = try engine.run(profile: session.profile, on: document, documentURL: session.fileURL)
                session.showReport(report)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                dismiss()
            }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }
}
