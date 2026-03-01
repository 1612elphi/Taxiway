# Backlog

## Universal Ghostscript binary (arm64 + x86_64)

The bundled Ghostscript binary is currently arm64-only (copied from Homebrew). This means fix features won't work on Intel Macs without Rosetta.

A print shop tester uses Intel Macs, so this needs to be resolved before wider distribution. Options:
- Cross-compile from source as a universal binary (attempted, ran into bundled lib configure issues with libtiff/zlib)
- Download separate arm64 and x86_64 Homebrew bottles and `lipo -create` them
- Ship arm64-only and require Rosetta on Intel (least effort, worst UX)
