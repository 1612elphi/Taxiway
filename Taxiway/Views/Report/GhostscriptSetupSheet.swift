import SwiftUI
import TaxiwayCore

struct GhostscriptSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var verificationState: VerificationState = .idle
    @State private var copiedStep: Int?

    enum VerificationState {
        case idle, checking, found, notFound
    }

    private let brewInstallCommand = "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    private let gsInstallCommand = "brew install ghostscript"

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // MARK: - Header
            HStack(spacing: 12) {
                Image(systemName: "terminal")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Install Ghostscript")
                        .font(TaxiwayTheme.monoLarge)
                        .fontWeight(.bold)
                    Text("Required for PDF fixes")
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // MARK: - Step 1: Install Homebrew
            stepView(
                number: 1,
                title: "Install Homebrew",
                subtitle: "Skip if you already have Homebrew.",
                command: brewInstallCommand
            )

            // MARK: - Step 2: Install Ghostscript
            stepView(
                number: 2,
                title: "Install Ghostscript",
                subtitle: "Run this in Terminal after Homebrew is installed.",
                command: gsInstallCommand
            )

            // MARK: - Step 3: Verify Installation
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    stepBadge(number: 3)
                    Text("Verify Installation")
                        .font(TaxiwayTheme.monoFont)
                        .fontWeight(.medium)
                }

                Text("Check that Ghostscript is available on this system.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button {
                        verify()
                    } label: {
                        Label(
                            verificationState == .checking ? "Checking\u{2026}" : "Check Installation",
                            systemImage: "magnifyingglass"
                        )
                    }
                    .buttonStyle(.bordered)
                    .disabled(verificationState == .checking)

                    verificationIndicator
                }
                .padding(.top, 4)
            }

            Spacer()

            // MARK: - Footer
            Divider()

            HStack {
                Spacer()
                if verificationState == .found {
                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                } else {
                    Button("Close") { dismiss() }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(24)
        .frame(width: 520, height: 480)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func stepView(number: Int, title: String, subtitle: String, command: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                stepBadge(number: number)
                Text(title)
                    .font(TaxiwayTheme.monoFont)
                    .fontWeight(.medium)
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                Text(command)
                    .font(TaxiwayTheme.monoSmall)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(8)

                Spacer()

                Button {
                    copyToClipboard(command, step: number)
                } label: {
                    Image(systemName: copiedStep == number ? "checkmark" : "doc.on.doc")
                        .foregroundStyle(copiedStep == number ? .green : .secondary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    @ViewBuilder
    private func stepBadge(number: Int) -> some View {
        Text("\(number)")
            .font(TaxiwayTheme.monoSmall)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(.orange, in: Circle())
    }

    @ViewBuilder
    private var verificationIndicator: some View {
        switch verificationState {
        case .idle:
            EmptyView()
        case .checking:
            ProgressView()
                .controlSize(.small)
        case .found:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Ghostscript found")
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.green)
            }
        case .notFound:
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text("Not found — check the steps above")
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Actions

    private func copyToClipboard(_ text: String, step: Int) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        withAnimation { copiedStep = step }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                if copiedStep == step { copiedStep = nil }
            }
        }
    }

    private func verify() {
        verificationState = .checking
        DispatchQueue.global(qos: .userInitiated).async {
            let result = GhostscriptRunner.system()
            DispatchQueue.main.async {
                withAnimation {
                    verificationState = result != nil ? .found : .notFound
                }
            }
        }
    }
}
