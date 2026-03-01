# Taxiway – Technical Specification

**Version:** 0.1 (pre-development)  
**Platform:** macOS 14.0+  
**Language:** Swift 6  
**Status:** Planning

---

## 1. Overview

Taxiway is a native macOS PDF preflight application. It parses PDF files against user-defined check profiles and produces structured preflight reports. The application is non-destructive in its current stage — it reads and reports only.

A second stage (Taxiway Fix) will add automated and manual PDF correction. The architecture of Stage 1 must accommodate this without requiring significant refactoring.

---

## 2. Architecture

### 2.1 Layer Separation

```
┌─────────────────────────────────┐
│         SwiftUI (UI Layer)      │
├─────────────────────────────────┤
│     App Layer (Coordinators,    │
│     State, Profile Management)  │
├─────────────────────────────────┤
│    Check Engine (Profile        │
│    execution, Result assembly)  │
├─────────────────────────────────┤
│    PDF Parser (Document model,  │
│    resource extraction)         │
├─────────────────────────────────┤
│  PDFKit / CoreGraphics / CGPDF  │
└─────────────────────────────────┘
```

The PDF Parser and Check Engine are implemented as a Swift Package (`TaxiwayCore`) with no UIKit or SwiftUI dependencies. This keeps them independently testable and leaves the door open for a CLI tool or future platform targets.

### 2.2 TaxiwayCore Package

```
TaxiwayCore/
    Sources/
        Parser/
            PDFDocument+Taxiway.swift
            PageGeometry.swift
            FontExtractor.swift
            ImageExtractor.swift
            ColourExtractor.swift
            MetadataExtractor.swift
            AnnotationExtractor.swift
        Checks/
            CheckProtocol.swift
            CheckResult.swift
            CheckSeverity.swift
            Checks/
                File/
                Color/
                Fonts/
                Images/
                Lines/
                Marks/
                PDF/
                Pages/
        Engine/
            PreflightEngine.swift
            PreflightProfile.swift
            PreflightReport.swift
    Tests/
        ParserTests/
        CheckTests/
        EngineTests/
```

### 2.3 Main App Target

```
Taxiway/
    App/
        TaxiwayApp.swift
        AppCoordinator.swift
    Views/
        Dashboard/
        Inspector/
        Report/
        ProfileEditor/
        Settings/
    ViewModels/
    Models/
        AppState.swift
    Resources/
        Assets.xcassets
        Localizable.strings
```

---

## 3. PDF Parsing

### 3.1 Primary Framework

PDFKit is the primary parsing layer. CGPDF APIs are used for lower-level access where PDFKit doesn't expose sufficient detail (e.g. content streams, resource dictionaries, inline images).

### 3.2 Document Model

The parser produces a `TaxiwayDocument` — an immutable snapshot of everything extracted from the PDF. The Check Engine operates only on this model, never on the raw PDF directly.

```swift
struct TaxiwayDocument {
    let fileInfo: FileInfo
    let documentInfo: DocumentInfo
    let pages: [PageInfo]
    let fonts: [FontInfo]
    let images: [ImageInfo]
    let colourSpaces: [ColourSpaceInfo]
    let spotColours: [SpotColourInfo]
    let annotations: [AnnotationInfo]
    let metadata: DocumentMetadata
}
```

### 3.3 Parsing Scope

| Domain | Source |
|---|---|
| File size, encryption | FileManager / PDFKit |
| PDF version, linearization | PDFKit document attributes / raw header |
| PDF/X, PDF/A conformance | XMP metadata, OutputIntents |
| Page geometry (MediaBox, TrimBox, BleedBox, ArtBox) | CGPDF page dictionary |
| Font names, types, embedding | CGPDF resource dictionary |
| Image resolution, mode, type, ICC | CGPDF image XObjects |
| Colour spaces (per page, per object) | CGPDF resource dictionary |
| Spot colours | Separation and DeviceN colour spaces |
| Overprint settings | CGPDF graphics state |
| Ink coverage | Rendered pixel sampling (approximate) |
| Annotations | PDFKit / CGPDF |
| XMP / document metadata | PDFKit / XMLParser |
| Content Credentials / C2PA | XMP packet parsing |

### 3.4 Parsing Limitations (Stage 1)

- Ink coverage is approximated via rasterisation at a fixed low resolution. Exact values require a RIP and are out of scope.
- Some checks (e.g. named colour in gradient) require content stream parsing, which will be implemented progressively.
- Password-protected documents are not supported in Stage 1.

