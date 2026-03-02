import Foundation
import AppKit
import UniformTypeIdentifiers
import TaxiwayCore

@Observable
final class PreflightSession: Identifiable {
    enum Phase {
        case running
        case report(PreflightReport)
    }

    let id: UUID
    let fileURL: URL
    let profile: PreflightProfile
    var phase: Phase = .running

    let fixQueue = FixQueue()
    var isFixing = false
    var fixProgress: String?
    var fixError: String?

    init(id: UUID = UUID(), fileURL: URL, profile: PreflightProfile) {
        self.id = id
        self.fileURL = fileURL
        self.profile = profile
    }

    func showReport(_ report: PreflightReport) {
        phase = .report(report)
    }

    func applyFixes() async {
        guard !fixQueue.isEmpty else { return }

        let engine = FixEngine()
        let fixes = fixQueue.items.map { QueuedFix(descriptor: $0.descriptor, parametersJSON: $0.parametersJSON) }

        // Check GS availability if needed
        if fixQueue.requiresGhostscript && !engine.ghostscriptAvailable {
            fixError = "Ghostscript is not available. Build it with scripts/build-ghostscript.sh and rebuild the app."
            return
        }

        isFixing = true
        fixProgress = "Preparing..."
        fixError = nil

        let inputURL = fileURL
        let tempOutput = FileManager.default.temporaryDirectory
            .appendingPathComponent("taxiway-fixed-\(UUID().uuidString).pdf")

        do {
            try await Task.detached { [fixes] in
                try engine.apply(fixes: fixes, inputURL: inputURL, outputURL: tempOutput) { progress in
                    Task { @MainActor in
                        self.fixProgress = progress.stage
                    }
                }
            }.value

            // Present save panel
            let defaultName = fileURL.deletingPathExtension().lastPathComponent + "-fixed.pdf"
            let saveURL = await presentSavePanel(defaultName: defaultName)

            if let saveURL {
                try FileManager.default.moveItem(at: tempOutput, to: saveURL)
                fixQueue.clear()
            } else {
                try? FileManager.default.removeItem(at: tempOutput)
            }
        } catch let error as FixError {
            fixError = error.localizedDescription
            try? FileManager.default.removeItem(at: tempOutput)
        } catch {
            fixError = error.localizedDescription
            try? FileManager.default.removeItem(at: tempOutput)
        }

        isFixing = false
        fixProgress = nil
    }

    @MainActor
    private func presentSavePanel(defaultName: String) async -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = defaultName
        panel.canCreateDirectories = true
        let response = await panel.begin()
        return response == .OK ? panel.url : nil
    }
}
