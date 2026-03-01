import SwiftUI
import TaxiwayCore

struct ParameterEditorView: View {
    @Binding var entry: CheckEntry
    let readOnly: Bool

    var body: some View {
        switch entry.typeID {
        // MARK: - File
        case "file.encryption":
            boolParameterEditor(
                label: "Expected encrypted",
                decode: { (p: EncryptionCheck.Parameters) in p.expected },
                encode: { EncryptionCheck.Parameters(expected: $0) }
            )
        case "file.size.max":
            doubleParameterEditor(
                label: "Max size (MB)",
                decode: { (p: FileSizeMaxCheck.Parameters) in p.maxSizeMB },
                encode: { FileSizeMaxCheck.Parameters(maxSizeMB: $0) }
            )
        case "file.size.min":
            doubleParameterEditor(
                label: "Min size (MB)",
                decode: { (p: FileSizeMinCheck.Parameters) in p.minSizeMB },
                encode: { FileSizeMinCheck.Parameters(minSizeMB: $0) }
            )
        case "file.metadata.present":
            stringParameterEditor(
                label: "Field name",
                decode: { (p: MetadataFieldPresentCheck.Parameters) in p.fieldName },
                encode: { MetadataFieldPresentCheck.Parameters(fieldName: $0) }
            )
        case "file.metadata.matches":
            metadataMatchesEditor()

        // MARK: - PDF
        case "pdf.version":
            pdfVersionEditor()
        case "pdf.conformance":
            pdfConformanceEditor()
        case "pdf.linearized":
            boolParameterEditor(
                label: "Expected linearized",
                decode: { (p: LinearizedCheck.Parameters) in p.expected },
                encode: { LinearizedCheck.Parameters(expected: $0) }
            )
        case "pdf.tagged":
            boolParameterEditor(
                label: "Expected tagged",
                decode: { (p: TaggedCheck.Parameters) in p.expected },
                encode: { TaggedCheck.Parameters(expected: $0) }
            )
        case "pdf.transparency":
            comparisonOperatorEditor(
                decode: { (p: TransparencyCheck.Parameters) in p.operator },
                encode: { TransparencyCheck.Parameters(operator: $0) }
            )
        case "pdf.all_text_outlined":
            comparisonOperatorEditor(
                decode: { (p: AllTextOutlinedCheck.Parameters) in p.operator },
                encode: { AllTextOutlinedCheck.Parameters(operator: $0) }
            )

        // MARK: - Pages
        case "pages.count":
            pageCountEditor()
        case "pages.size":
            pageSizeEditor()

        // MARK: - Marks
        case "marks.bleed_greater_than":
            doubleParameterEditor(
                label: "Threshold (mm)",
                decode: { (p: BleedGreaterThanCheck.Parameters) in p.thresholdMM },
                encode: { BleedGreaterThanCheck.Parameters(thresholdMM: $0) }
            )
        case "marks.bleed_less_than":
            doubleParameterEditor(
                label: "Threshold (mm)",
                decode: { (p: BleedLessThanCheck.Parameters) in p.thresholdMM },
                encode: { BleedLessThanCheck.Parameters(thresholdMM: $0) }
            )
        case "marks.bleed_non_uniform":
            doubleParameterEditor(
                label: "Tolerance (mm)",
                decode: { (p: BleedNonUniformCheck.Parameters) in p.toleranceMM },
                encode: { BleedNonUniformCheck.Parameters(toleranceMM: $0) }
            )
        case "marks.art_slug_box":
            comparisonOperatorEditor(
                decode: { (p: ArtSlugBoxCheck.Parameters) in p.operator },
                encode: { ArtSlugBoxCheck.Parameters(operator: $0) }
            )

        // MARK: - Colour
        case "colour.space_used":
            colourSpaceUsedEditor()
        case "colour.spot_count":
            intParameterEditor(
                label: "Max count",
                decode: { (p: SpotColourCountCheck.Parameters) in p.maxCount },
                encode: { SpotColourCountCheck.Parameters(maxCount: $0) }
            )
        case "colour.ink_coverage":
            inkCoverageEditor()
        case "colour.overprint":
            overprintContextEditor()

        // MARK: - Fonts
        case "fonts.type":
            fontTypeEditor()
        case "fonts.size":
            fontSizeEditor()

        // MARK: - Images
        case "images.colour_mode":
            imageColourModeEditor()
        case "images.type":
            imageTypeEditor()
        case "images.scaled":
            doubleParameterEditor(
                label: "Tolerance (%)",
                decode: { (p: ImageScaledCheck.Parameters) in p.tolerancePercent },
                encode: { ImageScaledCheck.Parameters(tolerancePercent: $0) }
            )
        case "images.scaled_non_proportional":
            doubleParameterEditor(
                label: "Tolerance (%)",
                decode: { (p: ImageScaledNonProportionallyCheck.Parameters) in p.tolerancePercent },
                encode: { ImageScaledNonProportionallyCheck.Parameters(tolerancePercent: $0) }
            )
        case "images.resolution_below":
            doubleParameterEditor(
                label: "Threshold (PPI)",
                decode: { (p: ResolutionBelowCheck.Parameters) in p.thresholdPPI },
                encode: { ResolutionBelowCheck.Parameters(thresholdPPI: $0) }
            )
        case "images.resolution_above":
            doubleParameterEditor(
                label: "Threshold (PPI)",
                decode: { (p: ResolutionAboveCheck.Parameters) in p.thresholdPPI },
                encode: { ResolutionAboveCheck.Parameters(thresholdPPI: $0) }
            )
        case "images.resolution_range":
            resolutionRangeEditor()

        // MARK: - Lines
        case "lines.stroke_below":
            doubleParameterEditor(
                label: "Threshold (pt)",
                decode: { (p: StrokeWeightBelowCheck.Parameters) in p.thresholdPt },
                encode: { StrokeWeightBelowCheck.Parameters(thresholdPt: $0) }
            )

        // MARK: - EmptyParameters
        default:
            Text("No configurable parameters.")
                .font(TaxiwayTheme.monoSmall)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Generic Editors

    @ViewBuilder
    private func boolParameterEditor<P: CheckParameters>(
        label: String,
        decode: @escaping (P) -> Bool,
        encode: @escaping (Bool) -> P
    ) -> some View {
        HStack {
            Text(label)
                .font(TaxiwayTheme.monoSmall)
            Spacer()
            Toggle("", isOn: Binding(
                get: { decodeParams(P.self).map(decode) ?? false },
                set: { encodeAndStore(encode($0)) }
            ))
            .labelsHidden()
            .disabled(readOnly)
        }
    }

    @ViewBuilder
    private func doubleParameterEditor<P: CheckParameters>(
        label: String,
        decode: @escaping (P) -> Double,
        encode: @escaping (Double) -> P
    ) -> some View {
        HStack {
            Text(label)
                .font(TaxiwayTheme.monoSmall)
            Spacer()
            TextField(label, value: Binding(
                get: { decodeParams(P.self).map(decode) ?? 0 },
                set: { encodeAndStore(encode($0)) }
            ), format: .number)
            .font(TaxiwayTheme.monoSmall)
            .textFieldStyle(.roundedBorder)
            .frame(width: 100)
            .disabled(readOnly)
        }
    }

    @ViewBuilder
    private func intParameterEditor<P: CheckParameters>(
        label: String,
        decode: @escaping (P) -> Int,
        encode: @escaping (Int) -> P
    ) -> some View {
        HStack {
            Text(label)
                .font(TaxiwayTheme.monoSmall)
            Spacer()
            TextField(label, value: Binding(
                get: { decodeParams(P.self).map(decode) ?? 0 },
                set: { encodeAndStore(encode($0)) }
            ), format: .number)
            .font(TaxiwayTheme.monoSmall)
            .textFieldStyle(.roundedBorder)
            .frame(width: 100)
            .disabled(readOnly)
        }
    }

    @ViewBuilder
    private func stringParameterEditor<P: CheckParameters>(
        label: String,
        decode: @escaping (P) -> String,
        encode: @escaping (String) -> P
    ) -> some View {
        HStack {
            Text(label)
                .font(TaxiwayTheme.monoSmall)
            Spacer()
            TextField(label, text: Binding(
                get: { decodeParams(P.self).map(decode) ?? "" },
                set: { encodeAndStore(encode($0)) }
            ))
            .font(TaxiwayTheme.monoSmall)
            .textFieldStyle(.roundedBorder)
            .frame(width: 160)
            .disabled(readOnly)
        }
    }

    // MARK: - Composite Editors

    @ViewBuilder
    private func metadataMatchesEditor() -> some View {
        let params = decodeParams(MetadataFieldMatchesCheck.Parameters.self)
            ?? MetadataFieldMatchesCheck.Parameters(fieldName: "", expectedValue: "")
        VStack(spacing: 8) {
            HStack {
                Text("Field name")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("Field", text: Binding(
                    get: { decodeParams(MetadataFieldMatchesCheck.Parameters.self)?.fieldName ?? "" },
                    set: { val in
                        let current = decodeParams(MetadataFieldMatchesCheck.Parameters.self) ?? params
                        encodeAndStore(MetadataFieldMatchesCheck.Parameters(fieldName: val, expectedValue: current.expectedValue))
                    }
                ))
                .font(TaxiwayTheme.monoSmall)
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)
                .disabled(readOnly)
            }
            HStack {
                Text("Expected value")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("Value", text: Binding(
                    get: { decodeParams(MetadataFieldMatchesCheck.Parameters.self)?.expectedValue ?? "" },
                    set: { val in
                        let current = decodeParams(MetadataFieldMatchesCheck.Parameters.self) ?? params
                        encodeAndStore(MetadataFieldMatchesCheck.Parameters(fieldName: current.fieldName, expectedValue: val))
                    }
                ))
                .font(TaxiwayTheme.monoSmall)
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)
                .disabled(readOnly)
            }
        }
    }