---

## 4. Check System

### 4.1 Check Protocol

```swift
protocol Check: Identifiable, Codable {
    var id: UUID { get }
    var name: String { get }
    var category: CheckCategory { get }
    var severity: CheckSeverity { get }  // error, warning, info
    var parameters: CheckParameters { get set }
    
    func run(on document: TaxiwayDocument) -> CheckResult
}
```

### 4.2 Check Result

```swift
struct CheckResult {
    let checkID: UUID
    let status: CheckStatus  // pass, fail, warning, skipped
    let affectedItems: [AffectedItem]  // page numbers, font names, image refs, etc.
    let message: String
    let detail: String?
}
```

### 4.3 Severity

Each check has a default severity. Profiles can override severity per check.

- **Error** — job should not proceed. Shown in red. Blocks pass/fail status.
- **Warning** — potential issue, review recommended. Shown in amber.
- **Info** — informational only, no action required. Shown in grey.

### 4.4 Check Categories and Inventory

#### File
| Check | Parameters |
|---|---|
| File Size (max) | X MB |
| File Size (min) | X MB |
| Encryption | — |
| Interactive Elements Present | — |
| Metadata Field Present | Field name |
| Metadata Field Matches | Field name, expected value |

#### PDF
| Check | Parameters |
|---|---|
| PDF Version | Operator (is/is not), version string |
| PDF/X Conformance | Standard (X-1a, X-3, X-4, X-4p) |
| PDF/A Conformance | Standard (A-1b, A-2b, A-3b) |
| Linearized | Is/Is Not |
| Tagged | Is/Is Not |
| All Text Outlined | Is/Is Not |
| Transparency Used | — |
| Layers Present | — |
| Annotations Present | — |

#### Pages
| Check | Parameters |
|---|---|
| Page Count | Operator, value |
| Page Size Matches | Tolerance, target size |
| Mixed Page Sizes | — |
| Non-Zero Rotation Present | — |
| Trim Box Set | — |
| Bleed Box Set | — |

#### Marks & Bleed
| Check | Parameters |
|---|---|
| Bleed is Zero | — |
| Bleed is Non-Zero | — |
| Bleed Less Than | X mm |
| Bleed Non-Zero and Less Than | X mm |
| Bleed Greater Than | X mm |
| Bleed Non-Uniform | Tolerance |

#### Colour
| Check | Parameters |
|---|---|
| Colour Space Used | Operator, space name |
| Registration Colour Used | — |
| Spot Colour Used | — |
| Spot Colour Count Exceeds | X |
| Unnamed Spot Colour Present | — |
| Rich Black Used | — |
| Overprint Fill Used | — |
| Overprint Stroke Used | — |
| Overprint Text Used | — |
| White Overprint Used | — |
| Named Colour in Gradient | — |
| Ink Coverage Exceeds | X% |
| Ink Coverage Below | X% |

#### Fonts
| Check | Parameters |
|---|---|
| Font Used and Not Embedded | — |
| Font Type Used | Operator, type name |
| Font Size Below | X pt |
| Font Size Above | X pt |

#### Images
| Check | Parameters |
|---|---|
| Image Type | Operator, type (JPEG, JPEG2000, JBIG2, CCITT, Flate) |
| Image Colour Mode | Operator, mode |
| Resolution Below | X PPI |
| Resolution Above | X PPI |
| Resolution Out of Range | Min PPI, Max PPI |
| Image Scaled | Tolerance % |
| Image Scaled Non-Proportionally | Tolerance % |
| ICC Profile Missing | — |
| ICC Profile Override Present | — |
| Alpha Channel Present | — |
| Non-Normal Blend Mode | — |
| Opacity Not 100% | — |
| Content Credentials Present | — |
| GenAI Metadata Detected | — |

#### Lines
| Check | Parameters |
|---|---|
| Stroke Weight Below | X pt |
| Zero-Width Stroke Present | — |

### 4.5 Check Parameters

Parameters are typed and Codable. Each check defines its own parameter struct. The profile editor generates UI from these dynamically — no hardcoded form layouts per check type.

---

## 5. Preflight Profiles

### 5.1 Data Model

```swift
struct PreflightProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var checks: [any Check]
    var createdAt: Date
    var modifiedAt: Date
}
```

Profiles are stored as JSON in `~/Library/Application Support/Taxiway/Profiles/`.

### 5.2 Built-in Profiles

A set of read-only built-in profiles ship with the app:

