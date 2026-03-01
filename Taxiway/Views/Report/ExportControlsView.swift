import SwiftUI
import UniformTypeIdentifiers
import TaxiwayCore

struct ExportControlsView: View {
    let report: PreflightReport

    @State private var exportError: String?
    @State private var showingError = false

    var body: some View {
        Menu("Export") {
            Button("Export JSON") { exportJSON() }
            Button("Export CSV") { exportCSV() }
            Button("Export PDF") { exportPDF() }
        }
        .alert("Export Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(exportError ?? "Unknown error")
        }
    }

    private var baseName: String {
        if let url = report.documentURL {
            return url.deletingPathExtension().lastPathComponent + "-preflight"
        }
        return "preflight-report"
    }

    private func exportJSON() {
        do {
            let data = try ReportExporter.exportJSON(report)
            saveData(data, fileName: "\(baseName).json", contentType: .json)
        } catch {
            exportError = error.localizedDescription
            showingError = true
        }
    }

    private func exportCSV() {
        let data = ReportExporter.exportCSV(report)
        saveData(data, fileName: "\(baseName).csv", contentType: .commaSeparatedText)
    }

    private func exportPDF() {
        do {
            let data = try ReportExporter.exportPDF(report)
            saveData(data, fileName: "\(baseName).pdf", contentType: .pdf)
        } catch {
            exportError = error.localizedDescription
            showingError = true
        }
    }

    private func saveData(_ data: Data, fileName: String, contentType: UTType) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [contentType]
        panel.nameFieldStringValue = fileName
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            exportError = error.localizedDescription
            showingError = true
        }
    }
}
