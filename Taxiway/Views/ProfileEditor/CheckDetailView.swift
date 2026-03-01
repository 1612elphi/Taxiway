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

                // MARK: - State
                VStack(alignment: .leading, spacing: 8) {
                    Text("State")
                        .font(TaxiwayTheme.monoSmall)
                    HStack(spacing: 8) {
                        stateButton(target: .ignore, label: "IGNORE", color: .green)
                        stateButton(target: .warn, label: "WARN", color: TaxiwayTheme.statusWarning)
                        stateButton(target: .fault, label: "FAULT", color: TaxiwayTheme.statusError)
                    }
                }

                Divider()

                // MARK: - Parameters
                VStack(alignment: .leading, spacing: 12) {
                    Text("Parameters")
                        .font(TaxiwayTheme.monoFont)
                    ParameterEditorView(entry: $entry, readOnly: readOnly || !entry.enabled)
                }
                .opacity(entry.enabled ? 1 : 0.4)

                Divider()

                // MARK: - Assertion
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rule")
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(.secondary)
                    Text(CheckMetadata.assertionText(for: entry.typeID, entry: entry))
                        .font(TaxiwayTheme.monoFont)
                        .foregroundStyle(assertionColor)
                }
                .padding(.vertical, 4)
            }
            .padding(TaxiwayTheme.panelPadding)
        }
    }

    // MARK: - State Helpers

    enum CheckState {
        case ignore, warn, fault
    }

    static func checkState(of entry: CheckEntry) -> CheckState {
        if !entry.enabled { return .ignore }
        switch entry.severityOverride {
        case .error: return .fault
        case .warning, .info, nil: return .warn
        }
    }

    private var currentState: CheckState {
        Self.checkState(of: entry)
    }

    private var assertionColor: Color {
        switch currentState {
        case .ignore: .secondary
        case .warn: TaxiwayTheme.statusWarning
        case .fault: TaxiwayTheme.statusError
        }
    }

    @ViewBuilder
    private func stateButton(target: CheckState, label: String, color: Color) -> some View {
        let isActive = currentState == target
        Button {
            switch target {
            case .ignore:
                entry.enabled = false
            case .warn:
                entry.enabled = true
                entry.severityOverride = .warning
            case .fault:
                entry.enabled = true
                entry.severityOverride = .error
            }
        } label: {
            Text(label)
                .font(.system(.body, design: .monospaced, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .foregroundStyle(isActive ? .white : color)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? color : color.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(color, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(readOnly)
    }
}