- **PDF/X-1a** — CMYK press, no transparency, fully embedded
- **PDF/X-4** — Modern press, transparency allowed
- **Screen / Digital** — RGB, no bleed required
- **Loose** — Minimal checks, good for quick sanity pass

Built-ins cannot be edited. They can be duplicated to create user profiles.

### 5.3 Profile Import / Export

Profiles export as `.taxiprofile` (JSON, versioned). Import via drag-and-drop or File menu.

---

## 6. Report

### 6.1 Report Model

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

### 6.2 Report Export

- **PDF Summary** — one-page report with pass/fail status, check table, document metadata
- **JSON** — full machine-readable report for integration with other tools
- **CSV** — flat table of check results

---

## 7. UI

### 7.1 Design Language

The UI is skeuomorphic, modelled on aircraft overhead instrumentation panels — specifically the 737 and A320 overhead panels. The goal is an interface that is visually distinctive and genuinely fun to use, while remaining more readable than a standard flat UI, not less. The metaphor serves the function: every visual element maps to a real preflight concept.

**Core visual characteristics:**
- Dark charcoal/near-black base panel, subtly textured to suggest brushed metal or moulded composite
- Backlit engraved labels — cream or warm white lettering that reads as if lit from behind, suggesting machined aluminium legend plates
- Status colours follow aviation annunciator convention strictly: green (pass), amber (warning), red (error/fail), unlit/dark (not run or not applicable). No other status colours.
- Monospaced or technical-weight typefaces for values, measurements, and identifiers
- Subtle bevel and inner glow on interactive elements — buttons have physical depth and light up when active
- Structural panel lines and recessed dividers between sections, suggesting physical subsystem groupings
- Wiring and connector detail as decorative elements between major panel sections — suggests physical cable runs between instrument clusters

**Key UI components:**

*Annunciator tiles* — the primary check result display. A grid of rectangular backlit buttons, one per check category. Each tile shows the category name in engraved label style and glows according to its worst result. Dark if the category has no enabled checks. Clicking a glowing tile opens that category's detail. This is the heart of the report view.

*Master Caution indicator* — a large panel element prominently positioned in the report view. Shows overall pass/fail status. Glows green (all clear) or red (faults present). Should feel weighty and satisfying. Directly references the master warning/caution annunciators on a real flight deck.

*Solari board (split-flap display)* — used for the issues list. Individual check failures and warnings are displayed as rows in a split-flap mechanical departure board aesthetic: dark background, white/cream characters on flap segments, with the characteristic staggered-reveal animation when results populate. Each row shows check name, severity, and a brief description. The mechanical flip animation plays as checks complete during a preflight run, giving the result feed a tangible, satisfying quality distinct from a plain scrolling list. Rows are grouped by severity (errors first, then warnings), and selecting a row expands an inset detail panel showing affected items.

*Analog gauges* — used for continuous numeric results (ink coverage, image resolution range). Circular instruments with needles, marked with green/amber/red zones. More immediately readable at a glance than a bar or number alone.

*Rocker switches* — used in the profile editor for enabling/disabling individual checks. Two-position rockers with a lit indicator pip in the active position. Guarded switches (flip-up cover) are reserved for Stage 2 destructive fix operations — present but physically locked in Stage 1.

*Parameter inputs* — styled as panel-mounted controls: rotary selector knobs for enum choices, inset seven-segment numeric displays for values, small backlit toggles for boolean options.

*Data plates* — small recessed label panels used for static information display: file name, profile name, run timestamp. Styled as the information placards found on real aircraft panels.

The aesthetic reference for "skeuomorphic that still feels like a Mac app" is early Panic software (Coda, Transmit 4). The reference for the instrument aesthetic is the 737NG overhead panel and the A320 overhead panel. Neither should dominate — the result should feel like a Mac app that loves aviation, not a flight simulator.

### 7.2 Core Views

**Dashboard**
- Central drop zone styled as an instrument bay aperture with a dashed panel border — accepts PDF via drag-and-drop or file picker
- Recent files displayed as a compact data-plate list
- Profile selector styled as a rotary selector switch with detents

**Preflight Run View**
- Annunciator tiles cycle through a dim "running" state (slow pulse) as their category is being checked
- Solari board populates row by row as checks complete, with the characteristic flip animation per row
- Tiles lock to their final status colour as each category finishes
- Master Caution indicator resolves last, with a brief hold before lighting

