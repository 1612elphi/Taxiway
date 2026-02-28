import SwiftUI
import TaxiwayCore

struct ResultsListView: View {
    let results: [CheckResult]
    @Binding var selectedResult: CheckResult?

    var body: some View {
        List(sortedResults, selection: Binding(
            get: { selectedResult?.id },
            set: { newID in selectedResult = results.first { $0.id == newID } }
        )) { result in
            HStack(spacing: 8) {
                Circle()
                    .fill(colorForStatus(result.status))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(CheckMetadata.displayName(for: result.checkTypeID))
                        .font(TaxiwayTheme.monoSmall)
                        .lineLimit(1)
                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .tag(result.id)
        }
    }

    private var sortedResults: [CheckResult] {
        results.sorted { lhs, rhs in
            let lhsOrder = sortOrder(lhs)
            let rhsOrder = sortOrder(rhs)
            if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
            return lhs.checkTypeID < rhs.checkTypeID
        }
    }

    private func sortOrder(_ result: CheckResult) -> Int {
        switch result.status {
        case .fail:
            return result.severity == .error ? 0 : 1
        case .warning:
            return 2
        case .pass:
            return 3
        case .skipped:
            return 4
        }
    }

    private func colorForStatus(_ status: CheckStatus) -> Color {
        switch status {
        case .pass: TaxiwayTheme.statusPass
        case .fail: TaxiwayTheme.statusError
        case .warning: TaxiwayTheme.statusWarning
        case .skipped: TaxiwayTheme.statusSkipped
        }
    }
}
