import SwiftUI
import TaxiwayCore

struct CategoryTilesView: View {
    let results: [CheckResult]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(CheckCategory.allCases, id: \.self) { category in
                let categoryResults = results.filter { categoryFor($0.checkTypeID) == category.rawValue }
                VStack(spacing: 4) {
                    Circle()
                        .fill(worstStatusColor(for: categoryResults))
                        .frame(width: 12, height: 12)
                    Text(category.rawValue.capitalized)
                        .font(TaxiwayTheme.monoSmall)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(TaxiwayTheme.tilePadding)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.horizontal, TaxiwayTheme.panelPadding)
    }

    private func categoryFor(_ typeID: String) -> String {
        if let dotIndex = typeID.firstIndex(of: ".") {
            return String(typeID[typeID.startIndex..<dotIndex])
        }
        return typeID
    }

    private func worstStatusColor(for results: [CheckResult]) -> Color {
        guard !results.isEmpty else { return TaxiwayTheme.statusSkipped }

        let nonSkipped = results.filter { $0.status != .skipped }
        guard !nonSkipped.isEmpty else { return TaxiwayTheme.statusSkipped }

        if nonSkipped.contains(where: { $0.status == .fail && $0.severity == .error }) {
            return TaxiwayTheme.statusError
        }
        if nonSkipped.contains(where: { $0.status == .fail && $0.severity == .warning })
            || nonSkipped.contains(where: { $0.status == .warning }) {
            return TaxiwayTheme.statusWarning
        }
        return TaxiwayTheme.statusPass
    }
}
