# Ghostscript Install Flow Design

## Context

The Fix engine now uses system-installed Ghostscript (via `brew install ghostscript`) instead of a bundled binary. Users who don't have GS installed need clear guidance to set it up. 13 of 14 fixes require Ghostscript; only `fix.remove_annotations` uses PDFKit.

## Design

### Fix Panel — GS Missing State

When `GhostscriptRunner.system()` returns nil:

1. **Setup banner** at the top of the fix panel (above QUEUED FIXES):
   - Icon + "Ghostscript Required" title
   - Subtitle explaining GS is needed for the fix engine
   - "Setup Instructions..." button opens the setup sheet
   - Small "Refresh" link to re-check availability

2. **TOOLS section**: GS-dependent tools shown but **dimmed/disabled** (no Add/Configure buttons). The PDFKit fix (`remove_annotations`) stays enabled.

3. **QUEUED FIXES section**: "Apply Fixes" button hidden when GS fixes are queued but GS is unavailable.

### Setup Sheet (modal)

Presented from the fix panel with 3 steps:

1. **Install Homebrew** — one-liner from brew.sh with copy-to-clipboard button. Shows a note: "Skip if you already have Homebrew."
2. **Install Ghostscript** — `brew install ghostscript` with copy-to-clipboard button.
3. **Verify** — "Check Installation" button. Shows green checkmark on success, red X with retry on failure.

On success: sheet shows "Done" button (or auto-dismisses after brief delay). Fix panel refreshes to enabled state.

### Re-detection

- `ghostscriptAvailable` is checked on `.onAppear` of the fix panel
- Manual "Check Installation" button in the setup sheet
- "Refresh" link in the setup banner

### Files to Change

- **`GhostscriptRunner.swift`**: Already done — uses `system()` factory.
- **`FixPanelView.swift`**: Add setup banner, disable GS tools when unavailable.
- **New: `GhostscriptSetupSheet.swift`**: Modal sheet with install steps.
- **`FixEngine.swift`**: No changes needed — already checks `ghostscriptAvailable`.
- **`PreflightSession.swift`**: Error message already updated.
