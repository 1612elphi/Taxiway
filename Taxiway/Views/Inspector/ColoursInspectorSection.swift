import SwiftUI
import TaxiwayCore

struct ColoursInspectorSection: View {
    let colourUsages: [ColourUsageInfo]
    var onHighlight: (([AffectedItem]) -> Void)?

    @State private var expandedID: String?

    var body: some View {
        DisclosureGroup("Colours (\(colourUsages.count))") {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(colourUsages) { colour in
                    colourEntry(colour)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Entry

    @ViewBuilder
    private func colourEntry(_ colour: ColourUsageInfo) -> some View {
        let isExpanded = expandedID == colour.id

        VStack(alignment: .leading, spacing: 0) {
            // Summary row — always visible, tap to expand
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedID = isExpanded ? nil : colour.id
                }
            } label: {
                summaryRow(colour, isExpanded: isExpanded)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ColourRowButtonStyle(isExpanded: isExpanded))

            // Detail panel — shown when expanded
            if isExpanded {
                detailPanel(colour)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Summary Row

    @ViewBuilder
    private func summaryRow(_ colour: ColourUsageInfo, isExpanded: Bool) -> some View {
        HStack(spacing: 8) {
            colourSwatch(colour, size: 18)

            Text(colour.name)
                .font(TaxiwayTheme.monoSmall)
                .fontWeight(.semibold)
                .lineLimit(1)

            Spacer()

            usageIcons(colour.usageContexts)

            typeCapsule(colour.colourType)
        }
    }

    // MARK: - Detail Panel

    @ViewBuilder
    private func detailPanel(_ colour: ColourUsageInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Large swatch + name
            HStack(spacing: 10) {
                colourSwatch(colour, size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(colour.name)
                        .font(TaxiwayTheme.monoSmall)
                        .fontWeight(.semibold)

                    Text(modeAndComponentString(colour))
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Used in
            VStack(alignment: .leading, spacing: 4) {
                Text("Used in")
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    if colour.usageContexts.contains(.textFill) {
                        usageLabel(icon: "textformat", label: "Text")
                    }
                    if colour.usageContexts.contains(.pathFill) {
                        usageLabel(icon: "square.fill", label: "Fill")
                    }
                    if colour.usageContexts.contains(.pathStroke) {
                        usageLabel(icon: "square", label: "Stroke")
                    }
                }
            }

            Divider()

            // Properties grid
            VStack(alignment: .leading, spacing: 4) {
                detailRow("Colour Type", colour.colourType == .spot ? "Spot" : "Process")
                detailRow("Colour Mode", colour.mode.rawValue.uppercased())

                if let inkSum = colour.inkSum {
                    HStack {
                        Text("Ink Sum")
                            .font(TaxiwayTheme.monoSmall)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%d%%", Int(round(inkSum))))
                            .font(TaxiwayTheme.monoSmall)
                            .foregroundStyle(inkSum > 300 ? .orange : .primary)
                    }
                }

                detailRow("Hex", hexString(colour))
            }

            Divider()

            // Channel breakdown
            channelBreakdown(colour)

            Divider()

            // Pages
            HStack {
                Text("Pages")
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(colour.pagesUsedOn.map { String($0 + 1) }.joined(separator: ", "))
                    .font(TaxiwayTheme.monoSmall)
            }

            // Highlight pages button
            if onHighlight != nil {
                Button {
                    onHighlight?([.colourSpace(name: colour.name, pages: colour.pagesUsedOn)])
                } label: {
                    Text("Highlight in Preview")
                        .font(TaxiwayTheme.monoSmall)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        )
    }

    // MARK: - Channel Breakdown

    @ViewBuilder
    private func channelBreakdown(_ colour: ColourUsageInfo) -> some View {
        let channels = channelInfo(colour)

        VStack(alignment: .leading, spacing: 4) {
            ForEach(channels, id: \.label) { channel in
                HStack(spacing: 6) {
                    Text(channel.label)
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(.secondary)
                        .frame(width: 14, alignment: .trailing)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.secondary.opacity(0.1))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(channel.barColour)
                                .frame(width: max(0, geo.size.width * channel.fraction), height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text(channel.displayValue)
                        .font(TaxiwayTheme.monoSmall)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }

    private struct ChannelData: Hashable {
        let label: String
        let fraction: Double
        let displayValue: String
        let barColour: Color
    }

    private func channelInfo(_ colour: ColourUsageInfo) -> [ChannelData] {
        let c = colour.components
        switch colour.mode {
        case .cmyk:
            guard c.count >= 4 else { return [] }
            return [
                ChannelData(label: "C", fraction: c[0], displayValue: "\(Int(round(c[0] * 100)))", barColour: .cyan),
                ChannelData(label: "M", fraction: c[1], displayValue: "\(Int(round(c[1] * 100)))", barColour: .pink),
                ChannelData(label: "Y", fraction: c[2], displayValue: "\(Int(round(c[2] * 100)))", barColour: .yellow),
                ChannelData(label: "K", fraction: c[3], displayValue: "\(Int(round(c[3] * 100)))", barColour: .primary),
            ]
        case .rgb:
            guard c.count >= 3 else { return [] }
            return [
                ChannelData(label: "R", fraction: c[0], displayValue: "\(Int(round(c[0] * 255)))", barColour: .red),
                ChannelData(label: "G", fraction: c[1], displayValue: "\(Int(round(c[1] * 255)))", barColour: .green),
                ChannelData(label: "B", fraction: c[2], displayValue: "\(Int(round(c[2] * 255)))", barColour: .blue),
            ]
        case .gray:
            guard let g = c.first else { return [] }
            return [
                ChannelData(label: "K", fraction: 1 - g, displayValue: "\(Int(round((1 - g) * 100)))", barColour: .primary),
            ]
        }
    }

    // MARK: - Swatch

    @ViewBuilder
    private func colourSwatch(_ colour: ColourUsageInfo, size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size > 20 ? 4 : 2)
            .fill(approximateRGB(colour))
            .overlay(
                RoundedRectangle(cornerRadius: size > 20 ? 4 : 2)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
            .frame(width: size, height: size)
    }

    private func approximateRGB(_ colour: ColourUsageInfo) -> Color {
        let c = colour.components
        switch colour.mode {
        case .gray:
            let g = c.first ?? 0
            return Color(red: g, green: g, blue: g)
        case .rgb:
            guard c.count >= 3 else { return .gray }
            return Color(red: c[0], green: c[1], blue: c[2])
        case .cmyk:
            guard c.count >= 4 else { return .gray }
            let r = (1 - c[0]) * (1 - c[3])
            let g = (1 - c[1]) * (1 - c[3])
            let b = (1 - c[2]) * (1 - c[3])
            return Color(red: r, green: g, blue: b)
        }
    }

    private func rgbComponents(_ colour: ColourUsageInfo) -> (r: Double, g: Double, b: Double) {
        let c = colour.components
        switch colour.mode {
        case .gray:
            let g = c.first ?? 0
            return (g, g, g)
        case .rgb:
            guard c.count >= 3 else { return (0.5, 0.5, 0.5) }
            return (c[0], c[1], c[2])
        case .cmyk:
            guard c.count >= 4 else { return (0.5, 0.5, 0.5) }
            return ((1 - c[0]) * (1 - c[3]),
                    (1 - c[1]) * (1 - c[3]),
                    (1 - c[2]) * (1 - c[3]))
        }
    }

    // MARK: - Type Capsule

    @ViewBuilder
    private func typeCapsule(_ type: ColourType) -> some View {
        Text(type == .spot ? "Spot" : "Process")
            .font(.system(.caption2, design: .monospaced))
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                Capsule()
                    .fill(type == .spot
                          ? Color.orange.opacity(0.15)
                          : Color.secondary.opacity(0.1))
            )
            .foregroundStyle(type == .spot ? .orange : .secondary)
    }

    // MARK: - Usage Icons & Labels

    @ViewBuilder
    private func usageIcons(_ contexts: ColourUsageContext) -> some View {
        HStack(spacing: 4) {
            if contexts.contains(.textFill) {
                Image(systemName: "textformat")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            if contexts.contains(.pathFill) {
                Image(systemName: "square.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            if contexts.contains(.pathStroke) {
                Image(systemName: "square")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func usageLabel(icon: String, label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 40)
    }

    // MARK: - Helpers

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(TaxiwayTheme.monoSmall)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(TaxiwayTheme.monoSmall)
        }
    }

    private func modeAndComponentString(_ colour: ColourUsageInfo) -> String {
        let c = colour.components
        switch colour.mode {
        case .cmyk:
            guard c.count >= 4 else { return "CMYK" }
            return String(format: "CMYK [%d %d %d %d]",
                          Int(round(c[0] * 100)), Int(round(c[1] * 100)),
                          Int(round(c[2] * 100)), Int(round(c[3] * 100)))
        case .rgb:
            guard c.count >= 3 else { return "RGB" }
            return String(format: "RGB [%d %d %d]",
                          Int(round(c[0] * 255)), Int(round(c[1] * 255)),
                          Int(round(c[2] * 255)))
        case .gray:
            guard let g = c.first else { return "Gray" }
            return String(format: "Gray [%d]", Int(round(g * 100)))
        }
    }

    private func hexString(_ colour: ColourUsageInfo) -> String {
        let (r, g, b) = rgbComponents(colour)
        return String(format: "#%02X%02X%02X",
                      Int(round(r * 255)),
                      Int(round(g * 255)),
                      Int(round(b * 255)))
    }
}

// MARK: - Button Style

private struct ColourRowButtonStyle: ButtonStyle {
    let isExpanded: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isPressed
                          ? Color.accentColor.opacity(0.15)
                          : isExpanded
                          ? Color.accentColor.opacity(0.07)
                          : Color.clear)
            )
    }
}
