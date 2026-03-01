import SwiftUI
import TaxiwayCore

struct FixPanelView: View {
    let session: PreflightSession

    @State private var configuringTool: FixDescriptor?

    private let fixRegistry = FixRegistry.default

    var body: some View {
        VStack(alignment: .leading, spacing: TaxiwayTheme.sectionSpacing) {
            queuedFixesSection
            Divider()
            availableToolsSection
        }
    }

    // MARK: - Queued Fixes

    @ViewBuilder
    private var queuedFixesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("QUEUED FIXES")
                    .font(TaxiwayTheme.monoSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Spacer()

                if !session.fixQueue.isEmpty {
                    Text("\(session.fixQueue.count)")
                        .font(TaxiwayTheme.monoSmall)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(.orange)
                }
            }

            if session.fixQueue.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "wrench")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No fixes queued")
                        .font(TaxiwayTheme.monoFont)
                        .foregroundStyle(.secondary)
                    Text("Add fixes from failed checks or from the tools below.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                ForEach(session.fixQueue.items) { item in
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.descriptor.name)
                                .font(TaxiwayTheme.monoSmall)
                                .fontWeight(.medium)
                            Text(item.descriptor.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            Text(item.descriptor.category == .ghostscript ? "Ghostscript" : "PDFKit")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        Button {
                            session.fixQueue.removeFix(id: item.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                }

                // GS unavailability warning
                if session.fixQueue.requiresGhostscript {
                    let engine = FixEngine()
                    if !engine.ghostscriptAvailable {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text("Ghostscript not bundled. Run scripts/build-ghostscript.sh and rebuild.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    }
                }

                Button {
                    Task { await session.applyFixes() }
                } label: {
                    Label("Apply Fixes", systemImage: "hammer.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(session.isFixing)
            }
        }
    }

    // MARK: - Available Tools

    @ViewBuilder
    private var availableToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TOOLS")
                .font(TaxiwayTheme.monoSmall)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            ForEach(fixRegistry.proactiveDescriptors) { descriptor in
                let queued = session.fixQueue.isQueued(descriptor.id)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: iconName(for: descriptor.id))
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(descriptor.name)
                            .font(TaxiwayTheme.monoSmall)
                            .fontWeight(.medium)
                        Text(descriptor.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    if queued {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else if needsConfiguration(descriptor) {
                        Button("Configure") {
                            configuringTool = descriptor
                        }
                        .controlSize(.small)
                        .buttonStyle(.bordered)
                    } else {
                        Button("Add") {
                            session.fixQueue.addProactiveFix(descriptor,
                                                            parametersJSON: descriptor.defaultParametersJSON)
                        }
                        .controlSize(.small)
                        .buttonStyle(.bordered)
                    }
                }
                .padding(8)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .popover(item: $configuringTool) { descriptor in
            FixToolConfigView(descriptor: descriptor) { parametersJSON in
                session.fixQueue.addProactiveFix(descriptor, parametersJSON: parametersJSON)
            }
        }
    }

    private func needsConfiguration(_ descriptor: FixDescriptor) -> Bool {
        descriptor.id != "fix.add_trim_marks"
    }

    private func iconName(for fixID: String) -> String {
        switch fixID {
        case "fix.add_bleed": "arrow.up.left.and.arrow.down.right"
        case "fix.change_page_size": "rectangle.and.arrow.up.right.and.arrow.down.left"
        case "fix.set_pdf_version": "doc.badge.gearshape"
        case "fix.add_trim_marks": "crop"
        default: "wrench"
        }
    }
}
