# Taxiway

**Your PDFs, cleared for takeoff.**

Native macOS PDF preflight inspector. 55 checks across 8 categories, 14 automated fixes, 10 built-in profiles. No subscription. No account. No dependencies. Free forever.

## What it does

Drop a PDF. Taxiway parses it, runs every check you've configured, and tells you exactly what's wrong — and where. Click a failed check and the offending object lights up on the page. No log files. No guessing.

Then fix it. Convert to CMYK, embed fonts, flatten transparency, downsample images, add bleed — 10 reactive fixes trigger automatically when checks fail, plus 4 proactive tools available anytime. Your original is never touched.

## Checks

| Category | Examples |
|----------|----------|
| **File** | File size, encryption, JavaScript, embedded files, metadata fields |
| **PDF** | Version, standard compliance (X-1a/X-3/X-4/A-2b), output intent, transparency, layers, annotations, tagged, linearized |
| **Pages** | Page count, page size, mixed sizes, rotation |
| **Marks & Bleed** | Trim box, bleed (zero/uniform/range), art & slug boxes |
| **Colour** | Colour space, spot colours, rich black, overprint, ink coverage, registration colour, text colour mode, named colour gradients |
| **Fonts** | Embedding, font type, size range |
| **Images** | Resolution, colour mode, file type, ICC profiles, alpha, blend modes, scaling, GenAI metadata, C2PA provenance |
| **Lines** | Stroke weight, zero-width hairlines |

Every check is parametric — thresholds, operators, and severity are all configurable.

## Profiles

10 built-in profiles ship with the app:

- **PDF/X-1a** — strict CMYK press production
- **PDF/X-3** — European print with ICC colour management
- **PDF/X-4** — modern press with transparency support
- **PDF/A-2b** — long-term archival, tagged, no JS/encryption
- **Screen / Digital** — optimised for screen distribution
- **Digital Print** — short-run toner, 3mm bleed, no overprint
- **Newspaper** — web-offset, strict ink limits, CMYK only
- **Large Format** — signage and banners, relaxed resolution
- **Loose** — minimal checks, warnings only
- **AI Content Audit** — flags GenAI markers and C2PA provenance

Clone any profile, adjust every parameter, import/export as `.taxiprofile` JSON.

## Fixes

| Reactive (triggered by failures) | Proactive (always available) |
|----------------------------------|------------------------------|
| Convert to CMYK | Add / Change Bleed |
| Embed Fonts | Change Page Size |
| Downsample Images | Set PDF Version |
| Flatten Transparency | Add Trim Marks |
| Convert Rich Black | |
| Limit Ink Coverage | |
| Remove Annotations | |
| Flatten Alpha | |
| Flatten Layers | |
| Assign Default ICC | |

Fixes are queued, reviewed, then applied in batch. Powered by a bundled Ghostscript binary — no external dependencies required.

## TaxiwayCore

The entire preflight engine lives in **TaxiwayCore**, a standalone Swift Package with zero UI dependencies and zero third-party libraries. Pure Swift 6. Sendable throughout. Immutable document model.

```
.package(path: "TaxiwayCore")
```

```
$ swift test
Build complete!
✓ 524 tests in 83 suites passed
```

Import it into your own tools. Run it on a server. Embed it in CI. Build a competing app — honestly, we'd be flattered.

## Building

Requires Xcode 26+ and macOS 26+.

```bash
# Build the app
xcodebuild -scheme Taxiway -destination 'platform=macOS' build

# Run TaxiwayCore tests
cd TaxiwayCore && swift test
```

## Export

Full reports in JSON, CSV, and formatted PDF. Every export includes the complete parsed document snapshot.

## License

[Apache License 2.0](LICENSE). The bundled Ghostscript binary retains its own [AGPL license](https://www.gnu.org/licenses/agpl-3.0.html).
