#!/bin/bash
set -euo pipefail

# Bundle Ghostscript from Homebrew into vendor/gs/ for inclusion in the app bundle.
# Copies the binary, its PostScript resources, AND all Homebrew dylib dependencies.
# Rewrites dylib load paths to @loader_path so the binary is fully self-contained.
# Re-signs everything with the specified Developer ID.
#
# Usage: ./build-ghostscript.sh [--force]
#   --force  Remove existing vendor/gs and rebuild from scratch

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENDOR_DIR="$PROJECT_DIR/vendor/gs"
# Resolve signing identity by finding the first valid Developer ID Application cert.
# Uses the SHA-1 hash to avoid ambiguity when duplicate certs exist in the keychain.
SIGNING_IDENTITY="$(security find-identity -v -p codesigning | grep 'Developer ID Application' | head -1 | awk '{print $2}')"
if [ -z "$SIGNING_IDENTITY" ]; then
    echo "error: No 'Developer ID Application' signing identity found."
    exit 1
fi

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
    FORCE=1
fi

# Check if already bundled (skip unless --force)
if [[ -f "$VENDOR_DIR/bin/gs" && $FORCE -eq 0 ]]; then
    echo "Ghostscript already bundled at $VENDOR_DIR/bin/gs"
    echo "Run with --force to rebuild."
    file "$VENDOR_DIR/bin/gs"
    exit 0
fi

# Clean previous bundle
rm -rf "$VENDOR_DIR"

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

# --- Copy binary ---
mkdir -p "$VENDOR_DIR/bin"
cp "$GS_BIN" "$VENDOR_DIR/bin/gs"
chmod 755 "$VENDOR_DIR/bin/gs"

# --- Copy PostScript resources ---
if [ -d "$GS_SHARE/lib" ]; then
    cp -R "$GS_SHARE/lib" "$VENDOR_DIR/lib"
fi
if [ -d "$GS_SHARE/Resource" ]; then
    cp -R "$GS_SHARE/Resource" "$VENDOR_DIR/Resource"
fi
if [ -d "$GS_SHARE/iccprofiles" ]; then
    cp -R "$GS_SHARE/iccprofiles" "$VENDOR_DIR/iccprofiles"
fi

# --- Bundle dylib dependencies ---
# Recursively discover all Homebrew dylibs needed by gs and its deps.
# Uses temp files to track the work queue (compatible with macOS system bash).

DYLIB_DIR="$VENDOR_DIR/lib"
mkdir -p "$DYLIB_DIR"

TMPDIR_WORK="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_WORK"' EXIT

SEEN_FILE="$TMPDIR_WORK/seen"
QUEUE_FILE="$TMPDIR_WORK/queue"
RESULT_FILE="$TMPDIR_WORK/result"
touch "$SEEN_FILE" "$QUEUE_FILE" "$RESULT_FILE"

