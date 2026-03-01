# Profile Editor Overhaul + Report PDF Preview — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Overhaul the profile editor with human-readable names, editable parameters, and a 3-column layout; add PDF page preview with bbox highlighting to the report view.

**Architecture:** Two independent features. Feature 1 rewrites ProfileEditorView as a NavigationSplitView with a CheckMetadata dictionary and dynamic ParameterEditorView. Feature 2 adds bounds to AnnotationInfo, extends AffectedItem with optional rect, and adds a PDFPreviewView using PDFKit to the report detail area.

**Tech Stack:** SwiftUI, PDFKit, TaxiwayCore (Swift Package)

**Build commands:**
- Package tests: `cd /Users/ruby/GitRepos/Taxiway/TaxiwayCore && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test`
- App build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace /Users/ruby/GitRepos/Taxiway/Taxiway.xcworkspace -scheme Taxiway -destination 'platform=macOS' build`

**Key context:**
- App uses `fileSystemSynchronizedRootGroup` — new .swift files in `Taxiway/` are auto-discovered, no pbxproj edits needed
- TaxiwayCore is a local Swift Package at `TaxiwayCore/`
- Swift 6 for package, Swift 5 mode for app target with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- All 43 check types use `ParameterisedCheck` protocol with typed `Parameters` structs
- `CheckEntry.parametersJSON` stores JSON-encoded parameters as `Data`

---

## Phase 1: Parser — Add Annotation Bounds

### Task 1: Add bounds to AnnotationInfo model

**Files:**
- Modify: `TaxiwayCore/Sources/TaxiwayCore/Models/AnnotationInfo.swift`
- Modify: `TaxiwayCore/Tests/TaxiwayCoreTests/Parser/AnnotationExtractorTests.swift`

**Step 1: Update AnnotationInfo to include bounds**

```swift
// AnnotationInfo.swift — full rewrite
import Foundation

public enum AnnotationType: String, Codable, Sendable, Equatable {
    case link = "Link"
    case widget = "Widget"
    case text = "Text"
    case freeText = "FreeText"
    case highlight = "Highlight"
    case underline = "Underline"
    case strikeOut = "StrikeOut"
    case stamp = "Stamp"
    case ink = "Ink"
    case popup = "Popup"
    case fileAttachment = "FileAttachment"
    case other = "Other"
}

public struct AnnotationBounds: Codable, Sendable, Equatable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct AnnotationInfo: Codable, Sendable, Equatable {
    public let type: AnnotationType
    public let pageIndex: Int
    public let subtype: String?
    public let bounds: AnnotationBounds?

    public init(type: AnnotationType, pageIndex: Int, subtype: String? = nil, bounds: AnnotationBounds? = nil) {
        self.type = type
        self.pageIndex = pageIndex
        self.subtype = subtype
        self.bounds = bounds
    }
}
```

Note: We use a custom `AnnotationBounds` struct rather than `CGRect` because `CGRect` doesn't conform to `Codable`/`Sendable` and TaxiwayCore is a pure Swift package that shouldn't depend on CoreGraphics.

**Step 2: Run tests to verify nothing broke (bounds is optional, so existing tests should pass)**

Run: `cd /Users/ruby/GitRepos/Taxiway/TaxiwayCore && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test`
Expected: All 459 tests pass

**Step 3: Update AnnotationExtractor to capture bounds**

```swift
// AnnotationExtractor.swift — modify extract method
// Change line 20-24 from:
annotations.append(AnnotationInfo(
    type: annotationType,
    pageIndex: i,
    subtype: subtypeStr
))
// To:
let rect = annotation.bounds
let annotBounds = AnnotationBounds(
    x: rect.origin.x,
    y: rect.origin.y,
    width: rect.size.width,
    height: rect.size.height
)
annotations.append(AnnotationInfo(
    type: annotationType,
    pageIndex: i,
    subtype: subtypeStr,
    bounds: annotBounds
))
```

**Step 4: Run tests again**

Run: `cd /Users/ruby/GitRepos/Taxiway/TaxiwayCore && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test`
Expected: All tests pass

**Step 5: Commit**

```bash
git add TaxiwayCore/Sources/TaxiwayCore/Models/AnnotationInfo.swift TaxiwayCore/Sources/TaxiwayCore/Parser/AnnotationExtractor.swift
git commit -m "feat: add bounds to AnnotationInfo for bbox highlighting"
```

---

### Task 2: Add optional rect to AffectedItem.annotation

**Files:**
- Modify: `TaxiwayCore/Sources/TaxiwayCore/Checks/AffectedItem.swift`
- Modify: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/PDF/AnnotationsPresentCheck.swift`

**Step 1: Extend AffectedItem with rect parameter**

```swift
// AffectedItem.swift — full rewrite
import Foundation

public enum AffectedItem: Codable, Sendable, Equatable {
    case document
    case page(index: Int)
    case font(name: String, pages: [Int])
    case image(id: String, page: Int)
    case colourSpace(name: String, pages: [Int])
    case annotation(type: String, page: Int, bounds: AnnotationBounds? = nil)
}
```

**Step 2: Update AnnotationsPresentCheck to pass bounds**

```swift
// AnnotationsPresentCheck.swift — change line 29-31 from:
let affectedItems = document.annotations.map {
    AffectedItem.annotation(type: $0.type.rawValue, page: $0.pageIndex)
}
// To:
let affectedItems = document.annotations.map {
    AffectedItem.annotation(type: $0.type.rawValue, page: $0.pageIndex, bounds: $0.bounds)
}
```

