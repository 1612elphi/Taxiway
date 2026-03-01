import SwiftUI
import TaxiwayCore

struct FixToolConfigView: View {
    let descriptor: FixDescriptor
    let onAdd: (String?) -> Void

    @Environment(\.dismiss) private var dismiss

    // Add/Change Bleed
    @State private var bleedMM: Double = 3.0
    @State private var bleedPageWidthPt: Double = 595.0
    @State private var bleedPageHeightPt: Double = 842.0

    // Change Page Size
    @State private var pageSizePreset: PageSizePreset = .a4
    @State private var customWidthMM: Double = 210.0
    @State private var customHeightMM: Double = 297.0

    // Set PDF Version
    @State private var pdfVersion: String = "1.4"


    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(descriptor.name)
                .font(TaxiwayTheme.monoFont)
                .fontWeight(.bold)

            Text(descriptor.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            configForm

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Add to Queue") {
                    onAdd(buildParametersJSON())
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear { loadDefaults() }
    }

    @ViewBuilder
    private var configForm: some View {
        switch descriptor.id {
        case "fix.add_bleed":
            addBleedForm
        case "fix.change_page_size":
            changePageSizeForm
        case "fix.set_pdf_version":
            setPDFVersionForm
        default:
            Text("No parameters")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Add/Change Bleed

    @ViewBuilder
    private var addBleedForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            LabeledContent("Bleed (mm)") {
                TextField("mm", value: $bleedMM, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            LabeledContent("Page width (pt)") {
                TextField("pt", value: $bleedPageWidthPt, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            LabeledContent("Page height (pt)") {
                TextField("pt", value: $bleedPageHeightPt, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            Text("Page dimensions are read from the first page of the document. Adjust if needed.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Change Page Size

    enum PageSizePreset: String, CaseIterable {
        case a4 = "A4 (210 × 297)"
        case a3 = "A3 (297 × 420)"
        case letter = "Letter (216 × 279)"
        case legal = "Legal (216 × 356)"
        case custom = "Custom"

        var sizeMM: (Double, Double)? {
            switch self {
            case .a4: (210.0, 297.0)
            case .a3: (297.0, 420.0)
            case .letter: (215.9, 279.4)
            case .legal: (215.9, 355.6)
            case .custom: nil
            }
        }
    }

    @ViewBuilder
    private var changePageSizeForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Preset", selection: $pageSizePreset) {
                ForEach(PageSizePreset.allCases, id: \.self) { Text($0.rawValue) }
            }
            .onChange(of: pageSizePreset) { _, newValue in
                if let size = newValue.sizeMM {
                    customWidthMM = size.0
                    customHeightMM = size.1
                }
            }

            if pageSizePreset == .custom {
                LabeledContent("Width (mm)") {
                    TextField("mm", value: $customWidthMM, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                LabeledContent("Height (mm)") {
                    TextField("mm", value: $customHeightMM, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }
        }
    }

    // MARK: - Set PDF Version

    private static let pdfVersions = ["1.3", "1.4", "1.5", "1.6", "1.7", "2.0"]

    @ViewBuilder
    private var setPDFVersionForm: some View {
        Picker("PDF Version", selection: $pdfVersion) {
            ForEach(Self.pdfVersions, id: \.self) { version in
                Text("PDF \(version)").tag(version)
            }
        }
    }

    // MARK: - Helpers

    private func loadDefaults() {
        guard let json = descriptor.defaultParametersJSON,
              let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        switch descriptor.id {
        case "fix.add_bleed":
            bleedMM = dict["bleedMM"] as? Double ?? bleedMM
            bleedPageWidthPt = dict["pageWidthPt"] as? Double ?? bleedPageWidthPt
            bleedPageHeightPt = dict["pageHeightPt"] as? Double ?? bleedPageHeightPt
        case "fix.change_page_size":
            customWidthMM = dict["widthMM"] as? Double ?? customWidthMM
            customHeightMM = dict["heightMM"] as? Double ?? customHeightMM
        case "fix.set_pdf_version":
            pdfVersion = dict["version"] as? String ?? pdfVersion
        default:
            break
        }
    }

    private func buildParametersJSON() -> String? {
        var dict: [String: Any]

        switch descriptor.id {
        case "fix.add_bleed":
            dict = ["bleedMM": bleedMM, "pageWidthPt": bleedPageWidthPt, "pageHeightPt": bleedPageHeightPt]
        case "fix.change_page_size":
            dict = ["widthMM": customWidthMM, "heightMM": customHeightMM]
        case "fix.set_pdf_version":
            dict = ["version": pdfVersion]
        default:
            return nil
        }

        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return json
    }
}