    @ViewBuilder
    private func pdfVersionEditor() -> some View {
        let params = decodeParams(PDFVersionCheck.Parameters.self)
            ?? PDFVersionCheck.Parameters(operator: .is, version: "1.4")
        VStack(spacing: 8) {
            HStack {
                Text("Operator")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                Picker("", selection: Binding(
                    get: { decodeParams(PDFVersionCheck.Parameters.self)?.operator ?? .is },
                    set: { val in
                        let current = decodeParams(PDFVersionCheck.Parameters.self) ?? params
                        encodeAndStore(PDFVersionCheck.Parameters(operator: val, version: current.version))
                    }
                )) {
                    Text("Is").tag(ComparisonOperator.is)
                    Text("Is Not").tag(ComparisonOperator.isNot)
                }
                .labelsHidden()
                .frame(width: 100)
                .disabled(readOnly)
            }
            HStack {
                Text("Version")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("1.4", text: Binding(
                    get: { decodeParams(PDFVersionCheck.Parameters.self)?.version ?? "" },
                    set: { val in
                        let current = decodeParams(PDFVersionCheck.Parameters.self) ?? params
                        encodeAndStore(PDFVersionCheck.Parameters(operator: current.operator, version: val))
                    }
                ))
                .font(TaxiwayTheme.monoSmall)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .disabled(readOnly)
            }
        }
    }

