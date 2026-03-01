import SwiftUI
import TaxiwayCore

struct CategoryTilesView: View {
    let results: [CheckResult]

    var body: some View {
        VStack(spacing: 2) {
            ForEach(CheckCategory.allCases, id: \.self) { category in
                let categoryResults = results.filter { categoryFor($0.checkTypeID) == category.rawValue }
                FlightStripRow(category: category, results: categoryResults)
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
}

// MARK: - Flight Strip Row

private struct FlightStripRow: View {
    let category: CheckCategory
    let results: [CheckResult]

    private var nonSkipped: [CheckResult] {
        results.filter { $0.status != .skipped }
    }

    private var passedCount: Int {
        nonSkipped.filter { $0.status == .pass }.count
    }

    private var totalCount: Int {
        nonSkipped.count
    }

    private var isEmpty: Bool {
        nonSkipped.isEmpty
    }

    private var statusColor: Color {
        guard !isEmpty else { return TaxiwayTheme.statusSkipped }
        if nonSkipped.contains(where: { $0.status == .fail && $0.severity == .error }) {
            return TaxiwayTheme.statusError
        }
        if nonSkipped.contains(where: { $0.status == .fail && $0.severity == .warning })
            || nonSkipped.contains(where: { $0.status == .warning }) {
            return TaxiwayTheme.statusWarning
        }
        return TaxiwayTheme.statusPass
    }

    private var statusWord: String {
        guard !isEmpty else { return "\u{2014}" }
        if nonSkipped.contains(where: { $0.status == .fail && $0.severity == .error }) {
            return "FAIL"
        }
        if nonSkipped.contains(where: { $0.status == .fail && $0.severity == .warning })
            || nonSkipped.contains(where: { $0.status == .warning }) {
            return "WARN"
        }
        return "PASS"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left edge strip
            RoundedRectangle(cornerRadius: 1)
                .fill(statusColor)
                .frame(width: 3, height: 20)
                .padding(.trailing, 8)

            // Category name
            Text(category.rawValue.uppercased())
                .font(TaxiwayTheme.monoSmall)
                .foregroundStyle(.primary)

            Spacer()

            // Count + status
            if isEmpty {
                Text("\u{2014}")
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(TaxiwayTheme.statusSkipped)
            } else {
                Text("\(passedCount)/\(totalCount)")
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 6)
                Text(statusWord)
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 4))
    }
}
