# Taxiway MVP Design

**Date:** 2026-02-28
**Status:** Approved

---

## Scope Decisions

- **Engine-first** — full parser and check system, light-themed UI
- **All 8 check categories**, skip content-stream parsing, ink coverage, and overprint (~35 checks)
- **Full profiles** — 4 built-ins + editor + `.taxiprofile` import/export
- **Full report export** — PDF summary, JSON, CSV
- **Light theming** — dark panel + monospace aesthetic respecting system light/dark mode, no skeuomorphism
- **Deferred:** batch processing, CLI tool, localisation, content stream parsing, ink coverage, overprint detection

---

## 1. Architecture

**Approach:** Local Swift Package (`TaxiwayCore`) + thin SwiftUI app shell.

TaxiwayCore contains parser, checks, engine, profiles, and reports. No UIKit/SwiftUI dependencies. The app target imports TaxiwayCore and handles views only.

```
TaxiwayCore/
    Package.swift
    Sources/TaxiwayCore/
        Parser/
            PDFDocumentParser.swift
            PageGeometry.swift
            FontExtractor.swift
            ImageExtractor.swift
            ColourExtractor.swift
            MetadataExtractor.swift
            AnnotationExtractor.swift
            Models/          (TaxiwayDocument, FontInfo, ImageInfo, etc.)
        Checks/
            CheckProtocol.swift
            CheckResult.swift
            CheckSeverity.swift
            CheckRegistry.swift
            Implementations/
                File/  PDF/  Pages/  Marks/  Colour/  Fonts/  Images/  Lines/
        Engine/
            PreflightEngine.swift
            PreflightProfile.swift
            PreflightReport.swift
            ProfileStorage.swift
            ReportExporter.swift
    Tests/TaxiwayCoreTests/
        ParserTests/
        CheckTests/
        EngineTests/

Taxiway/  (app target)
    App/
        TaxiwayApp.swift
        AppCoordinator.swift
    Views/
        Dashboard/  Report/  Inspector/  ProfileEditor/  Settings/
    ViewModels/
    Theme/
        TaxiwayTheme.swift
```

**Key decisions:**

- `TaxiwayDocument` is an immutable struct — parser produces it, engine reads it.
- Check Codable round-tripping via `CheckRegistry` mapping string type IDs to concrete types. Profiles store `[CheckEntry]` with encoded parameters, not type-erased `[any Check]`.
- Public API is narrow: `PDFDocumentParser.parse(url:)`, `PreflightEngine.run(profile:on:)`, and model types.

---

## 2. Parser

Produces a `TaxiwayDocument` from a URL. Uses PDFKit for high-level access, CGPDF for resource dictionaries and page-level detail.

```swift
struct TaxiwayDocument: Codable, Sendable {
    let fileInfo: FileInfo
    let documentInfo: DocumentInfo
    let pages: [PageInfo]
    let fonts: [FontInfo]
    let images: [ImageInfo]
    let colourSpaces: [ColourSpaceInfo]
    let spotColours: [SpotColourInfo]
    let annotations: [AnnotationInfo]
    let metadata: DocumentMetadata
    let parseWarnings: [ParseWarning]
}
```

**Extractors:**

| Extractor | Source | Edge cases |
|---|---|---|
| PageGeometry | CGPDF page dict | Missing boxes (TrimBox defaults to MediaBox), rotation |
| FontExtractor | CGPDF resource dict/page | Fonts in Form XObjects, subset prefix, CIDFont |
| ImageExtractor | CGPDF image XObjects | Soft masks, image matrices for PPI calc. Inline images deferred. |
| ColourExtractor | CGPDF resource dict | DeviceGray/RGB/CMYK, ICCBased, Separation, DeviceN, Indexed |
| MetadataExtractor | PDFKit attrs + XMP | Malformed XMP, missing OutputIntent, C2PA via XMP |
| AnnotationExtractor | PDFKit annotations | Link vs widget vs markup subtypes |

**Strategy:** Single pass per page. Errors in one extractor don't abort the parse — partial failures recorded in `parseWarnings`.

---

## 3. Check System

```swift
protocol Check: Identifiable, Sendable {
    static var typeID: String { get }
    var id: UUID { get }
    var name: String { get }
    var category: CheckCategory { get }
    var defaultSeverity: CheckSeverity { get }
    var parameters: any CheckParameters { get set }
    func run(on document: TaxiwayDocument) -> CheckResult
}

protocol CheckParameters: Codable, Sendable {}
```

**CheckResult:**

```swift
struct CheckResult: Codable, Sendable {
    let checkID: UUID
    let checkTypeID: String
    let status: CheckStatus          // pass, fail, warning, skipped
    let severity: CheckSeverity      // may differ from default via profile override
    let message: String
    let detail: String?
    let affectedItems: [AffectedItem]
}

enum AffectedItem: Codable, Sendable {
    case page(index: Int)
    case font(name: String, pages: [Int])
    case image(id: String, page: Int)
    case colourSpace(name: String, pages: [Int])
    case annotation(type: String, page: Int)
    case document
}
```

