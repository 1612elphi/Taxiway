import AppKit

@Observable
final class TaxiwayAppDelegate: NSObject, NSApplicationDelegate {
    var pendingURLs: [URL] = []

    func application(_ application: NSApplication, open urls: [URL]) {
        let pdfURLs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
        pendingURLs.append(contentsOf: pdfURLs)
    }
}