    @ViewBuilder
    private func pdfConformanceEditor() -> some View {
        HStack {
            Text("Standard")
                .font(TaxiwayTheme.monoSmall)
            Spacer()
            Picker("", selection: Binding(
                get: { decodeParams(PDFConformanceCheck.Parameters.self)?.standard ?? .x1a },
                set: { encodeAndStore(PDFConformanceCheck.Parameters(standard: $0)) }
            )) {
                Text("PDF/X-1a").tag(PDFStandard.x1a)
                Text("PDF/X-3").tag(PDFStandard.x3)
                Text("PDF/X-4").tag(PDFStandard.x4)
                Text("PDF/A-1b").tag(PDFStandard.a1b)
                Text("PDF/A-2b").tag(PDFStandard.a2b)
                Text("PDF/A-3b").tag(PDFStandard.a3b)
            }
            .labelsHidden()
            .frame(width: 120)
            .disabled(readOnly)
        }
    }

    @ViewBuilder
    private func pageCountEditor() -> some View {
        let params = decodeParams(PageCountCheck.Parameters.self)
            ?? PageCountCheck.Parameters(operator: .equals, value: 1)
        VStack(spacing: 8) {
            HStack {
                Text("Operator")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                Picker("", selection: Binding(
                    get: { decodeParams(PageCountCheck.Parameters.self)?.operator ?? .equals },
                    set: { val in
                        let current = decodeParams(PageCountCheck.Parameters.self) ?? params
                        encodeAndStore(PageCountCheck.Parameters(operator: val, value: current.value))
                    }
                )) {
                    Text("Equals").tag(NumericOperator.equals)
                    Text("Less Than").tag(NumericOperator.lessThan)
                    Text("More Than").tag(NumericOperator.moreThan)
                }
                .labelsHidden()
                .frame(width: 120)
                .disabled(readOnly)
            }
            HStack {
                Text("Value")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("Pages", value: Binding(
                    get: { decodeParams(PageCountCheck.Parameters.self)?.value ?? 1 },
                    set: { val in
                        let current = decodeParams(PageCountCheck.Parameters.self) ?? params
                        encodeAndStore(PageCountCheck.Parameters(operator: current.operator, value: val))
                    }
                ), format: .number)
                .font(TaxiwayTheme.monoSmall)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .disabled(readOnly)
            }
        }
    }

