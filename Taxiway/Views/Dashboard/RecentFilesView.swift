import SwiftUI

struct RecentFilesView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Binding var selectedURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Files")
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear") {
                    coordinator.clearRecentFiles()
                }
                .buttonStyle(.plain)
                .font(TaxiwayTheme.monoSmall)
                .foregroundStyle(.secondary)
            }

            ForEach(coordinator.recentFiles, id: \.self) { url in
                Button {
                    selectedURL = url
                } label: {
                    HStack {
                        Image(systemName: "doc")
                            .foregroundStyle(.secondary)
                        Text(url.lastPathComponent)
                            .font(TaxiwayTheme.monoFont)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
