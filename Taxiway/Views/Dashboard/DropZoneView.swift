import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Binding var selectedURL: URL?
    @State private var isTargeted = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
                )

            if let url = selectedURL {
                VStack(spacing: 8) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text(url.lastPathComponent)
                        .font(TaxiwayTheme.monoFont)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("Drop PDF here or click to browse")
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 200)
        .contentShape(Rectangle())
        .onTapGesture {
            openFilePanel()
        }
        .onDrop(of: [.pdf], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            selectedURL = panel.url
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, _ in
            DispatchQueue.main.async {
                if let url = item as? URL {
                    selectedURL = url
                } else if let data = item as? Data {
                    selectedURL = URL(dataRepresentation: data, relativeTo: nil)
                }
            }
        }
        return true
    }
}