**MVP inventory (~35 checks):**

| Category | Included | Deferred |
|---|---|---|
| File (6) | File size max/min, Encryption, Interactive elements, Metadata present/matches | — |
| PDF (6) | PDF version, PDF/X conformance, Linearized, Tagged, Layers, Annotations present | All Text Outlined, Transparency (content stream) |
| Pages (4) | Page count, Page size matches, Mixed sizes, Non-zero rotation | — |
| Marks (6) | Bleed zero/non-zero/less-than/greater-than/non-uniform, Trim box set | — |
| Colour (4) | Colour space used, Registration colour, Spot colour used, Spot count exceeds | Rich Black, Named colour in gradient (content stream) |
| Fonts (3) | Not embedded, Font type, Font size below/above | — |
| Images (10) | Image type, Colour mode, Resolution below/above/range, Scaled, Scaled non-proportionally, ICC missing/override, Alpha, Blend mode, Opacity, C2PA, GenAI metadata | — |
| Lines (2) | Stroke weight below, Zero-width stroke (best-effort from graphics state defaults) | — |

---

## 4. Engine, Profiles & Reports

**PreflightEngine** is stateless:

```swift
struct PreflightEngine {
    func run(profile: PreflightProfile, on document: TaxiwayDocument) -> PreflightReport
    func run(profile: PreflightProfile, on document: TaxiwayDocument,
             progress: @Sendable (CheckProgress) -> Void) async -> PreflightReport
}
```

**PreflightProfile:**

```swift
struct PreflightProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var entries: [CheckEntry]
    var createdAt: Date
    var modifiedAt: Date
    let isBuiltIn: Bool
}

struct CheckEntry: Codable {
    let checkTypeID: String
    var enabled: Bool
    var severityOverride: CheckSeverity?
    var parametersJSON: Data
}
```

**Built-in profiles (4, read-only):**
- PDF/X-1a — CMYK press, no RGB, fonts embedded, no transparency, trim box set
- PDF/X-4 — Modern press, transparency OK, fonts embedded, trim box set
- Screen / Digital — RGB OK, no bleed required, basic sanity
- Loose — Minimal: file size cap, encryption check, page count sanity

**Storage:** JSON in `~/Library/Application Support/Taxiway/Profiles/`. Built-ins bundled in app resources.

**Import/export:** `.taxiprofile` files (JSON, versioned). Unknown check types preserved but disabled.

**PreflightReport:**

```swift
struct PreflightReport: Identifiable, Codable {
    let id: UUID
    let documentURL: URL
    let profileID: UUID
    let profileName: String
    let runAt: Date
    let duration: TimeInterval
    let overallStatus: CheckStatus
    let results: [CheckResult]
    let documentSnapshot: TaxiwayDocument
}
```

`overallStatus` is `pass` only if zero errors. Warnings alone don't block pass.

**Export:** JSON (full report), CSV (flat check results table), PDF summary (header + results table + metadata).

---

## 5. UI

Single-window app. `AppCoordinator` (`@Observable`) drives navigation: `.dashboard` / `.running` / `.report`.

**Theme — system-adaptive:**
- Dark mode: charcoal backgrounds (#1C1C1E range), warm white/cream text, vivid status colours
- Light mode: warm off-white backgrounds, dark charcoal text, slightly muted status colours
- Semantic colour tokens in `TaxiwayTheme` resolved via `@Environment(\.colorScheme)` — no hardcoded hex in views
- Typography: SF Mono for values/identifiers, SF Pro for labels
- Category tiles: rounded rectangles with status-colour glow. Dark/unlit when not run.
- Panel-like grouping with subtle dividers. Structured, instrument-like, not skeuomorphic.

**Navigation flow:**
1. Dashboard — drop zone, profile picker, recent files, Run button
2. Running — brief interstitial with per-category progress
3. Report — status header, category tiles, results list, inspector sidebar, export controls
4. Profile Editor — separate sheet/window

**Views:** Dashboard (drop zone, profile picker, recent files), Report (status header, category tiles, results list, result detail, export), Inspector (collapsible sidebar: doc info, pages, fonts, images, colours), ProfileEditor (check toggles grouped by category, metadata fields), Settings.

---

## 6. Testing

| Layer | Approach | Edge cases |
|---|---|---|
| Parser | Integration tests against real PDF corpus in `TestFixtures/` | Encrypted PDFs, zero-page docs, missing boxes, PDF 1.3-2.0, malformed XMP |
| Checks | Unit tests with synthetic `TaxiwayDocument` fixtures. Min 3 per check: pass, fail, edge. | Empty pages, zero fonts, nil optionals, boundary values |
| Engine | Unit tests for aggregation, severity overrides, progress reporting | Empty profile, all-disabled, single-check |
| Profiles | Encode/decode round-trip, unknown type handling | Corrupt JSON, future versions, duplicate IDs |
| Reports | Snapshot tests (JSON), format validation (CSV/PDF) | Zero results, 1000+ results |