    @ViewBuilder
    private func pageSizeEditor() -> some View {
        let params = decodeParams(PageSizeCheck.Parameters.self)
            ?? PageSizeCheck.Parameters(targetWidthPt: 595, targetHeightPt: 842, tolerancePt: 1)
        VStack(spacing: 8) {
            HStack {
                Text("Width (pt)")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("Width", value: Binding(
                    get: { decodeParams(PageSizeCheck.Parameters.self)?.targetWidthPt ?? 595 },
                    set: { val in
                        let current = decodeParams(PageSizeCheck.Parameters.self) ?? params
                        encodeAndStore(PageSizeCheck.Parameters(targetWidthPt: val, targetHeightPt: current.targetHeightPt, tolerancePt: current.tolerancePt))
                    }
                ), format: .number)
                .font(TaxiwayTheme.monoSmall)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .disabled(readOnly)
            }
            HStack {
                Text("Height (pt)")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("Height", value: Binding(
                    get: { decodeParams(PageSizeCheck.Parameters.self)?.targetHeightPt ?? 842 },
                    set: { val in
                        let current = decodeParams(PageSizeCheck.Parameters.self) ?? params
                        encodeAndStore(PageSizeCheck.Parameters(targetWidthPt: current.targetWidthPt, targetHeightPt: val, tolerancePt: current.tolerancePt))
                    }
                ), format: .number)
                .font(TaxiwayTheme.monoSmall)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .disabled(readOnly)
            }
            HStack {
                Text("Tolerance (pt)")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("Tolerance", value: Binding(
                    get: { decodeParams(PageSizeCheck.Parameters.self)?.tolerancePt ?? 1 },
                    set: { val in
                        let current = decodeParams(PageSizeCheck.Parameters.self) ?? params
                        encodeAndStore(PageSizeCheck.Parameters(targetWidthPt: current.targetWidthPt, targetHeightPt: current.targetHeightPt, tolerancePt: val))
                    }
                ), format: .number)
                .font(TaxiwayTheme.monoSmall)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .disabled(readOnly)
            }
        }
    }

    @ViewBuilder
    private func colourSpaceUsedEditor() -> some View {
        let params = decodeParams(ColourSpaceUsedCheck.Parameters.self)
            ?? ColourSpaceUsedCheck.Parameters(colourSpace: .deviceRGB, operator: .is)
        VStack(spacing: 8) {
            HStack {
                Text("Colour space")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                Picker("", selection: Binding(
                    get: { decodeParams(ColourSpaceUsedCheck.Parameters.self)?.colourSpace ?? .deviceRGB },
                    set: { val in
                        let current = decodeParams(ColourSpaceUsedCheck.Parameters.self) ?? params
                        encodeAndStore(ColourSpaceUsedCheck.Parameters(colourSpace: val, operator: current.operator))
                    }
                )) {
                    Text("DeviceGray").tag(ColourSpaceName.deviceGray)
                    Text("DeviceRGB").tag(ColourSpaceName.deviceRGB)
                    Text("DeviceCMYK").tag(ColourSpaceName.deviceCMYK)
                    Text("ICCBased").tag(ColourSpaceName.iccBased)
                    Text("CalGray").tag(ColourSpaceName.calGray)
                    Text("CalRGB").tag(ColourSpaceName.calRGB)
                    Text("Lab").tag(ColourSpaceName.lab)
                    Text("Indexed").tag(ColourSpaceName.indexed)
                    Text("Separation").tag(ColourSpaceName.separation)
                    Text("DeviceN").tag(ColourSpaceName.deviceN)
                    Text("Pattern").tag(ColourSpaceName.pattern)
                    Text("Unknown").tag(ColourSpaceName.unknown)
                }
                .labelsHidden()
                .frame(width: 140)
                .disabled(readOnly)
            }
            HStack {
                Text("Operator")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                Picker("", selection: Binding(
                    get: { decodeParams(ColourSpaceUsedCheck.Parameters.self)?.operator ?? .is },
                    set: { val in
                        let current = decodeParams(ColourSpaceUsedCheck.Parameters.self) ?? params
                        encodeAndStore(ColourSpaceUsedCheck.Parameters(colourSpace: current.colourSpace, operator: val))
                    }
                )) {
                    Text("Is").tag(ComparisonOperator.is)
                    Text("Is Not").tag(ComparisonOperator.isNot)
                }
                .labelsHidden()
                .frame(width: 100)
                .disabled(readOnly)
            }
        }
    }

