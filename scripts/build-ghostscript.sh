#!/bin/bash
set -euo pipefail

# Bundle Ghostscript from Homebrew into vendor/gs/ for inclusion in the app bundle.
# Installs via Homebrew if not already present.
# Idempotent — skips if vendor/gs/bin/gs already exists.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENDOR_DIR="$PROJECT_DIR/vendor/gs"

# Check if already bundled
if [ -f "$VENDOR_DIR/bin/gs" ]; then
    echo "Ghostscript already bundled at $VENDOR_DIR/bin/gs"
    file "$VENDOR_DIR/bin/gs"
    exit 0
fi

# Install via Homebrew if needed
if ! brew list ghostscript &>/dev/null; then
    echo "Installing Ghostscript via Homebrew..."
    brew install ghostscript
fi

GS_PREFIX="$(brew --prefix ghostscript)"
GS_VERSION="$(gs --version)"
GS_BIN="$GS_PREFIX/bin/gs"
GS_SHARE="$GS_PREFIX/share/ghostscript/$GS_VERSION"

echo "=== Bundling Ghostscript $GS_VERSION from Homebrew ==="

# Copy binary
mkdir -p "$VENDOR_DIR/bin"
cp "$GS_BIN" "$VENDOR_DIR/bin/gs"

# Copy lib (PostScript support files, fontmap, etc.)
if [ -d "$GS_SHARE/lib" ]; then
    cp -R "$GS_SHARE/lib" "$VENDOR_DIR/lib"
fi

# Copy Resource directory (CMap, Init, etc. — GS 10+ moved files here)
if [ -d "$GS_SHARE/Resource" ]; then
    cp -R "$GS_SHARE/Resource" "$VENDOR_DIR/Resource"
fi

# Copy ICC profiles
if [ -d "$GS_SHARE/iccprofiles" ]; then
    cp -R "$GS_SHARE/iccprofiles" "$VENDOR_DIR/iccprofiles"
fi

echo "=== Done ==="
file "$VENDOR_DIR/bin/gs"
echo "Installed to: $VENDOR_DIR"
echo "Ghostscript $GS_VERSION bundled successfully."