**Step 3: Run tests**

Run: `cd /Users/ruby/GitRepos/Taxiway/TaxiwayCore && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test`
Expected: All tests pass (default nil for bounds means existing test assertions still match)

**Step 4: Fix any tests that construct `.annotation` without the bounds parameter**

Search for `.annotation(type:` in test files and add `bounds: nil` if the compiler requires it. Since the parameter has a default value, this should not be needed.

**Step 5: Commit**

```bash
git add TaxiwayCore/Sources/TaxiwayCore/Checks/AffectedItem.swift TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/PDF/AnnotationsPresentCheck.swift
git commit -m "feat: add optional bounds to AffectedItem.annotation"
```

---

## Phase 2: Profile Editor Overhaul

### Task 3: Create CheckMetadata dictionary

**Files:**
- Create: `Taxiway/Taxiway/Views/ProfileEditor/CheckMetadata.swift`

**Step 1: Create the metadata file**

This maps every typeID to a human-readable display name and short description.

```swift
import Foundation

struct CheckMetadata {
    let displayName: String
    let description: String

    static let all: [String: CheckMetadata] = [
        // File
        "file.encryption": CheckMetadata(displayName: "Encryption", description: "Verify file encryption status."),
        "file.size.max": CheckMetadata(displayName: "Maximum File Size", description: "Fail if file exceeds size limit."),
        "file.size.min": CheckMetadata(displayName: "Minimum File Size", description: "Fail if file is below size limit."),
        "file.interactive_elements": CheckMetadata(displayName: "Interactive Elements", description: "Detect form fields and widgets."),
        "file.metadata.present": CheckMetadata(displayName: "Metadata Field Present", description: "Check that a metadata field is set."),
        "file.metadata.matches": CheckMetadata(displayName: "Metadata Field Matches", description: "Verify metadata field has expected value."),

        // PDF
        "pdf.version": CheckMetadata(displayName: "PDF Version", description: "Check PDF version number."),
        "pdf.conformance": CheckMetadata(displayName: "PDF Conformance", description: "Verify PDF/X or PDF/A standard compliance."),
        "pdf.annotations": CheckMetadata(displayName: "Annotations Present", description: "Detect annotations in the document."),
        "pdf.layers": CheckMetadata(displayName: "Layers Present", description: "Detect optional content layers."),
        "pdf.linearized": CheckMetadata(displayName: "Linearized", description: "Check if PDF is optimized for web."),
        "pdf.tagged": CheckMetadata(displayName: "Tagged PDF", description: "Verify structure tags for accessibility."),

        // Pages
        "pages.count": CheckMetadata(displayName: "Page Count", description: "Validate total number of pages."),
        "pages.size": CheckMetadata(displayName: "Page Size", description: "Verify page dimensions match target."),
        "pages.mixed_sizes": CheckMetadata(displayName: "Mixed Page Sizes", description: "Detect inconsistent page dimensions."),
        "pages.rotation": CheckMetadata(displayName: "Page Rotation", description: "Detect rotated pages."),

        // Marks
        "marks.bleed_zero": CheckMetadata(displayName: "Zero Bleed", description: "Flag pages with no bleed."),
        "marks.bleed_nonzero": CheckMetadata(displayName: "Non-Zero Bleed", description: "Flag pages with bleed set."),
        "marks.bleed_greater_than": CheckMetadata(displayName: "Bleed Exceeds Limit", description: "Flag bleed above threshold."),
        "marks.bleed_less_than": CheckMetadata(displayName: "Bleed Below Minimum", description: "Flag bleed under threshold."),
        "marks.bleed_non_uniform": CheckMetadata(displayName: "Non-Uniform Bleed", description: "Flag uneven bleed margins."),
        "marks.trim_box_set": CheckMetadata(displayName: "Trim Box Set", description: "Verify trim box is defined."),

        // Colour
        "colour.space_used": CheckMetadata(displayName: "Colour Space Used", description: "Detect or reject a colour space."),
        "colour.spot_used": CheckMetadata(displayName: "Spot Colours Used", description: "Report spot colour inks."),
        "colour.spot_count": CheckMetadata(displayName: "Spot Colour Count", description: "Limit number of spot colours."),
        "colour.registration": CheckMetadata(displayName: "Registration Colour", description: "Detect registration colour marks."),

        // Fonts
        "fonts.not_embedded": CheckMetadata(displayName: "Unembedded Fonts", description: "Flag fonts not embedded in the PDF."),
        "fonts.type": CheckMetadata(displayName: "Font Type", description: "Detect or reject a font type."),
        "fonts.size": CheckMetadata(displayName: "Font Size", description: "Check font sizes against threshold."),

        // Images
        "images.alpha": CheckMetadata(displayName: "Alpha Channel", description: "Flag images with transparency."),
        "images.blend_mode": CheckMetadata(displayName: "Blend Mode / Opacity", description: "Flag non-normal blend modes."),
        "images.colour_mode": CheckMetadata(displayName: "Image Colour Mode", description: "Detect or reject an image colour mode."),
        "images.type": CheckMetadata(displayName: "Image Compression", description: "Detect or reject a compression type."),
        "images.icc_missing": CheckMetadata(displayName: "Missing ICC Profile", description: "Flag images without ICC profiles."),
        "images.scaled": CheckMetadata(displayName: "Image Scaled", description: "Flag images scaled beyond tolerance."),
        "images.scaled_non_proportional": CheckMetadata(displayName: "Non-Proportional Scaling", description: "Flag distorted images."),
        "images.resolution_below": CheckMetadata(displayName: "Low Resolution", description: "Flag images below minimum PPI."),
        "images.resolution_above": CheckMetadata(displayName: "High Resolution", description: "Flag images above maximum PPI."),
        "images.resolution_range": CheckMetadata(displayName: "Resolution Range", description: "Flag images outside PPI range."),
        "images.c2pa": CheckMetadata(displayName: "C2PA Credentials", description: "Detect content provenance metadata."),
        "images.genai": CheckMetadata(displayName: "GenAI Metadata", description: "Detect generative AI indicators."),

        // Lines
        "lines.zero_width": CheckMetadata(displayName: "Zero-Width Strokes", description: "Detect strokes with zero width."),
        "lines.stroke_below": CheckMetadata(displayName: "Thin Strokes", description: "Flag strokes below minimum weight."),
    ]

    static func displayName(for typeID: String) -> String {
        all[typeID]?.displayName ?? typeID
    }

    static func description(for typeID: String) -> String {
        all[typeID]?.description ?? ""
    }

    static func category(for typeID: String) -> String {
        String(typeID.prefix(while: { $0 != "." }))
    }
}
```