    @ViewBuilder
    private func fontTypeEditor() -> some View {
        let params = decodeParams(FontTypeCheck.Parameters.self)
            ?? FontTypeCheck.Parameters(fontType: .type1, operator: .is)
        VStack(spacing: 8) {
            HStack {
                Text("Font type")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                Picker("", selection: Binding(
                    get: { decodeParams(FontTypeCheck.Parameters.self)?.fontType ?? .type1 },
                    set: { val in
                        let current = decodeParams(FontTypeCheck.Parameters.self) ?? params
                        encodeAndStore(FontTypeCheck.Parameters(fontType: val, operator: current.operator))
                    }
                )) {
                    Text("Type1").tag(FontType.type1)
                    Text("TrueType").tag(FontType.trueType)
                    Text("OpenType CFF").tag(FontType.openTypeCFF)
                    Text("CIDFontType0").tag(FontType.cidFontType0)
                    Text("CIDFontType2").tag(FontType.cidFontType2)
                    Text("Type3").tag(FontType.type3)
                    Text("MMType1").tag(FontType.mmType1)
                    Text("Unknown").tag(FontType.unknown)
                }
                .labelsHidden()
                .frame(width: 140)
                .disabled(readOnly)
            }
            HStack {
                Text("Operator")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                Picker("", selection: Binding(
                    get: { decodeParams(FontTypeCheck.Parameters.self)?.operator ?? .is },
                    set: { val in
                        let current = decodeParams(FontTypeCheck.Parameters.self) ?? params
                        encodeAndStore(FontTypeCheck.Parameters(fontType: current.fontType, operator: val))
                    }
                )) {
                    Text("Is").tag(ComparisonOperator.is)
                    Text("Is Not").tag(ComparisonOperator.isNot)
                }
                .labelsHidden()
                .frame(width: 100)
                .disabled(readOnly)
            }
        }
    }

    @ViewBuilder
    private func fontSizeEditor() -> some View {
        let params = decodeParams(FontSizeCheck.Parameters.self)
            ?? FontSizeCheck.Parameters(threshold: 6, operator: .lessThan)
        VStack(spacing: 8) {
            HStack {
                Text("Operator")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                Picker("", selection: Binding(
                    get: { decodeParams(FontSizeCheck.Parameters.self)?.operator ?? .lessThan },
                    set: { val in
                        let current = decodeParams(FontSizeCheck.Parameters.self) ?? params
                        encodeAndStore(FontSizeCheck.Parameters(threshold: current.threshold, operator: val))
                    }
                )) {
                    Text("Equals").tag(NumericOperator.equals)
                    Text("Less Than").tag(NumericOperator.lessThan)
                    Text("More Than").tag(NumericOperator.moreThan)
                }
                .labelsHidden()
                .frame(width: 120)
                .disabled(readOnly)
            }
            HStack {
                Text("Threshold (pt)")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("Size", value: Binding(
                    get: { decodeParams(FontSizeCheck.Parameters.self)?.threshold ?? 6 },
                    set: { val in
                        let current = decodeParams(FontSizeCheck.Parameters.self) ?? params
                        encodeAndStore(FontSizeCheck.Parameters(threshold: val, operator: current.operator))
                    }
                ), format: .number)
                .font(TaxiwayTheme.monoSmall)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .disabled(readOnly)
            }
        }
    }

