# Ghostscript Install Flow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Guide users to install system Ghostscript when it's missing, with clear steps and auto-detection.

**Architecture:** A `@State var gsAvailable` flag in `FixPanelView` drives two states: the normal fix panel, or a degraded panel with a setup banner and disabled GS tools. A modal sheet provides step-by-step install instructions with a verify button that re-checks `GhostscriptRunner.system()`.

**Tech Stack:** SwiftUI, TaxiwayCore (GhostscriptRunner)

---

### Task 1: Create GhostscriptSetupSheet

**Files:**
- Create: `Taxiway/Views/Report/GhostscriptSetupSheet.swift`

**Step 1: Create the setup sheet view**

```swift
import SwiftUI
import TaxiwayCore

struct GhostscriptSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var verificationState: VerificationState = .idle

    enum VerificationState {
        case idle, checking, found, notFound
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "terminal")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Install Ghostscript")
                        .font(TaxiwayTheme.monoLarge)
                        .fontWeight(.bold)
                    Text("Required for PDF fixes")
                        .font(TaxiwayTheme.monoSmall)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Step 1: Homebrew
            stepView(
                number: 1,
                title: "Install Homebrew",
                subtitle: "Skip if you already have Homebrew installed.",
                command: #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#
            )

            // Step 2: Ghostscript
            stepView(
                number: 2,
                title: "Install Ghostscript",
                subtitle: "Run this in Terminal.",
                command: "brew install ghostscript"
            )

            Divider()

            // Step 3: Verify
            VStack(alignment: .leading, spacing: 8) {
                Label("Step 3: Verify Installation", systemImage: "checkmark.shield")
                    .font(TaxiwayTheme.monoSmall)
                    .fontWeight(.bold)

                HStack(spacing: 12) {
                    Button {
                        checkInstallation()
                    } label: {
                        Label("Check Installation", systemImage: "arrow.clockwise")
                    }
                    .disabled(verificationState == .checking)

                    switch verificationState {
                    case .idle:
                        EmptyView()
                    case .checking:
                        ProgressView()
                            .controlSize(.small)
                    case .found:
                        Label("Ghostscript found", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(TaxiwayTheme.monoSmall)
                    case .notFound:
                        Label("Not found — check the steps above", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(TaxiwayTheme.monoSmall)
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                Spacer()
                if verificationState == .found {
                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                } else {
                    Button("Close") { dismiss() }
                }
            }
        }
        .padding(24)
        .frame(width: 520, height: 480)
    }

    private func stepView(number: Int, title: String, subtitle: String, command: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Step \(number): \(title)", systemImage: "\(number).circle")
                .font(TaxiwayTheme.monoSmall)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Text(command)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                    .textSelection(.enabled)
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Copy to clipboard")
            }
        }
    }

    private func checkInstallation() {
        verificationState = .checking
        DispatchQueue.global(qos: .userInitiated).async {
            let found = GhostscriptRunner.system() != nil
            DispatchQueue.main.async {
                verificationState = found ? .found : .notFound
            }
        }
    }
}
```

**Step 2: Verify it compiles**

Run: full Xcode build (Cmd+B)

**Step 3: Commit**

```bash
git add Taxiway/Views/Report/GhostscriptSetupSheet.swift
git commit -m "feat: add Ghostscript setup sheet with install steps and verification"
```

---

### Task 2: Update FixPanelView with GS availability state and setup banner

**Files:**
- Modify: `Taxiway/Views/Report/FixPanelView.swift`

**Step 1: Add GS state and setup banner to FixPanelView**

Add state properties at the top of the struct:

```swift
@State private var gsAvailable = GhostscriptRunner.system() != nil
@State private var showSetupSheet = false
```

Add a setup banner `@ViewBuilder` property:

```swift
@ViewBuilder
private var ghostscriptBanner: some View {
    VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Ghostscript Required")
                    .font(TaxiwayTheme.monoSmall)
                    .fontWeight(.bold)
                Text("Most fixes need Ghostscript installed on your system.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        HStack(spacing: 12) {
            Button("Setup Instructions\u{2026}") {
                showSetupSheet = true
            }
            .controlSize(.small)
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            Button {
                gsAvailable = GhostscriptRunner.system() != nil
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .controlSize(.small)
            .buttonStyle(.bordered)
        }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
}
```

**Step 2: Wire it into the body**

Replace the `body` with:

```swift
var body: some View {
    VStack(alignment: .leading, spacing: TaxiwayTheme.sectionSpacing) {
        if !gsAvailable {
            ghostscriptBanner
        }
        queuedFixesSection
        Divider()
        availableToolsSection
    }
    .onAppear {
        gsAvailable = GhostscriptRunner.system() != nil
    }
    .sheet(isPresented: $showSetupSheet) {
        // Re-check after sheet closes
        gsAvailable = GhostscriptRunner.system() != nil
    } content: {
        GhostscriptSetupSheet()
    }
}
```

**Step 3: Disable GS tools when unavailable**

In the `availableToolsSection`, change the tool row button logic. Replace the existing `if queued { ... } else if needsConfiguration { ... } else { ... }` block with:

```swift
if queued {
    Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(.green)
} else if !gsAvailable && descriptor.category == .ghostscript {
    Text("Requires Ghostscript")
        .font(.caption2)
        .foregroundStyle(.tertiary)
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
```

Also dim the entire tool row when GS is unavailable. On the tool row `HStack`, add:

```swift
.opacity(!gsAvailable && descriptor.category == .ghostscript ? 0.5 : 1.0)
```

**Step 4: Disable "Apply Fixes" when GS unavailable but GS fixes queued**

In `queuedFixesSection`, replace the existing GS warning block (lines 88-102) and update the Apply button:

Remove the old warning block entirely (the banner replaces it). On the Apply button, add a disabled condition:

```swift
.disabled(session.isFixing || (!gsAvailable && session.fixQueue.requiresGhostscript))
```

**Step 5: Verify it compiles**

Run: full Xcode build (Cmd+B)

**Step 6: Commit**

```bash
git add Taxiway/Views/Report/FixPanelView.swift
git commit -m "feat: show GS setup banner and disable GS tools when unavailable"
```

---

### Task 3: Clean up old bundled-GS infrastructure

**Files:**
- Modify: `Taxiway.xcodeproj/project.pbxproj` — remove the "Copy Ghostscript" shell script build phase
- Delete: `scripts/build-ghostscript.sh` — no longer used
- Delete: `vendor/gs/` directory — no longer used

**Step 1: Remove the "Copy Ghostscript" build phase from the Xcode project**

In `Taxiway.xcodeproj/project.pbxproj`:

1. Remove `9BF1A0012F63000000E614D5 /* Copy Ghostscript */,` from the build phases array.
2. Remove the entire `9BF1A0012F63000000E614D5` PBXShellScriptBuildPhase section.

**Step 2: Delete old files**

```bash
rm scripts/build-ghostscript.sh
rm -rf vendor/gs/
```

**Step 3: Add vendor/gs/ to .gitignore (optional, prevents accidental re-creation)**

Append to `.gitignore`:

```
vendor/gs/
```

**Step 4: Verify the project still builds**

Run: full Xcode build (Cmd+B)

**Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove bundled Ghostscript infrastructure

The Fix engine now uses system-installed Ghostscript.
Removed: build-ghostscript.sh, vendor/gs/, Copy Ghostscript build phase."
```