**Step 2: Build app to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace /Users/ruby/GitRepos/Taxiway/Taxiway.xcworkspace -scheme Taxiway -destination 'platform=macOS' build 2>&1 | grep -E "error:|BUILD"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Taxiway/Views/ProfileEditor/CheckMetadata.swift
git commit -m "feat: add CheckMetadata dictionary with display names for all 43 checks"
```

---

### Task 4: Create ParameterEditorView for dynamic parameter editing

**Files:**
- Create: `Taxiway/Taxiway/Views/ProfileEditor/ParameterEditorView.swift`

**Step 1: Create the view**

This view decodes `CheckEntry.parametersJSON` into the correct parameter struct based on typeID, renders appropriate controls, and re-encodes on change.

```swift
import SwiftUI
import TaxiwayCore

struct ParameterEditorView: View {
    @Binding var entry: CheckEntry
    let readOnly: Bool

    var body: some View {
        let typeID = entry.typeID
        Group {
            switch typeID {
            // --- File ---
            case "file.encryption":
                boolParam(label: "Expected encrypted", keyPath: \EncryptionCheck.Parameters.expected)
            case "file.size.max":
                doubleParam(label: "Max size (MB)", keyPath: \FileSizeMaxCheck.Parameters.maxSizeMB, range: 0...10000)
            case "file.size.min":
                doubleParam(label: "Min size (MB)", keyPath: \FileSizeMinCheck.Parameters.minSizeMB, range: 0...10000)
            case "file.metadata.present":
                stringParam(label: "Field name", keyPath: \MetadataFieldPresentCheck.Parameters.fieldName,
                            options: ["title", "author", "subject", "keywords", "producer", "creator"])
            case "file.metadata.matches":
                metadataMatchesEditor()

            // --- PDF ---
            case "pdf.version":
                pdfVersionEditor()
            case "pdf.conformance":
                enumParam(label: "Standard", keyPath: \PDFConformanceCheck.Parameters.standard)
            case "pdf.linearized":
                boolParam(label: "Expected linearized", keyPath: \LinearizedCheck.Parameters.expected)
            case "pdf.tagged":
                boolParam(label: "Expected tagged", keyPath: \TaggedCheck.Parameters.expected)

            // --- Pages ---
            case "pages.count":
                pageCountEditor()
            case "pages.size":
                pageSizeEditor()

            // --- Marks ---
            case "marks.bleed_greater_than":
                doubleParam(label: "Threshold (mm)", keyPath: \BleedGreaterThanCheck.Parameters.thresholdMM, range: 0...50)
            case "marks.bleed_less_than":
                doubleParam(label: "Threshold (mm)", keyPath: \BleedLessThanCheck.Parameters.thresholdMM, range: 0...50)
            case "marks.bleed_non_uniform":
                doubleParam(label: "Tolerance (mm)", keyPath: \BleedNonUniformCheck.Parameters.toleranceMM, range: 0...10)

            // --- Colour ---
            case "colour.space_used":
                colourSpaceEditor()
            case "colour.spot_count":
                intParam(label: "Max spot colours", keyPath: \SpotColourCountCheck.Parameters.maxCount, range: 0...100)

            // --- Fonts ---
            case "fonts.type":
                fontTypeEditor()
            case "fonts.size":
                fontSizeEditor()

            // --- Images ---
            case "images.scaled":
                doubleParam(label: "Tolerance (%)", keyPath: \ImageScaledCheck.Parameters.tolerancePercent, range: 0...100)
            case "images.scaled_non_proportional":
                doubleParam(label: "Tolerance (%)", keyPath: \ImageScaledNonProportionallyCheck.Parameters.tolerancePercent, range: 0...100)
            case "images.resolution_below":
                doubleParam(label: "Min PPI", keyPath: \ResolutionBelowCheck.Parameters.thresholdPPI, range: 0...2400)
            case "images.resolution_above":
                doubleParam(label: "Max PPI", keyPath: \ResolutionAboveCheck.Parameters.thresholdPPI, range: 0...2400)
            case "images.resolution_range":
                resolutionRangeEditor()
            case "images.colour_mode":
                imageColourModeEditor()
            case "images.type":
                imageTypeEditor()

            // --- Lines ---
            case "lines.stroke_below":
                doubleParam(label: "Min weight (pt)", keyPath: \StrokeWeightBelowCheck.Parameters.thresholdPt, range: 0...10)

            default:
                Text("No configurable parameters")
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(readOnly)
    }

    // MARK: - Generic Parameter Editors

    private func boolParam<P: CheckParameters>(label: String, keyPath: WritableKeyPath<P, Bool>) -> some View {
        let params = decodeParams(P.self)
        return Toggle(label, isOn: Binding(
            get: { params?[keyPath: keyPath] ?? false },
            set: { newVal in
                guard var p = params else { return }
                p[keyPath: keyPath] = newVal
                encodeParams(p)
            }
        ))
        .font(TaxiwayTheme.monoSmall)
    }

    private func doubleParam<P: CheckParameters>(label: String, keyPath: WritableKeyPath<P, Double>, range: ClosedRange<Double>) -> some View {
        let params = decodeParams(P.self)
        let value = params?[keyPath: keyPath] ?? range.lowerBound
        return HStack {
            Text(label)
                .font(TaxiwayTheme.monoSmall)
            Spacer()
            TextField("", value: Binding(
                get: { value },
                set: { newVal in
                    guard var p = params else { return }
                    p[keyPath: keyPath] = min(max(newVal, range.lowerBound), range.upperBound)
                    encodeParams(p)
                }
            ), format: .number)
            .frame(width: 80)
            .textFieldStyle(.roundedBorder)
            .font(TaxiwayTheme.monoSmall)
        }
    }

    private func intParam<P: CheckParameters>(label: String, keyPath: WritableKeyPath<P, Int>, range: ClosedRange<Int>) -> some View {
        let params = decodeParams(P.self)
        let value = params?[keyPath: keyPath] ?? range.lowerBound
        return HStack {
            Text(label)
                .font(TaxiwayTheme.monoSmall)
            Spacer()
            TextField("", value: Binding(
                get: { value },
                set: { newVal in
                    guard var p = params else { return }
                    p[keyPath: keyPath] = min(max(newVal, range.lowerBound), range.upperBound)
                    encodeParams(p)
                }
            ), format: .number)
            .frame(width: 80)
            .textFieldStyle(.roundedBorder)
            .font(TaxiwayTheme.monoSmall)
        }
    }

    private func stringParam<P: CheckParameters>(label: String, keyPath: WritableKeyPath<P, String>, options: [String]) -> some View {
        let params = decodeParams(P.self)
        let value = params?[keyPath: keyPath] ?? options.first ?? ""
        return Picker(label, selection: Binding(
            get: { value },
            set: { newVal in
                guard var p = params else { return }
                p[keyPath: keyPath] = newVal
                encodeParams(p)
            }
        )) {
            ForEach(options, id: \.self) { Text($0).tag($0) }
        }
        .font(TaxiwayTheme.monoSmall)
    }

    private func enumParam<P: CheckParameters, E: CaseIterable & RawRepresentable & Hashable>(
        label: String, keyPath: WritableKeyPath<P, E>
    ) -> some View where E.RawValue == String, E.AllCases: RandomAccessCollection {
        let params = decodeParams(P.self)
        let value = params?[keyPath: keyPath] ?? E.allCases.first!
        return Picker(label, selection: Binding(
            get: { value },
            set: { newVal in
                guard var p = params else { return }
                p[keyPath: keyPath] = newVal
                encodeParams(p)
            }
        )) {
            ForEach(Array(E.allCases), id: \.self) { c in
                Text(c.rawValue).tag(c)
            }
        }
        .font(TaxiwayTheme.monoSmall)
    }

    // MARK: - Composite Editors

    private func metadataMatchesEditor() -> some View {
        let params = decodeParams(MetadataFieldMatchesCheck.Parameters.self)
        return VStack(alignment: .leading, spacing: 8) {
            stringParam(label: "Field", keyPath: \MetadataFieldMatchesCheck.Parameters.fieldName,
                        options: ["title", "author", "subject", "keywords", "producer", "creator"])
            HStack {
                Text("Expected value")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("", text: Binding(
                    get: { params?.expectedValue ?? "" },
                    set: { newVal in
                        guard var p = params else { return }
                        p.expectedValue = newVal
                        encodeParams(p)
                    }
                ))
                .frame(width: 200)
                .textFieldStyle(.roundedBorder)
                .font(TaxiwayTheme.monoSmall)
            }
        }
    }

    private func pdfVersionEditor() -> some View {
        let params = decodeParams(PDFVersionCheck.Parameters.self)
        return VStack(alignment: .leading, spacing: 8) {
            enumParam(label: "Operator", keyPath: \PDFVersionCheck.Parameters.operator)
            HStack {
                Text("Version")
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                TextField("", text: Binding(
                    get: { params?.version ?? "1.7" },
                    set: { newVal in
                        guard var p = params else { return }
                        p.version = newVal
                        encodeParams(p)
                    }
                ))
                .frame(width: 80)
                .textFieldStyle(.roundedBorder)
                .font(TaxiwayTheme.monoSmall)
            }
        }
    }

    private func pageCountEditor() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            enumParam(label: "Operator", keyPath: \PageCountCheck.Parameters.operator)
            intParam(label: "Value", keyPath: \PageCountCheck.Parameters.value, range: 0...99999)
        }
    }