    @ViewBuilder
    private func imageColourModeEditor() -> some View {
        let params = decodeParams(ImageColourModeCheck.Parameters.self)
            ?? ImageColourModeCheck.Parameters(colourMode: .deviceRGB, operator: .is)
        VStack(spacing: 8) {
            HStack {
                Text("Colour mode")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                Picker("", selection: Binding(
                    get: { decodeParams(ImageColourModeCheck.Parameters.self)?.colourMode ?? .deviceRGB },
                    set: { val in
                        let current = decodeParams(ImageColourModeCheck.Parameters.self) ?? params
                        encodeAndStore(ImageColourModeCheck.Parameters(colourMode: val, operator: current.operator))
                    }
                )) {
                    Text("DeviceGray").tag(ImageColourMode.deviceGray)
                    Text("DeviceRGB").tag(ImageColourMode.deviceRGB)
                    Text("DeviceCMYK").tag(ImageColourMode.deviceCMYK)
                    Text("ICCBased").tag(ImageColourMode.iccBased)
                    Text("Indexed").tag(ImageColourMode.indexed)
                    Text("Separation").tag(ImageColourMode.separation)
                    Text("DeviceN").tag(ImageColourMode.deviceN)
                    Text("Unknown").tag(ImageColourMode.unknown)
                }
                .labelsHidden()
                .frame(width: 140)
                .disabled(readOnly)
            }
            HStack {
                Text("Operator")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                Picker("", selection: Binding(
                    get: { decodeParams(ImageColourModeCheck.Parameters.self)?.operator ?? .is },
                    set: { val in
                        let current = decodeParams(ImageColourModeCheck.Parameters.self) ?? params
                        encodeAndStore(ImageColourModeCheck.Parameters(colourMode: current.colourMode, operator: val))
                    }
                )) {
                    Text("Is").tag(ComparisonOperator.is)
                    Text("Is Not").tag(ComparisonOperator.isNot)
                }
                .labelsHidden()
                .frame(width: 100)
                .disabled(readOnly)
            }
        }
    }

    @ViewBuilder
    private func imageTypeEditor() -> some View {
        let params = decodeParams(ImageTypeCheck.Parameters.self)
            ?? ImageTypeCheck.Parameters(compressionType: .jpeg, operator: .is)
        VStack(spacing: 8) {
            HStack {
                Text("Compression")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                Picker("", selection: Binding(
                    get: { decodeParams(ImageTypeCheck.Parameters.self)?.compressionType ?? .jpeg },
                    set: { val in
                        let current = decodeParams(ImageTypeCheck.Parameters.self) ?? params
                        encodeAndStore(ImageTypeCheck.Parameters(compressionType: val, operator: current.operator))
                    }
                )) {
                    Text("JPEG").tag(ImageCompressionType.jpeg)
                    Text("JPEG 2000").tag(ImageCompressionType.jpeg2000)
                    Text("JBIG2").tag(ImageCompressionType.jbig2)
                    Text("CCITT").tag(ImageCompressionType.ccitt)
                    Text("Flate").tag(ImageCompressionType.flate)
                    Text("LZW").tag(ImageCompressionType.lzw)
                    Text("RunLength").tag(ImageCompressionType.runLength)
                    Text("None").tag(ImageCompressionType.none)
                    Text("Unknown").tag(ImageCompressionType.unknown)
                }
                .labelsHidden()
                .frame(width: 140)
                .disabled(readOnly)
            }
            HStack {
                Text("Operator")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                Picker("", selection: Binding(
                    get: { decodeParams(ImageTypeCheck.Parameters.self)?.operator ?? .is },
                    set: { val in
                        let current = decodeParams(ImageTypeCheck.Parameters.self) ?? params
                        encodeAndStore(ImageTypeCheck.Parameters(compressionType: current.compressionType, operator: val))
                    }
                )) {
                    Text("Is").tag(ComparisonOperator.is)
                    Text("Is Not").tag(ComparisonOperator.isNot)
                }
                .labelsHidden()
                .frame(width: 100)
                .disabled(readOnly)
            }
        }
    }

