import SwiftUI
import TaxiwayCore

struct CheckDetailView: View {
    @Binding var entry: CheckEntry
    let readOnly: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TaxiwayTheme.sectionSpacing) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(CheckMetadata.displayName(for: entry.typeID))
                        .font(TaxiwayTheme.monoLarge)
                    Text(CheckMetadata.description(for: entry.typeID))
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(.secondary)
                    Text(entry.typeID)
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                // MARK: - Enabled & Severity
                VStack(spacing: 12) {
                    HStack {
                        Text("Enabled")
                            .font(TaxiwayTheme.monoSmall)
                        Spacer()
                        Toggle("", isOn: $entry.enabled)
                            .labelsHidden()
                            .disabled(readOnly)
                    }

                    HStack {
                        Text("Severity")
                            .font(TaxiwayTheme.monoSmall)
                        Spacer()
                        Picker("", selection: $entry.severityOverride) {
                            Text("Default").tag(CheckSeverity?.none)
                            ForEach(CheckSeverity.allCases, id: \.self) { severity in
                                Label(severityLabel(severity), systemImage: severityIcon(severity))
                                    .tag(CheckSeverity?.some(severity))
                            }
                        }
                        .labelsHidden()
                        .frame(width: 120)
                        .disabled(readOnly)
                    }
                }

                Divider()

                // MARK: - Parameters
                VStack(alignment: .leading, spacing: 12) {
                    Text("Parameters")
                        .font(TaxiwayTheme.monoFont)
                    ParameterEditorView(entry: $entry, readOnly: readOnly)
                }
            }
            .padding(TaxiwayTheme.panelPadding)
        }
    }

    // MARK: - Helpers

    private func severityLabel(_ severity: CheckSeverity) -> String {
        switch severity {
        case .error: "Error"
        case .warning: "Warning"
        case .info: "Info"
        }
    }

    private func severityIcon(_ severity: CheckSeverity) -> String {
        switch severity {
        case .error: "xmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        }
    }
}
