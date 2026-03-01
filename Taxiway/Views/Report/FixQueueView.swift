import SwiftUI
import TaxiwayCore

struct FixQueueView: View {
    let session: PreflightSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("FIX QUEUE")
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
                emptyState
            } else {
                queuedFixesList
            }
        }
        .padding()
        .frame(width: 320)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "wrench")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No fixes queued")
                .font(TaxiwayTheme.monoFont)
                .foregroundStyle(.secondary)
            Text("Click the wrench icon on failed checks to add fixes to the queue.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Queue List

    @ViewBuilder
    private var queuedFixesList: some View {
        VStack(alignment: .leading, spacing: 8) {
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

        Divider()

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
