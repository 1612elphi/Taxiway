import SwiftUI
import TaxiwayCore

struct StatusHeaderView: View {
    let report: PreflightReport

    var body: some View {
        HStack(spacing: TaxiwayTheme.sectionSpacing) {
            Text(report.overallStatus == .pass ? "PASS" : "FAIL")
                .font(TaxiwayTheme.monoTitle)
                .foregroundStyle(report.overallStatus == .pass
                    ? TaxiwayTheme.statusPass
                    : TaxiwayTheme.statusError)

            VStack(alignment: .leading, spacing: 4) {
                Text(report.profileName)
                    .font(TaxiwayTheme.monoFont)

                if let url = report.documentURL {
                    Text(url.lastPathComponent)
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(.secondary)
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

            Spacer()
        }
        .padding(TaxiwayTheme.panelPadding)
    }
}
