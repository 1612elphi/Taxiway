import SwiftUI
import TaxiwayCore

struct ResultDetailView: View {
    let result: CheckResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TaxiwayTheme.sectionSpacing) {
                // Status badge and type ID
                HStack(spacing: 10) {
                    statusBadge
                    Text(result.checkTypeID)
                        .font(TaxiwayTheme.monoLarge)
                }

                // Severity
                HStack(spacing: 6) {
                    Text("Severity:")
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(.secondary)
                    Text(severityLabel)
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(severityColor)
                }

                // Message
                Text(result.message)
                    .font(TaxiwayTheme.monoFont)

                // Detail
                if let detail = result.detail {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Detail")
                            .font(TaxiwayTheme.monoSmall)
                            .foregroundStyle(.secondary)
                        Text(detail)
                            .font(TaxiwayTheme.monoFont)
                            .textSelection(.enabled)
                    }
                }

                // Affected items
                if !result.affectedItems.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Affected Items")
                            .font(TaxiwayTheme.monoSmall)
                            .foregroundStyle(.secondary)

                        ForEach(Array(result.affectedItems.enumerated()), id: \.offset) { _, item in
                            Text(descriptionFor(item))
                                .font(TaxiwayTheme.monoFont)
                        }
                    }
                }

                Spacer()
            }
            .padding(TaxiwayTheme.panelPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        Text(result.status.rawValue.uppercased())
            .font(TaxiwayTheme.monoSmall)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(.white)
            .background(statusColor, in: RoundedRectangle(cornerRadius: 4))
    }

    private var statusColor: Color {
        switch result.status {
        case .pass: TaxiwayTheme.statusPass
        case .fail: TaxiwayTheme.statusError
        case .warning: TaxiwayTheme.statusWarning
        case .skipped: TaxiwayTheme.statusSkipped
        }
    }

    private var severityLabel: String {
        switch result.severity {
        case .error: "Error"
        case .warning: "Warning"
        case .info: "Info"
        }
    }

    private var severityColor: Color {
        switch result.severity {
        case .error: TaxiwayTheme.statusError
        case .warning: TaxiwayTheme.statusWarning
        case .info: .secondary
        }
    }

    private func descriptionFor(_ item: AffectedItem) -> String {
        switch item {
        case .document:
            "Document"
        case .page(let index):
            "Page \(index + 1)"
        case .font(let name, let pages):
            "Font: \(name) (pages \(pages.map { String($0 + 1) }.joined(separator: ", ")))"
        case .image(let id, let page):
            "Image \(id) (page \(page + 1))"
        case .colourSpace(let name, let pages):
            "Colour space: \(name) (pages \(pages.map { String($0 + 1) }.joined(separator: ", ")))"
        case .annotation(let type, let page):
            "\(type) annotation (page \(page + 1))"
        }
    }
}