**Report View**
- Master Caution indicator at top
- Annunciator grid below — one tile per category
- Solari board panel occupying the main content area — the full issues list, errors before warnings
- Selecting a Solari row expands an inset detail panel (recessed, like a pull-out instrument tray) showing affected items: page numbers, font names, image references
- Analog gauge cluster for ink coverage and any other continuous metrics
- Inspector strip along one edge styled as a data readout panel (see Inspector Panel below)
- Export controls in a recessed button cluster at the bottom of the panel

**Profile Editor**
- Panel of rocker switches grouped by category, separated by structural dividers
- Each switch row expands on enable to reveal parameter controls inset below it
- Profile name and description fields styled as editable data plates
- Built-in profiles displayed as non-interactive reference panels — switches visible but covered by a transparent guard panel with "READ ONLY" legend plate

**Inspector Panel** (collapsible sidebar, available during report review)
- Full document metadata
- Page list with geometry details
- Font inventory
- Colour space and spot colour list
- Image inventory
- Styled as a secondary co-pilot instrument panel — same visual language as the main panel but narrower and lower contrast, subordinate to the main view

### 7.3 Animation and Motion

The Solari board flip animation is the centrepiece of the motion design. It should be accurate to the real mechanism: each character flips independently with a brief stagger, making a characteristic mechanical sound (opt-in). The flip duration per character should be fast enough to feel snappy but slow enough that the character is legible mid-flip.

All other animation should be restrained. Annunciator tiles fade to their status colour rather than snapping. Gauges animate their needle from zero on first display. Everything else is essentially static — this is a panel, not an iOS app.

Sound design (optional, off by default): a soft mechanical click on tile state change, the Solari flip sound during result population, a distinct tone when the Master Caution resolves (different tones for pass and fail).

### 7.4 Navigation

Single-window application. Navigation is state-driven via AppCoordinator. No document-based NSDocument architecture in Stage 1 — one file at a time.

---

## 8. Stage 2 Hooks (Fix Engine)

The following are not implemented in Stage 1 but the architecture must not preclude them.

- `TaxiwayDocument` is immutable. The Fix Engine will produce a `TaxiwayPatch` — a set of discrete operations to apply to a PDF.
- `CheckResult.affectedItems` carries enough reference information (page index, object reference, font name) to target fix operations precisely.
- The report format includes `documentSnapshot` so fixes can be derived from report data without re-parsing.
- Fix operations are logged in an audit trail and are undoable within a session.

Planned fix operations (Stage 2, not in scope now):
- Embed missing fonts (where legally permissible)
- Convert colour spaces
- Flatten transparency
- Set or correct bleed box
- Remove annotations and interactive elements
- Downsample images
- Remove or flag AI metadata

---

## 9. Testing

### 9.1 Unit Tests

All checks in `TaxiwayCore` have unit tests against synthetic `TaxiwayDocument` fixtures. Parser tests run against a corpus of real PDFs covering edge cases.

### 9.2 Test PDF Corpus

A set of test PDFs is maintained in the repo under `TestFixtures/`. Each fixture is documented with its expected check results. Fixtures cover:

- Correct files that should pass common profiles
- Files with known issues (unembedded fonts, wrong colour space, insufficient bleed, etc.)
- Edge cases (empty pages, encrypted files, PDF 1.3 through 2.0, malformed boxes)

### 9.3 Snapshot Testing

Report output (JSON) is snapshot-tested against known fixtures to catch regressions in check logic.

---

## 10. Open Questions

These need decisions before or during development:

1. **Content stream parsing** — How far do we go with parsing content streams in Stage 1? Required for accurate overprint detection, named colour in gradients, and text outline detection. CGPDF streams are accessible but parsing PostScript operators is non-trivial.
2. **Ink coverage calculation** — Rasterise-and-sample vs. out of scope for Stage 1?
3. **Multi-file batch processing** — Stage 1 or Stage 2?
4. **CLI companion tool** — Wrap `TaxiwayCore` in a CLI for scripting? Good candidate for a separate target in the same repo.
5. **Localisation** — English only for now, or plan for DE from the start given the user base?

---

## 11. Dependencies

Preference is for zero third-party dependencies in `TaxiwayCore`. The UI layer may use:

- [Sparkle](https://sparkle-project.org) — auto-update (if distributed outside Mac App Store)

PDF parsing relies entirely on Apple frameworks: PDFKit, CoreGraphics, ImageIO, Foundation.

---

*This document is a living spec. Sections marked "Stage 2" are architectural notes only and carry no implementation commitment for the current milestone.*