# resolve_rpath: given a binary and an @rpath/libfoo.dylib reference, find the real path.
# Checks LC_RPATH entries from the binary, then falls back to common Homebrew locations.
resolve_rpath() {
    local binary="$1"
    local rpath_ref="$2"  # e.g. @rpath/libsharpyuv.0.dylib
    local libname="${rpath_ref#@rpath/}"

    # Extract LC_RPATH entries from the binary
    local rpaths
    rpaths="$(otool -l "$binary" 2>/dev/null | awk '/cmd LC_RPATH/{found=1} found && /path /{print $2; found=0}')"

    # Try each rpath
    for rp in $rpaths; do
        # Resolve @loader_path relative to the binary's directory
        local resolved="${rp/@loader_path/$(dirname "$binary")}"
        resolved="${resolved/@executable_path/$(dirname "$binary")}"
        if [ -f "$resolved/$libname" ]; then
            echo "$resolved/$libname"
            return 0
        fi
    done

    # Fallback: search common Homebrew locations
    local found
    found="$(find /opt/homebrew/opt /opt/homebrew/lib -name "$libname" -not -path "*/site-packages/*" 2>/dev/null | head -1)"
    if [ -n "$found" ]; then
        echo "$found"
        return 0
    fi

    return 1
}

# get_homebrew_deps: extract non-system dylib deps from a binary.
# Outputs one resolved absolute path per line.
get_homebrew_deps() {
    local binary="$1"
    otool -L "$binary" | awk '/^\t/{print $1}' | while read -r dep; do
        if [[ "$dep" == /opt/homebrew/* ]]; then
            echo "$dep"
        elif [[ "$dep" == @rpath/* ]]; then
            resolved="$(resolve_rpath "$binary" "$dep" || true)"
            if [ -n "$resolved" ]; then
                echo "$resolved"
            fi
        fi
    done
}

# Seed the queue with direct deps of the gs binary
get_homebrew_deps "$VENDOR_DIR/bin/gs" >> "$QUEUE_FILE"

echo "Discovering dylib dependencies..."

# Process queue until empty — breadth-first dependency walk
while [ -s "$QUEUE_FILE" ]; do
    # Take the first item from the queue
    dylib="$(head -1 "$QUEUE_FILE")"
    tail -n +2 "$QUEUE_FILE" > "$TMPDIR_WORK/rest"
    mv "$TMPDIR_WORK/rest" "$QUEUE_FILE"

    base="$(basename "$dylib")"

    # Skip if already seen
    if grep -qxF "$base" "$SEEN_FILE" 2>/dev/null; then
        continue
    fi
    echo "$base" >> "$SEEN_FILE"

    # Record this dylib
    echo "$dylib" >> "$RESULT_FILE"

    # Add its deps to the queue
    if [ -f "$dylib" ]; then
        get_homebrew_deps "$dylib" | while read -r dep; do
            dep_base="$(basename "$dep")"
            if ! grep -qxF "$dep_base" "$SEEN_FILE" 2>/dev/null; then
                echo "$dep"
            fi
        done >> "$QUEUE_FILE"
    fi
done

# Read results into a variable
ALL_DYLIBS=()
while IFS= read -r line; do
    ALL_DYLIBS+=("$line")
done < "$RESULT_FILE"

echo "Found ${#ALL_DYLIBS[@]} Homebrew dylibs to bundle:"
for d in "${ALL_DYLIBS[@]}"; do
    echo "  $(basename "$d")"
done

# Copy all dylibs
for dylib in "${ALL_DYLIBS[@]}"; do
    cp "$dylib" "$DYLIB_DIR/$(basename "$dylib")"
    chmod 644 "$DYLIB_DIR/$(basename "$dylib")"
done

# --- Rewrite load paths ---
echo "Rewriting dylib load paths..."

# Rewrite the gs binary: change Homebrew paths to @loader_path/../lib/
for dylib in "${ALL_DYLIBS[@]}"; do
    local_name="$(basename "$dylib")"
    install_name_tool -change "$dylib" "@loader_path/../lib/$local_name" "$VENDOR_DIR/bin/gs" 2>/dev/null || true
done

# Rewrite each bundled dylib: change its own ID and its deps to @loader_path/
for dylib_file in "$DYLIB_DIR"/*.dylib; do
    local_name="$(basename "$dylib_file")"

    # Change the dylib's own install name
    install_name_tool -id "@loader_path/$local_name" "$dylib_file" 2>/dev/null || true

    # Change references to other Homebrew dylibs (absolute paths)
    for dep in "${ALL_DYLIBS[@]}"; do
        dep_name="$(basename "$dep")"
        install_name_tool -change "$dep" "@loader_path/$dep_name" "$dylib_file" 2>/dev/null || true
    done

    # Also rewrite any @rpath references to bundled dylibs
    otool -L "$dylib_file" | awk '/^\t.*@rpath/{print $1}' | while read -r rpath_ref; do
        ref_name="$(basename "$rpath_ref")"
        if [ -f "$DYLIB_DIR/$ref_name" ]; then
            install_name_tool -change "$rpath_ref" "@loader_path/$ref_name" "$dylib_file" 2>/dev/null || true
        fi
    done
done

# --- Re-sign everything ---
echo "Code signing..."

# Sign dylibs first, then the binary
for dylib_file in "$DYLIB_DIR"/*.dylib; do
    codesign -fs "$SIGNING_IDENTITY" --timestamp --options runtime "$dylib_file"
done
codesign -fs "$SIGNING_IDENTITY" --timestamp --options runtime "$VENDOR_DIR/bin/gs"

# --- Verify ---
echo ""
echo "=== Verification ==="
echo "Binary:"
file "$VENDOR_DIR/bin/gs"
echo ""
echo "Load paths (should all be @loader_path or /usr/lib):"
otool -L "$VENDOR_DIR/bin/gs" | tail -n +2
echo ""
echo "Bundled dylibs: $(ls "$DYLIB_DIR"/*.dylib 2>/dev/null | wc -l | xargs)"
echo ""

# Check for any remaining Homebrew references
REMAINING="$(otool -L "$VENDOR_DIR/bin/gs" | grep "/opt/homebrew" || true)"
if [ -n "$REMAINING" ]; then
    echo "WARNING: gs binary still references Homebrew paths:"
    echo "$REMAINING"
    exit 1
fi

# Check dylibs for remaining Homebrew or unresolved @rpath references
for dylib_file in "$DYLIB_DIR"/*.dylib; do
    REMAINING="$(otool -L "$dylib_file" | grep -E "/opt/homebrew|@rpath" || true)"
    if [ -n "$REMAINING" ]; then
        echo "WARNING: $(basename "$dylib_file") still has unresolved references:"
        echo "$REMAINING"
        exit 1
    fi
done

echo "All load paths verified — no Homebrew or @rpath references remain."
echo "Installed to: $VENDOR_DIR"
echo "Ghostscript $GS_VERSION bundled successfully."
