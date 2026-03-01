import SwiftUI

enum TaxiwayTheme {
    // Status — aviation annunciator convention
    static let statusPass = Color.green
    static let statusWarning = Color.orange
    static let statusError = Color.red
    static let statusSkipped = Color.secondary.opacity(0.4)

    // Typography
    static let monoFont: Font = .system(.body, design: .monospaced)
    static let monoSmall: Font = .system(.caption, design: .monospaced)
    static let monoLarge: Font = .system(.title2, design: .monospaced)
    static let monoTitle: Font = .system(.title, design: .monospaced, weight: .bold)

    // Spacing
    static let panelPadding: CGFloat = 16
    static let tilePadding: CGFloat = 12
    static let sectionSpacing: CGFloat = 20
}