    @ViewBuilder
    private func resolutionRangeEditor() -> some View {
        let params = decodeParams(ResolutionRangeCheck.Parameters.self)
            ?? ResolutionRangeCheck.Parameters(minPPI: 150, maxPPI: 600)
        VStack(spacing: 8) {
            HStack {
                Text("Min PPI")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("Min", value: Binding(
                    get: { decodeParams(ResolutionRangeCheck.Parameters.self)?.minPPI ?? 150 },
                    set: { val in
                        let current = decodeParams(ResolutionRangeCheck.Parameters.self) ?? params
                        encodeAndStore(ResolutionRangeCheck.Parameters(minPPI: val, maxPPI: current.maxPPI))
                    }
                ), format: .number)
                .font(TaxiwayTheme.monoSmall)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .disabled(readOnly)
            }
            HStack {
                Text("Max PPI")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("Max", value: Binding(
                    get: { decodeParams(ResolutionRangeCheck.Parameters.self)?.maxPPI ?? 600 },
                    set: { val in
                        let current = decodeParams(ResolutionRangeCheck.Parameters.self) ?? params
                        encodeAndStore(ResolutionRangeCheck.Parameters(minPPI: current.minPPI, maxPPI: val))
                    }
                ), format: .number)
                .font(TaxiwayTheme.monoSmall)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .disabled(readOnly)
            }
        }
    }

    @ViewBuilder
    private func comparisonOperatorEditor<P: CheckParameters>(
        decode: @escaping (P) -> ComparisonOperator,
        encode: @escaping (ComparisonOperator) -> P
    ) -> some View {
        HStack {
            Text("Operator")
                .font(TaxiwayTheme.monoSmall)
            Spacer()
            Picker("", selection: Binding(
                get: { decodeParams(P.self).map(decode) ?? .is },
                set: { encodeAndStore(encode($0)) }
            )) {
                Text("Is").tag(ComparisonOperator.is)
                Text("Is Not").tag(ComparisonOperator.isNot)
            }
            .labelsHidden()
            .frame(width: 100)
            .disabled(readOnly)
        }
    }

    @ViewBuilder
    private func inkCoverageEditor() -> some View {
        let params = decodeParams(InkCoverageCheck.Parameters.self)
            ?? InkCoverageCheck.Parameters(thresholdPercent: 300, operator: .moreThan)
        VStack(spacing: 8) {
            HStack {
                Text("Operator")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                Picker("", selection: Binding(
                    get: { decodeParams(InkCoverageCheck.Parameters.self)?.operator ?? .moreThan },
                    set: { val in
                        let current = decodeParams(InkCoverageCheck.Parameters.self) ?? params
                        encodeAndStore(InkCoverageCheck.Parameters(thresholdPercent: current.thresholdPercent, operator: val))
                    }
                )) {
                    Text("Equals").tag(NumericOperator.equals)
                    Text("Less Than").tag(NumericOperator.lessThan)
                    Text("More Than").tag(NumericOperator.moreThan)
                }
                .labelsHidden()
                .frame(width: 120)
                .disabled(readOnly)
            }
            HStack {
                Text("Threshold (%)")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("300", value: Binding(
                    get: { decodeParams(InkCoverageCheck.Parameters.self)?.thresholdPercent ?? 300 },
                    set: { val in
                        let current = decodeParams(InkCoverageCheck.Parameters.self) ?? params
                        encodeAndStore(InkCoverageCheck.Parameters(thresholdPercent: val, operator: current.operator))
                    }
                ), format: .number)
                .font(TaxiwayTheme.monoSmall)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .disabled(readOnly)
            }
        }
    }

    @ViewBuilder
    private func overprintContextEditor() -> some View {
        HStack {
            Text("Context")
                .font(TaxiwayTheme.monoSmall)
            Spacer()
            Picker("", selection: Binding(
                get: { decodeParams(OverprintCheck.Parameters.self)?.context ?? .fill },
                set: { encodeAndStore(OverprintCheck.Parameters(context: $0)) }
            )) {
                Text("Fill").tag(OverprintCheck.OverprintCheckContext.fill)
                Text("Stroke").tag(OverprintCheck.OverprintCheckContext.stroke)
                Text("Text").tag(OverprintCheck.OverprintCheckContext.text)
                Text("White").tag(OverprintCheck.OverprintCheckContext.white)
            }
            .labelsHidden()
            .frame(width: 120)
            .disabled(readOnly)
        }
    }

    // MARK: - Helpers

    private func decodeParams<P: CheckParameters>(_ type: P.Type) -> P? {
        try? JSONDecoder().decode(P.self, from: entry.parametersJSON)
    }

    private func encodeAndStore<P: CheckParameters>(_ params: P) {
        guard let data = try? JSONEncoder().encode(params) else { return }
        entry.parametersJSON = data
    }
}
