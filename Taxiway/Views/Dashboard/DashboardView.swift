import SwiftUI
import TaxiwayCore
import UniformTypeIdentifiers

struct DashboardView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(SessionStore.self) var sessionStore
    @Environment(TaxiwayAppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    @State private var isDropTargeted = false
    @State private var cursorPosition: CGPoint?
    @State private var taglineText = ""
    @State private var taglineIndex = 0
    @Environment(\.colorScheme) private var colorScheme

    private var solariCardColor: Color {
        colorScheme == .dark ? Color(white: 0.22) : Color(white: 0.88)
    }

    private var solariTextColor: Color {
        colorScheme == .dark
            ? Color(red: 0.92, green: 0.72, blue: 0.20)
            : Color(red: 0.60, green: 0.45, blue: 0.05)
    }

    private static let taglines = [
        "Open-source preflight",
        "No subscription required",
        "Acrobat costs HOW much?",
        "PDFs deserve better",
        "Free as in beer and PDF",
        "PDF/X-3 or bust",
        "RGB in MY print file?!",
        "Sorry, Patrick!",
        "No Creative Cloud here",
        "Preflight sans price tag",
        "Embed your fonts, people",
        "Missing bleed? Found it.",
        "Have you tried CMYK?",
        "Cheaper than PitStop",
        "Not made in San Jose",
    ]

    var body: some View {
        @Bindable var coordinator = coordinator

        HStack(spacing: 0) {
            leftColumn
            Divider()
            ProfileListView()
                .frame(minWidth: 260, idealWidth: 320, maxWidth: 400)
        }
        .sheet(isPresented: $coordinator.showingProfileEditor) {
            ProfileEditorView()
        }
        .onChange(of: appDelegate.pendingURLs) { _, urls in
            for url in urls {
                openPreflight(url: url)
            }
            appDelegate.pendingURLs.removeAll()
        }
    }

    // MARK: - Left Column

    private var leftColumn: some View {
        ZStack {
            SymbolFieldView(cursorPosition: cursorPosition)

            VStack(spacing: 0) {
                Spacer()

                Text("a delphi tool")
                    .font(.system(size: 14))
                    .tracking(10)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 16)

                SolariCascadeView(
                    word: "TAXIWAY",
                    fontSize: 48,
                    cardColor: solariCardColor,
                    textColor: solariTextColor
                )
                .shadow(color: solariTextColor.opacity(0.1), radius: 24)

                Text(taglineText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.6), value: taglineText)
                    .padding(.top, 8)

                Spacer()

                // Action button
                Button {
                    openFilePanel()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.badge.plus")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 28)
                        Text("Open a File...")
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.fill.tertiary, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 48)

                // Drop zone
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isDropTargeted ? Color.accentColor.opacity(0.08) : .clear)
                        )

                    Text(isDropTargeted ? "Drop to preflight" : "or drag a PDF here")
                        .font(.caption)
                        .foregroundStyle(isDropTargeted ? .primary : .tertiary)
                }
                .frame(height: 44)
                .padding(.horizontal, 48)
                .padding(.top, 12)
                .padding(.bottom, 48)
                .onDrop(of: [.pdf], isTargeted: $isDropTargeted) { providers in
                    handleDrop(providers)
                }
            }
        }
        .frame(minWidth: 380, idealWidth: 460)
        .contentShape(Rectangle())
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                cursorPosition = location
            case .ended:
                cursorPosition = nil
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            taglineText = Self.taglines[0]

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                taglineIndex = (taglineIndex + 1) % Self.taglines.count
                taglineText = Self.taglines[taglineIndex]
            }
        }
    }

    // MARK: - File Handling

    private func openPreflight(url: URL) {
        coordinator.addRecentFile(url)
        let sessionID = sessionStore.createSession(url: url, profile: coordinator.selectedProfile)
        openWindow(value: sessionID)
    }

    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            openPreflight(url: url)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, _ in
            DispatchQueue.main.async {
                if let url = item as? URL {
                    openPreflight(url: url)
                } else if let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) {
                    openPreflight(url: url)
                }
            }
        }
        return true
    }
}
