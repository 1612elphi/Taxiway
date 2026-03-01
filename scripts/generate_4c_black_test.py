#!/usr/bin/env python3
"""
Generate a PDF with 4-colour (registration) black text and high ink coverage.

The text is set in C100 M100 Y100 K100 — 400% ink coverage, the worst possible
"rich black". This should trigger colour.ink_coverage, colour.rich_black, and
the convert-to-CMYK fix should clean it up.

Usage:
    python3 scripts/generate_4c_black_test.py [output_path]
"""

import os
import sys


def main():
    output_path = (
        sys.argv[1]
        if len(sys.argv) > 1
        else os.path.expanduser("~/Desktop/Taxiway-4C-Black-Test.pdf")
    )

    objects = {}
    next_num = [1]

    def alloc():
        n = next_num[0]
        next_num[0] += 1
        return n

    def obj(num, data):
        if isinstance(data, str):
            data = data.encode("latin-1")
        objects[num] = data

    def stream(num, props, data):
        if isinstance(data, str):
            data = data.encode("latin-1")
        hdr = f"<< /Length {len(data)}"
        if props:
            hdr += f" {props}"
        hdr += " >>"
        objects[num] = hdr.encode("latin-1") + b"\nstream\n" + data + b"\nendstream"

    catalog = alloc()   # 1
    info = alloc()      # 2
    pages = alloc()     # 3
    page1 = alloc()     # 4
    cs1 = alloc()       # 5
    font = alloc()      # 6

    obj(catalog, f"<< /Type /Catalog /Pages {pages} 0 R >>")
    obj(info,
        "<< /Title (4C Black Test) /Creator (Taxiway Test Generator) "
        "/CreationDate (D:20260301120000Z) >>")
    obj(pages, f"<< /Type /Pages /Kids [{page1} 0 R] /Count 1 >>")

    # Helvetica — not embedded, but that's fine for this test
    obj(font,
        "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica "
        "/Encoding /WinAnsiEncoding >>")

    # A4 with 3mm bleed
    bleed = 8.504
    tw, th = 595.276, 841.89
    mw, mh = tw + bleed * 2, th + bleed * 2

    obj(page1,
        f"<< /Type /Page /Parent {pages} 0 R "
        f"/MediaBox [0 0 {mw:.3f} {mh:.3f}] "
        f"/TrimBox [{bleed:.3f} {bleed:.3f} {tw + bleed:.3f} {th + bleed:.3f}] "
        f"/BleedBox [0 0 {mw:.3f} {mh:.3f}] "
        f"/Contents {cs1} 0 R "
        f"/Resources << /Font << /F1 {font} 0 R >> >> >>")

    # Content stream — all text in CMYK with obscene ink coverage
    content = (
        "q\n"
        # White background
        "0 0 0 0 k 0 0 {mw:.3f} {mh:.3f} re f\n"

        # === 4C Black text: C100 M100 Y100 K100 = 400% ===
        "BT /F1 48 Tf\n"
        "1 1 1 1 k\n"
        "60 750 Td (REGISTRATION BLACK) Tj\n"
        "ET\n"

        "BT /F1 24 Tf\n"
        "1 1 1 1 k\n"
        "60 690 Td (This headline is C100/M100/Y100/K100) Tj\n"
        "ET\n"

        "BT /F1 14 Tf\n"
        "1 1 1 1 k\n"
        "60 650 Td (400%% total ink coverage. Every press operator's nightmare.) Tj\n"
        "ET\n"

        # === Slightly less terrible rich black: C80 M70 Y70 K100 = 320% ===
        "BT /F1 36 Tf\n"
        "0.8 0.7 0.7 1.0 k\n"
        "60 570 Td (HEAVY RICH BLACK) Tj\n"
        "ET\n"

        "BT /F1 14 Tf\n"
        "0.8 0.7 0.7 1.0 k\n"
        "60 530 Td (C80/M70/Y70/K100 = 320%% ink. Still way too high.) Tj\n"
        "ET\n"

        # === Body text in 4C black ===
        "BT /F1 11 Tf\n"
        "1 1 1 1 k\n"
        "60 470 Td (Body copy should never be in registration black.) Tj\n"
        "0 -18 Td (It causes mis-registration on press, slurring, and set-off.) Tj\n"
        "0 -18 Td (The correct black for body text is 0/0/0/100 \\(K-only\\).) Tj\n"
        "0 -18 Td (Even rich black headlines should stay under 280%% total.) Tj\n"
        "ET\n"

        # === Big solid fill at 400% for maximum ink coverage trigger ===
        "1 1 1 1 k\n"
        "60 280 492 100 re f\n"

        "BT /F1 18 Tf\n"
        "0 0 0 0 k\n"
        "80 320 Td (400%% ink solid fill) Tj\n"
        "ET\n"

        # === Proper K-only black for comparison ===
        "0 0 0 1 k\n"
        "60 160 492 80 re f\n"

        "BT /F1 18 Tf\n"
        "1 1 1 0 k\n"
        "80 190 Td (K-only black \\(correct\\)) Tj\n"
        "ET\n"

        "Q\n"
    ).format(mw=mw, mh=mh)

    stream(cs1, "", content)

    # === Assemble PDF ===
    buf = bytearray()
    buf.extend(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n\n")

    offsets = {}
    for num in sorted(objects):
        offsets[num] = len(buf)
        buf.extend(f"{num} 0 obj\n".encode("latin-1"))
        data = objects[num]
        if isinstance(data, str):
            data = data.encode("latin-1")
        buf.extend(data)
        buf.extend(b"\nendobj\n\n")

    xref_pos = len(buf)
    max_num = max(objects)
    buf.extend(f"xref\n0 {max_num + 1}\n".encode())
    buf.extend(b"0000000000 65535 f \r\n")
    for i in range(1, max_num + 1):
        off = offsets.get(i, 0)
        buf.extend(f"{off:010d} 00000 n \r\n".encode())

    buf.extend(b"trailer\n")
    buf.extend(
        f"<< /Size {max_num + 1} /Root {catalog} 0 R "
        f"/Info {info} 0 R >>\n".encode()
    )
    buf.extend(f"startxref\n{xref_pos}\n%%EOF\n".encode())

    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(bytes(buf))

    print(f"Generated: {output_path}")
    print(f"Size: {len(buf):,} bytes")
    print()
    print("Expected preflight triggers:")
    print("  colour.ink_coverage   — 400% (registration black text + solid fill)")
    print("  colour.rich_black     — C100/M100/Y100/K100 and C80/M70/Y70/K100")
    print("  fonts.not_embedded    — Helvetica Type1")
    print()
    print("Fix to test: 'Convert to CMYK' should re-distill and clean up ink limits.")


if __name__ == "__main__":
    main()