    private func pageSizeEditor() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            doubleParam(label: "Width (pt)", keyPath: \PageSizeCheck.Parameters.targetWidthPt, range: 0...5000)
            doubleParam(label: "Height (pt)", keyPath: \PageSizeCheck.Parameters.targetHeightPt, range: 0...5000)
            doubleParam(label: "Tolerance (pt)", keyPath: \PageSizeCheck.Parameters.tolerancePt, range: 0...100)
        }
    }

    private func colourSpaceEditor() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            enumParam(label: "Colour space", keyPath: \ColourSpaceUsedCheck.Parameters.colourSpace)
            enumParam(label: "Operator", keyPath: \ColourSpaceUsedCheck.Parameters.operator)
        }
    }

    private func fontTypeEditor() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            enumParam(label: "Font type", keyPath: \FontTypeCheck.Parameters.fontType)
            enumParam(label: "Operator", keyPath: \FontTypeCheck.Parameters.operator)
        }
    }

    private func fontSizeEditor() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            doubleParam(label: "Threshold (pt)", keyPath: \FontSizeCheck.Parameters.threshold, range: 0...1000)
            enumParam(label: "Operator", keyPath: \FontSizeCheck.Parameters.operator)
        }
    }

    private func resolutionRangeEditor() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            doubleParam(label: "Min PPI", keyPath: \ResolutionRangeCheck.Parameters.minPPI, range: 0...2400)
            doubleParam(label: "Max PPI", keyPath: \ResolutionRangeCheck.Parameters.maxPPI, range: 0...2400)
        }
    }

    private func imageColourModeEditor() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            enumParam(label: "Colour mode", keyPath: \ImageColourModeCheck.Parameters.colourMode)
            enumParam(label: "Operator", keyPath: \ImageColourModeCheck.Parameters.operator)
        }
    }

    private func imageTypeEditor() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            enumParam(label: "Compression", keyPath: \ImageTypeCheck.Parameters.compressionType)
            enumParam(label: "Operator", keyPath: \ImageTypeCheck.Parameters.operator)
        }
    }

    // MARK: - Encode / Decode

    private func decodeParams<P: CheckParameters>(_ type: P.Type) -> P? {
        try? JSONDecoder().decode(P.self, from: entry.parametersJSON)
    }

    private func encodeParams<P: CheckParameters>(_ params: P) {
        if let data = try? JSONEncoder().encode(params) {
            entry.parametersJSON = data
        }
    }
}
```

**Step 2: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace /Users/ruby/GitRepos/Taxiway/Taxiway.xcworkspace -scheme Taxiway -destination 'platform=macOS' build 2>&1 | grep -E "error:|BUILD"`
Expected: BUILD SUCCEEDED (view isn't used yet, but must compile)

**Step 3: Commit**

```bash
git add Taxiway/Views/ProfileEditor/ParameterEditorView.swift
git commit -m "feat: add ParameterEditorView with dynamic controls for all check types"
```

---

### Task 5: Create CheckDetailView for the right column

**Files:**
- Create: `Taxiway/Taxiway/Views/ProfileEditor/CheckDetailView.swift`

**Step 1: Create the view**

```swift
import SwiftUI
import TaxiwayCore

struct CheckDetailView: View {
    @Binding var entry: CheckEntry
    let readOnly: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TaxiwayTheme.sectionSpacing) {
                // Header
                Text(CheckMetadata.displayName(for: entry.typeID))
                    .font(TaxiwayTheme.monoLarge)

                Text(CheckMetadata.description(for: entry.typeID))
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)

                Divider()

                // Enable toggle
                Toggle("Enabled", isOn: $entry.enabled)
                    .disabled(readOnly)
                    .font(TaxiwayTheme.monoFont)

                // Severity
                Picker("Severity", selection: $entry.severityOverride) {
                    Text("Default").tag(CheckSeverity?.none)
                    ForEach(CheckSeverity.allCases, id: \.self) { severity in
                        Text(severity.rawValue.capitalized).tag(CheckSeverity?.some(severity))
                    }
                }
                .disabled(readOnly)
                .font(TaxiwayTheme.monoFont)

                Divider()

                // Parameters
                Text("Parameters")
                    .font(TaxiwayTheme.monoFont)
                    .foregroundStyle(.secondary)

                ParameterEditorView(entry: $entry, readOnly: readOnly)

                Spacer()
            }
            .padding(TaxiwayTheme.panelPadding)
        }
    }
}
```

**Step 2: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace /Users/ruby/GitRepos/Taxiway/Taxiway.xcworkspace -scheme Taxiway -destination 'platform=macOS' build 2>&1 | grep -E "error:|BUILD"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Taxiway/Views/ProfileEditor/CheckDetailView.swift
git commit -m "feat: add CheckDetailView for profile editor right column"
```

---

### Task 6: Rewrite ProfileEditorView as 3-column NavigationSplitView

**Files:**
- Rewrite: `Taxiway/Taxiway/Views/ProfileEditor/ProfileEditorView.swift`

**Step 1: Rewrite the view**

```swift
import SwiftUI
import TaxiwayCore

struct ProfileEditorView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(\.dismiss) var dismiss

    @State private var editedProfile: PreflightProfile?
    @State private var selectedCategory: CheckCategory?
    @State private var selectedCheckIndex: Int?
    @State private var saveError: String?

    private var isBuiltIn: Bool {
        editedProfile?.origin == .builtIn
    }

    var body: some View {
        Group {
            if editedProfile != nil {
                editorContent
            } else {
                ContentUnavailableView("No Profile Selected", systemImage: "doc.questionmark")
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .onAppear {
            editedProfile = coordinator.editingProfile
            selectedCategory = .file
        }
    }

    @ViewBuilder
    private var editorContent: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                if isBuiltIn {
                    Label("Read-only", systemImage: "lock.fill")
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(editedProfile?.name ?? "")
                    .font(TaxiwayTheme.monoFont)
                    .fontWeight(.semibold)
                Spacer()
                HStack(spacing: 8) {
                    if isBuiltIn {
                        Button("Duplicate") { duplicateProfile() }
                    }
                    Button("Cancel") { dismiss() }
                    Button("Save") { saveProfile() }
                        .buttonStyle(.borderedProminent)
                        .disabled(isBuiltIn)
                }
            }
            .padding(.horizontal, TaxiwayTheme.panelPadding)
            .padding(.vertical, 10)

            Divider()

            // 3-column layout
            NavigationSplitView {
                categorySidebar
                    .navigationSplitViewColumnWidth(min: 150, ideal: 170, max: 200)
            } content: {
                checksList
                    .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 320)
            } detail: {
                checkDetail
            }
        }
        .alert("Save Failed", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "Unknown error")
        }
    }

    // MARK: - Category Sidebar

    @ViewBuilder
    private var categorySidebar: some View {
        List(CheckCategory.allCases, id: \.self, selection: $selectedCategory) { category in
            HStack {
                Text(category.rawValue.capitalized)
                    .font(TaxiwayTheme.monoSmall)
                Spacer()
                let count = enabledCount(for: category)
                let total = totalCount(for: category)
                Text("\(count)/\(total)")
                    .font(TaxiwayTheme.monoSmall)
                    .foregroundStyle(.secondary)
            }
            .tag(category)
        }
        .onChange(of: selectedCategory) { _, _ in
            selectedCheckIndex = nil
        }
    }

    // MARK: - Checks List

    @ViewBuilder
    private var checksList: some View {
        if let category = selectedCategory, let profile = editedProfile {
            let indices = indicesForCategory(category, in: profile.checks)
            List(indices, id: \.self, selection: $selectedCheckIndex) { index in
                let entry = profile.checks[index]
                HStack(spacing: 8) {
                    Circle()
                        .fill(entry.enabled ? severityColor(entry.severityOverride) : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text(CheckMetadata.displayName(for: entry.typeID))
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(entry.enabled ? .primary : .secondary)
                    Spacer()
                    if !entry.enabled {
                        Text("OFF")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(index)
            }
        } else {
            ContentUnavailableView("Select a Category", systemImage: "sidebar.left")
        }
    }

    // MARK: - Check Detail

    @ViewBuilder
    private var checkDetail: some View {
        if let index = selectedCheckIndex, var profile = editedProfile,
           index < profile.checks.count {
            CheckDetailView(
                entry: Binding(
                    get: { editedProfile!.checks[index] },
                    set: { newEntry in editedProfile?.checks[index] = newEntry }
                ),
                readOnly: isBuiltIn
            )
        } else {
            ContentUnavailableView("Select a Check", systemImage: "checklist")
        }
    }

    // MARK: - Helpers

    private func indicesForCategory(_ category: CheckCategory, in checks: [CheckEntry]) -> [Int] {
        checks.enumerated().compactMap { index, entry in
            CheckMetadata.category(for: entry.typeID) == category.rawValue ? index : nil
        }
    }

    private func enabledCount(for category: CheckCategory) -> Int {
        guard let profile = editedProfile else { return 0 }
        return indicesForCategory(category, in: profile.checks)
            .filter { profile.checks[$0].enabled }
            .count
    }

    private func totalCount(for category: CheckCategory) -> Int {
        guard let profile = editedProfile else { return 0 }
        return indicesForCategory(category, in: profile.checks).count
    }

    private func severityColor(_ severity: CheckSeverity?) -> Color {
        switch severity {
        case .error: TaxiwayTheme.statusError
        case .warning: TaxiwayTheme.statusWarning
        case .info: .blue
        case nil: TaxiwayTheme.statusWarning
        }
    }

    private func duplicateProfile() {
        guard let original = editedProfile else { return }
        let copy = original.duplicate(name: "Copy of \(original.name)")
        do {
            try ProfileStorage().save(copy)
            editedProfile = copy
            coordinator.editingProfile = copy
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func saveProfile() {
        guard let profile = editedProfile else { return }
        do {
            try ProfileStorage().save(profile)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
```

**Step 2: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace /Users/ruby/GitRepos/Taxiway/Taxiway.xcworkspace -scheme Taxiway -destination 'platform=macOS' build 2>&1 | grep -E "error:|BUILD"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Taxiway/Views/ProfileEditor/ProfileEditorView.swift
git commit -m "feat: rewrite ProfileEditorView as 3-column NavigationSplitView"
```

---

## Phase 3: Report PDF Preview

### Task 7: Create PDFPreviewView with highlighting overlay

**Files:**
- Create: `Taxiway/Taxiway/Views/Report/PDFPreviewView.swift`

**Step 1: Create the view**

This renders a PDF page via PDFKit and overlays highlight rects for affected items.

```swift
import SwiftUI
import PDFKit
import TaxiwayCore

struct PDFPreviewView: View {
    let pdfURL: URL?
    let affectedItems: [AffectedItem]
    let highlightColor: Color

    @State private var currentPageIndex: Int = 0

    private var affectedPageIndices: [Int] {
        let indices = affectedItems.compactMap { item -> Int? in
            switch item {
            case .document: return 0
            case .page(let index): return index
            case .annotation(_, let page, _): return page
            case .image(_, let page): return page
            case .font(_, let pages): return pages.first
            case .colourSpace(_, let pages): return pages.first
            }
        }
        return Array(Set(indices)).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            if let url = pdfURL, let pdfDoc = PDFDocument(url: url) {
                // Page navigation
                if affectedPageIndices.count > 1 {
                    pageNavigationBar(total: pdfDoc.pageCount)
                    Divider()
                }

                // PDF page with overlay
                GeometryReader { geo in
                    if let page = pdfDoc.page(at: currentPageIndex) {
                        let pageBounds = page.bounds(for: .mediaBox)
                        let scale = min(
                            geo.size.width / pageBounds.width,
                            geo.size.height / pageBounds.height
                        )
                        let scaledWidth = pageBounds.width * scale
                        let scaledHeight = pageBounds.height * scale

                        ZStack {
                            // PDF page thumbnail
                            PDFPageView(page: page)
                                .frame(width: scaledWidth, height: scaledHeight)

                            // Highlight overlays
                            ForEach(Array(overlayRects(for: currentPageIndex, pageBounds: pageBounds, scale: scale).enumerated()), id: \.offset) { _, rect in
                                Rectangle()
                                    .fill(highlightColor.opacity(0.25))
                                    .border(highlightColor, width: 2)
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.midX, y: rect.midY)
                            }
                        }
                        .frame(width: scaledWidth, height: scaledHeight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            } else {
                ContentUnavailableView("PDF Not Available", systemImage: "doc.questionmark",
                    description: Text("Could not load the PDF file."))
            }
        }
        .onAppear {
            currentPageIndex = affectedPageIndices.first ?? 0
        }
        .onChange(of: affectedItems) { _, _ in
            currentPageIndex = affectedPageIndices.first ?? 0
        }
    }

    private func pageNavigationBar(total: Int) -> some View {
        HStack {
            Button {
                if let idx = affectedPageIndices.firstIndex(of: currentPageIndex), idx > 0 {
                    currentPageIndex = affectedPageIndices[idx - 1]
                }
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(currentPageIndex == affectedPageIndices.first)

            Text("Page \(currentPageIndex + 1) of \(total)")
                .font(TaxiwayTheme.monoSmall)

            Button {
                if let idx = affectedPageIndices.firstIndex(of: currentPageIndex),
                   idx < affectedPageIndices.count - 1 {
                    currentPageIndex = affectedPageIndices[idx + 1]
                }
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(currentPageIndex == affectedPageIndices.last)
        }
        .padding(.vertical, 6)
    }

    private func overlayRects(for pageIndex: Int, pageBounds: CGRect, scale: CGFloat) -> [CGRect] {
        affectedItems.compactMap { item -> CGRect? in
            switch item {
            case .annotation(_, let page, let bounds) where page == pageIndex:
                if let b = bounds {
                    // Convert from PDF coordinates (origin bottom-left) to view coordinates (origin top-left)
                    let x = b.x * scale
                    let y = (pageBounds.height - b.y - b.height) * scale
                    return CGRect(x: x, y: y, width: b.width * scale, height: b.height * scale)
                }
                // No bounds — highlight full page
                return CGRect(x: 0, y: 0, width: pageBounds.width * scale, height: pageBounds.height * scale)

            case .page(let index) where index == pageIndex:
                return CGRect(x: 0, y: 0, width: pageBounds.width * scale, height: pageBounds.height * scale)

            case .image(_, let page) where page == pageIndex:
                return CGRect(x: 0, y: 0, width: pageBounds.width * scale, height: pageBounds.height * scale)

            case .document where pageIndex == 0:
                return CGRect(x: 0, y: 0, width: pageBounds.width * scale, height: pageBounds.height * scale)

            default:
                return nil
            }
        }
    }
}

// MARK: - PDFPageView (NSViewRepresentable)

struct PDFPageView: NSViewRepresentable {
    let page: PDFPage

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displaysPageBreaks = false
        pdfView.isEditable = false
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        pdfView.document = doc
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        pdfView.document = doc
    }
}
```

**Step 2: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace /Users/ruby/GitRepos/Taxiway/Taxiway.xcworkspace -scheme Taxiway -destination 'platform=macOS' build 2>&1 | grep -E "error:|BUILD"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Taxiway/Views/Report/PDFPreviewView.swift
git commit -m "feat: add PDFPreviewView with page rendering and highlight overlays"
```

---

### Task 8: Update ResultDetailView to include PDF preview

**Files:**
- Rewrite: `Taxiway/Taxiway/Views/Report/ResultDetailView.swift`

**Step 1: Rewrite to split into preview + info**

```swift
import SwiftUI
import TaxiwayCore

struct ResultDetailView: View {
    let result: CheckResult
    let pdfURL: URL?

    var body: some View {
        VSplitView {
            // Top: PDF preview
            PDFPreviewView(
                pdfURL: pdfURL,
                affectedItems: result.affectedItems,
                highlightColor: highlightColor
            )
            .frame(minHeight: 200)

            // Bottom: Result info
            ScrollView {
                VStack(alignment: .leading, spacing: TaxiwayTheme.sectionSpacing) {
                    // Status badge and check name
                    HStack(spacing: 10) {
                        statusBadge
                        VStack(alignment: .leading, spacing: 2) {
                            Text(CheckMetadata.displayName(for: result.checkTypeID))
                                .font(TaxiwayTheme.monoLarge)
                            Text(result.checkTypeID)
                                .font(TaxiwayTheme.monoSmall)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    // Severity
                    HStack(spacing: 6) {
                        Text("Severity:")
                            .font(TaxiwayTheme.monoSmall)
                            .foregroundStyle(.secondary)
                        Text(severityLabel)
                            .font(TaxiwayTheme.monoSmall)
                            .foregroundStyle(severityColor)
                    }

                    // Message
                    Text(result.message)
                        .font(TaxiwayTheme.monoFont)

                    // Detail
                    if let detail = result.detail {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Detail")
                                .font(TaxiwayTheme.monoSmall)
                                .foregroundStyle(.secondary)
                            Text(detail)
                                .font(TaxiwayTheme.monoFont)
                                .textSelection(.enabled)
                        }
                    }

                    // Affected items
                    if !result.affectedItems.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Affected Items")
                                .font(TaxiwayTheme.monoSmall)
                                .foregroundStyle(.secondary)

                            ForEach(Array(result.affectedItems.enumerated()), id: \.offset) { _, item in
                                Text(descriptionFor(item))
                                    .font(TaxiwayTheme.monoFont)
                            }
                        }
                    }
                }
                .padding(TaxiwayTheme.panelPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 150)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        Text(result.status.rawValue.uppercased())
            .font(TaxiwayTheme.monoSmall)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(.white)
            .background(statusColor, in: RoundedRectangle(cornerRadius: 4))
    }

    private var statusColor: Color {
        switch result.status {
        case .pass: TaxiwayTheme.statusPass
        case .fail: TaxiwayTheme.statusError
        case .warning: TaxiwayTheme.statusWarning
        case .skipped: TaxiwayTheme.statusSkipped
        }
    }

    private var highlightColor: Color {
        switch result.status {
        case .fail: TaxiwayTheme.statusError
        case .warning: TaxiwayTheme.statusWarning
        case .pass: TaxiwayTheme.statusPass
        case .skipped: TaxiwayTheme.statusSkipped
        }
    }

    private var severityLabel: String {
        switch result.severity {
        case .error: "Error"
        case .warning: "Warning"
        case .info: "Info"
        }
    }

    private var severityColor: Color {
        switch result.severity {
        case .error: TaxiwayTheme.statusError
        case .warning: TaxiwayTheme.statusWarning
        case .info: .secondary
        }
    }

    private func descriptionFor(_ item: AffectedItem) -> String {
        switch item {
        case .document:
            "Document"
        case .page(let index):
            "Page \(index + 1)"
        case .font(let name, let pages):
            "Font: \(name) (pages \(pages.map { String($0 + 1) }.joined(separator: ", ")))"
        case .image(let id, let page):
            "Image \(id) (page \(page + 1))"
        case .colourSpace(let name, let pages):
            "Colour space: \(name) (pages \(pages.map { String($0 + 1) }.joined(separator: ", ")))"
        case .annotation(let type, let page, _):
            "\(type) annotation (page \(page + 1))"
        }
    }
}
```

**Step 2: Update ReportView to pass pdfURL**

In `Taxiway/Taxiway/Views/Report/ReportView.swift`, change the detail block from:

```swift
ResultDetailView(result: selected)
```

To:

```swift
ResultDetailView(result: selected, pdfURL: report.documentURL)
```

**Step 3: Update ResultsListView to use human-readable names**

In `Taxiway/Taxiway/Views/Report/ResultsListView.swift`, change line 19 from:

```swift
Text(result.checkTypeID)
```

To:

```swift
Text(CheckMetadata.displayName(for: result.checkTypeID))
```

**Step 4: Build to verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace /Users/ruby/GitRepos/Taxiway/Taxiway.xcworkspace -scheme Taxiway -destination 'platform=macOS' build 2>&1 | grep -E "error:|BUILD"`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Taxiway/Views/Report/ResultDetailView.swift Taxiway/Views/Report/ReportView.swift Taxiway/Views/Report/ResultsListView.swift
git commit -m "feat: add PDF preview with highlighting to report detail view"
```

---

## Phase 4: Final Integration

### Task 9: Build, test, and verify end-to-end

**Step 1: Run TaxiwayCore tests**

Run: `cd /Users/ruby/GitRepos/Taxiway/TaxiwayCore && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test`
Expected: All 459+ tests pass

**Step 2: Build app**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -workspace /Users/ruby/GitRepos/Taxiway/Taxiway.xcworkspace -scheme Taxiway -destination 'platform=macOS' build 2>&1 | grep -E "error:|BUILD"`
Expected: BUILD SUCCEEDED

**Step 3: Fix any compilation errors**

Address errors one by one. Common issues:
- Missing `CaseIterable` conformance on enums used with `enumParam` — add it to the enum in TaxiwayCore
- `parametersJSON` not being `var` — it already is in CheckEntry
- Mismatched parameter struct field names — check the actual struct definitions

**Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve compilation errors in editor and preview integration"
```
