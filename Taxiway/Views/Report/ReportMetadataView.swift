import SwiftUI
import TaxiwayCore

struct ReportMetadataView: View {
    let report: PreflightReport

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(report.profileName)
                .font(TaxiwayTheme.monoFont)

            if let url = report.documentURL {
                Text(url.lastPathComponent)
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)
                    .truncationMode(.middle)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                Text(report.runAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)

                Text(String(format: "%.2fs", report.duration))
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(TaxiwayTheme.panelPadding)
    }
}
