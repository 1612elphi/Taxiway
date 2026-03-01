# Profile Editor Overhaul + Report PDF Preview Design

## Feature 1: Profile Editor Overhaul

### Problem

The current profile editor shows raw typeIDs (`fonts.not_embedded`), hides check parameters, and uses a clunky disclosure-group layout.

### Design

**Layout:** Replace the current Form with a 3-column `NavigationSplitView`:

- **Left sidebar** — 8 category rows (File, PDF, Pages, Marks, Colour, Fonts, Images, Lines) with badge showing enabled check count per category.
- **Middle list** — Checks within the selected category. Each row: human-readable name, enable toggle, severity pill (coloured badge). Selected check is highlighted.
- **Right detail** — Full info for the selected check: display name, description of what it verifies, editable parameter fields, severity picker. Built-in profiles show read-only state with a "Duplicate" button.

**Human-readable names:** A static `CheckMetadata` dictionary in the app target maps each typeID to:
- `displayName: String` (e.g., "Unembedded Fonts")
- `description: String` (e.g., "Flags fonts that are referenced but not embedded in the PDF.")

**Parameter editing:** Decode `CheckEntry.parametersJSON` into the known parameter structs and render appropriate controls:
- Numeric thresholds → `Stepper` / `TextField` with number formatter
- Enum values (colour space, font type, operator) → `Picker`
- Booleans → `Toggle`

Re-encode modified parameters back to `parametersJSON` on change.

**Files involved:**
- New: `Taxiway/Views/ProfileEditor/CheckMetadata.swift` — static metadata dictionary
- New: `Taxiway/Views/ProfileEditor/CheckDetailView.swift` — right-column detail
- New: `Taxiway/Views/ProfileEditor/ParameterEditorView.swift` — dynamic parameter form
- Rewrite: `Taxiway/Views/ProfileEditor/ProfileEditorView.swift` — NavigationSplitView layout

---

## Feature 2: Report PDF Preview with Highlighting

### Problem

When clicking an issue in the report sidebar, the detail area only shows text. There's no visual connection to the actual PDF content.

### Design

**Layout change:** The report detail area splits into two regions:
- **Top:** PDF page preview rendered via `PDFView` (PDFKit), showing the page associated with the selected issue.
- **Bottom:** Existing result detail info (message, severity, affected items list).

**Highlighting by item type:**

| AffectedItem | Page shown | Highlight style |
|-------------|-----------|----------------|
| `.document` | Page 1 | Amber border on preview |
| `.page(index:)` | That page | Semi-transparent overlay on full page |
| `.annotation(type:, page:)` | That page | Rect overlay on annotation bounds |
| `.image(id:, page:)` | That page | Page-level overlay (no bbox data yet) |
| `.font(name:, pages:)` | First affected page | Page-level overlay |
| `.colourSpace(name:, pages:)` | First affected page | Page-level overlay |

**Multi-page navigation:** When a result affects multiple pages, show prev/next buttons in the preview toolbar.

### Parser changes

- Add `bounds: CGRect?` to `AnnotationInfo`
- Capture `PDFAnnotation.bounds` in `AnnotationExtractor`
- Add optional `rect: CGRect?` to `AffectedItem.annotation` case

Bounding-box highlighting for images and text requires content stream parsing — deferred to a future enhancement.

**Files involved:**
- Modify: `TaxiwayCore/Sources/TaxiwayCore/Models/AnnotationInfo.swift` — add bounds
- Modify: `TaxiwayCore/Sources/TaxiwayCore/Parser/AnnotationExtractor.swift` — capture bounds
- Modify: `TaxiwayCore/Sources/TaxiwayCore/Checks/AffectedItem.swift` — add optional rect
- New: `Taxiway/Views/Report/PDFPreviewView.swift` — PDFKit page render + highlight overlay
- Rewrite: `Taxiway/Views/Report/ResultDetailView.swift` — split into preview + info
- Modify: `Taxiway/Views/Report/ReportView.swift` — pass PDF URL to detail area
