#!/usr/bin/env python3
"""
Generate a deliberately mangled PDF for Taxiway preflight testing.

Creates a 4-page PDF that triggers as many preflight checks as possible.
No external dependencies — writes raw PDF syntax using only stdlib.

Usage:
    python3 scripts/generate_test_pdf.py [output_path]
"""

import os
import sys
import zlib


def main():
    output_path = (
        sys.argv[1]
        if len(sys.argv) > 1
        else os.path.expanduser("~/Desktop/Taxiway-Mangled-Test.pdf")
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

    def img_stream(num, dict_template, data):
        """Image stream where dict_template has __LENGTH__ placeholder."""
        dict_str = dict_template.replace("__LENGTH__", str(len(data)))
        objects[num] = (
            dict_str.encode("latin-1") + b"\nstream\n" + data + b"\nendstream"
        )

    # ------------------------------------------------------------------
    # Allocate all object numbers up front
    # ------------------------------------------------------------------
    catalog = alloc()       # 1
    info = alloc()          # 2
    pages = alloc()         # 3
    page1 = alloc()         # 4
    page2 = alloc()         # 5
    page3 = alloc()         # 6
    page4 = alloc()         # 7
    cs1 = alloc()           # 8  content stream page 1
    cs2 = alloc()           # 9  content stream page 2
    cs3 = alloc()           # 10 content stream page 3
    cs4 = alloc()           # 11 content stream page 4
    font = alloc()          # 12 Helvetica (Type1, not embedded)
    gs_norm = alloc()       # 13 normal ExtGState
    gs_op = alloc()         # 14 overprint ExtGState
    gs_trans = alloc()      # 15 transparency ExtGState
    im_rgb = alloc()        # 16 RGB image XObject
    im_mask = alloc()       # 17 alpha mask (SMask)
    annot_note = alloc()    # 18 sticky note annotation
    annot_widget = alloc()  # 19 form widget annotation
    fn_spot = alloc()       # 20 tint function for spot colours
    fn_all = alloc()        # 21 tint function for registration (All)
    fn_shading = alloc()    # 22 shading interpolation function
    shading1 = alloc()      # 23 axial gradient with spot colour

    # ------------------------------------------------------------------
    # Catalog (with AcroForm for interactive elements)
    # ------------------------------------------------------------------
    obj(
        catalog,
        f"<< /Type /Catalog /Pages {pages} 0 R "
        f"/AcroForm << /Fields [{annot_widget} 0 R] >> >>",
    )

    # ------------------------------------------------------------------
    # Info dictionary — Title present, Author MISSING
    # ------------------------------------------------------------------
    obj(
        info,
        "<< /Title (Mangled Test PDF) "
        "/Creator (Taxiway Test Generator) "
        "/Producer (Raw PDF Writer v0.1) "
        "/Subject (Preflight testing) "
        "/CreationDate (D:20260301120000Z) >>",
    )

    # ------------------------------------------------------------------
    # Pages tree
    # ------------------------------------------------------------------
    obj(
        pages,
        f"<< /Type /Pages /Kids [{page1} 0 R {page2} 0 R "
        f"{page3} 0 R {page4} 0 R] /Count 4 >>",
    )

    # ------------------------------------------------------------------
    # Font: Helvetica Type1, NOT embedded
    # ------------------------------------------------------------------
    obj(
        font,
        "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica "
        "/Encoding /WinAnsiEncoding >>",
    )

    # ------------------------------------------------------------------
    # ExtGState objects
    # ------------------------------------------------------------------
    obj(gs_norm, "<< /Type /ExtGState >>")
    obj(gs_op, "<< /Type /ExtGState /OP true /op true /OPM 1 >>")
    obj(gs_trans, "<< /Type /ExtGState /ca 0.5 /CA 0.5 /BM /Multiply >>")

    # ------------------------------------------------------------------
    # Tint transform functions
    # ------------------------------------------------------------------
    # Regular spot: tint t -> CMYK (0, t, 0.5t, 0)
    obj(
        fn_spot,
        "<< /FunctionType 2 /Domain [0 1] "
        "/C0 [0 0 0 0] /C1 [0 1 0.5 0] /N 1 >>",
    )
    # Registration (All): tint t -> CMYK (t, t, t, t)
    obj(
        fn_all,
        "<< /FunctionType 2 /Domain [0 1] "
        "/C0 [0 0 0 0] /C1 [1 1 1 1] /N 1 >>",
    )
    # Shading interpolation: t -> tint [0..1]
    obj(
        fn_shading,
        "<< /FunctionType 2 /Domain [0 1] /C0 [0] /C1 [1] /N 1 >>",
    )

    # ------------------------------------------------------------------
    # Shading: axial gradient using spot colour
    # ------------------------------------------------------------------
    obj(
        shading1,
        f"<< /ShadingType 2 "
        f"/ColorSpace [/Separation /PantoneWarmRed /DeviceCMYK {fn_spot} 0 R] "
        f"/Coords [100 400 400 600] "
        f"/Function {fn_shading} 0 R "
        f"/Extend [true true] >>",
    )

    # ------------------------------------------------------------------
    # Images
    # ------------------------------------------------------------------
    img_w, img_h = 72, 72

    # RGB image (solid reddish, no ICC profile)
    rgb_raw = bytes([200, 50, 50]) * (img_w * img_h)
    rgb_z = zlib.compress(rgb_raw)
    img_stream(
        im_rgb,
        f"<< /Type /XObject /Subtype /Image /Width {img_w} /Height {img_h} "
        f"/ColorSpace /DeviceRGB /BitsPerComponent 8 "
        f"/SMask {im_mask} 0 R "
        f"/Filter /FlateDecode /Length __LENGTH__ >>",
        rgb_z,
    )

    # Alpha mask (gradient: opaque on left, transparent on right)
    mask_raw = bytearray()
    for y in range(img_h):
        for x in range(img_w):
            mask_raw.append(max(0, min(255, 255 - x * 255 // img_w)))
    mask_z = zlib.compress(bytes(mask_raw))
    img_stream(
        im_mask,
        f"<< /Type /XObject /Subtype /Image /Width {img_w} /Height {img_h} "
        f"/ColorSpace /DeviceGray /BitsPerComponent 8 "
        f"/Filter /FlateDecode /Length __LENGTH__ >>",
        mask_z,
    )

    # ------------------------------------------------------------------
    # Annotations
    # ------------------------------------------------------------------
    obj(
        annot_note,
        "<< /Type /Annot /Subtype /Text "
        "/Rect [50 750 70 770] "
        "/Contents (Review: this document has many preflight issues) "
        "/Open false /C [1 1 0] /T (Reviewer) >>",
    )
    obj(
        annot_widget,
        f"<< /Type /Annot /Subtype /Widget "
        f"/Rect [100 100 250 120] /P {page2} 0 R "
        f"/FT /Tx /T (TextField1) /V () >>",
    )

    # ==================================================================
    # PAGE 1 — A4 + non-uniform bleed, small text, RGB, low-res image
    #          with alpha, zero-width stroke, thin stroke, annotation
    # ==================================================================
    # TrimBox = A4 (595.276 x 841.89)
    # Bleed: 3mm (8.504pt) left/right/top, 5mm (14.173pt) bottom
    tb1 = [8.504, 14.173, 603.780, 850.394]
    mb1 = [0, 0, 612.284, 864.567]

    obj(
        page1,
        f"<< /Type /Page /Parent {pages} 0 R "
        f"/MediaBox [{mb1[0]:.3f} {mb1[1]:.3f} {mb1[2]:.3f} {mb1[3]:.3f}] "
        f"/TrimBox [{tb1[0]:.3f} {tb1[1]:.3f} {tb1[2]:.3f} {tb1[3]:.3f}] "
        f"/BleedBox [{mb1[0]:.3f} {mb1[1]:.3f} {mb1[2]:.3f} {mb1[3]:.3f}] "
        f"/Contents {cs1} 0 R "
        f"/Resources << "
        f"/Font << /F1 {font} 0 R >> "
        f"/XObject << /Im1 {im_rgb} 0 R >> "
        f"/ExtGState << /GS1 {gs_norm} 0 R >> "
        f">> "
        f"/Annots [{annot_note} 0 R] >>",
    )

    stream(
        cs1,
        "",
        # Light gray background (DeviceRGB)
        "q\n"
        "0.95 0.95 0.95 rg\n"
        f"0 0 {mb1[2]:.3f} {mb1[3]:.3f} re f\n"
        # Heading
        "BT /F1 14 Tf 0.15 0.15 0.6 rg 50 800 Td "
        "(PAGE 1: Mixed Issues) Tj ET\n"
        # Small text — 5pt (triggers fonts.size < 6)
        "BT /F1 5 Tf 0.3 0.3 0.3 rg 50 775 Td "
        "(This text is only 5pt - too small for production print!) Tj ET\n"
        # Even smaller — 4pt
        "BT /F1 4 Tf 0 0 0 rg 50 762 Td "
        "(Even smaller 4pt text that nobody can read) Tj ET\n"
        # Low-res image: 72x72 pixels at 200x200pt = ~26 PPI
        "q 200 0 0 200 50 520 cm /Im1 Do Q\n"
        # Caption
        "BT /F1 9 Tf 0 0 0 rg 50 505 Td "
        "(Low-res RGB image with alpha channel \\(26 PPI, no ICC\\)) Tj ET\n"
        # Zero-width stroke (triggers lines.zero_width)
        "0 w 0 0 0 RG 50 485 m 350 485 l S\n"
        # Very thin stroke 0.1pt (triggers lines.stroke_below)
        "0.1 w 0.6 0 0 RG 50 475 m 350 475 l S\n"
        # Descriptive text
        "BT /F1 8 Tf 0.5 0.5 0.5 rg 50 460 Td "
        "(Zero-width stroke above, 0.1pt stroke below) Tj ET\n"
        "Q\n",
    )

    # ==================================================================
    # PAGE 2 — US Letter, no trim box, art box, overprint, rich black,
    #          form widget, CMYK colours
    # ==================================================================
    obj(
        page2,
        f"<< /Type /Page /Parent {pages} 0 R "
        f"/MediaBox [0 0 612 792] "
        f"/ArtBox [36 36 576 756] "
        f"/Contents {cs2} 0 R "
        f"/Resources << "
        f"/Font << /F1 {font} 0 R >> "
        f"/ExtGState << /GS1 {gs_norm} 0 R /GS2 {gs_op} 0 R >> "
        f">> "
        f"/Annots [{annot_widget} 0 R] >>",
    )

    stream(
        cs2,
        "",
        "q\n"
        # White CMYK background
        "0 0 0 0 k 0 0 612 792 re f\n"
        # Heading
        "BT /F1 14 Tf 0 0 0 1 k 50 720 Td "
        "(PAGE 2: CMYK, Overprint, Rich Black) Tj ET\n"
        # Rich black fill: C60 M40 Y40 K100 (triggers colour.rich_black)
        "0.6 0.4 0.4 1.0 k 50 600 250 80 re f\n"
        "BT /F1 9 Tf 1 1 1 rg 60 630 Td (Rich Black C60/M40/Y40/K100) Tj ET\n"
        # Enable overprint
        "/GS2 gs\n"
        # Fill overprint — pure black CMYK (triggers colour.overprint fill)
        "0 0 0 1 k 50 490 250 80 re f\n"
        "BT /F1 9 Tf 1 1 1 rg 60 520 Td (Fill Overprint) Tj ET\n"
        # White overprint — CMYK 0,0,0,0 with OP active (triggers overprint white)
        "0 0 0 0 k 50 390 250 60 re f\n"
        "BT /F1 9 Tf 0 0 0 1 k 60 410 Td (White Overprint) Tj ET\n"
        # Stroke overprint (triggers colour.overprint stroke)
        "0 0 0 1 K 2 w 50 360 m 350 360 l S\n"
        # Text overprint (triggers colour.overprint text)
        "BT /F1 12 Tf 0 0 0 1 k 50 330 Td "
        "(This text has overprint enabled) Tj ET\n"
        # Reset overprint
        "/GS1 gs\n"
        "Q\n",
    )

    # ==================================================================
    # PAGE 3 — A4, zero bleed (trim=media), rotated 90°, spot colours,
    #          registration colour, unnamed spot, high ink CMYK
    # ==================================================================
    obj(
        page3,
        f"<< /Type /Page /Parent {pages} 0 R "
        f"/MediaBox [0 0 595.276 841.89] "
        f"/TrimBox [0 0 595.276 841.89] "
        f"/Rotate 90 "
        f"/Contents {cs3} 0 R "
        f"/Resources << "
        f"/Font << /F1 {font} 0 R >> "
        f"/ExtGState << /GS1 {gs_norm} 0 R >> "
        f"/ColorSpace << "
        f"/CS1 [/Separation /Pantone185C /DeviceCMYK {fn_spot} 0 R] "
        f"/CS2 [/Separation () /DeviceCMYK {fn_spot} 0 R] "
        f"/CS3 [/Separation /All /DeviceCMYK {fn_all} 0 R] "
        f">> >> >>",
    )

    stream(
        cs3,
        "",
        "q\n"
        # Heading
        "BT /F1 14 Tf 0 0 0 1 k 50 780 Td "
        "(PAGE 3: Spot Colours, High Ink, Rotation) Tj ET\n"
        # Pantone 185 C spot colour fill (triggers colour.spot_used)
        "/CS1 cs 1.0 scn 50 600 200 120 re f\n"
        "BT /F1 9 Tf 0 0 0 1 k 60 650 Td (Pantone 185 C) Tj ET\n"
        # Unnamed spot colour (triggers colour.unnamed_spot)
        "/CS2 cs 0.8 scn 300 600 120 120 re f\n"
        "BT /F1 9 Tf 0 0 0 1 k 310 650 Td (Unnamed Spot) Tj ET\n"
        # Registration colour — All (triggers colour.registration)
        "/CS3 cs 1.0 scn 470 600 80 80 re f\n"
        "BT /F1 9 Tf 0 0 0 1 k 475 630 Td (Reg) Tj ET\n"
        # High ink CMYK: C100 M80 Y60 K90 = 330% (triggers colour.ink_coverage)
        "1.0 0.8 0.6 0.9 k 50 420 300 120 re f\n"
        "BT /F1 9 Tf 1 1 1 rg 60 470 Td (330%% Ink Coverage) Tj ET\n"
        "Q\n",
    )

    # ==================================================================
    # PAGE 4 — A4, transparency group, reduced opacity, Multiply blend,
    #          gradient with spot colour
    # ==================================================================
    obj(
        page4,
        f"<< /Type /Page /Parent {pages} 0 R "
        f"/MediaBox [0 0 595.276 841.89] "
        f"/TrimBox [8.504 8.504 586.772 833.386] "
        f"/BleedBox [0 0 595.276 841.89] "
        f"/Group << /Type /Group /S /Transparency /CS /DeviceCMYK >> "
        f"/Contents {cs4} 0 R "
        f"/Resources << "
        f"/Font << /F1 {font} 0 R >> "
        f"/ExtGState << /GS1 {gs_norm} 0 R /GS3 {gs_trans} 0 R >> "
        f"/Shading << /Sh1 {shading1} 0 R >> "
        f">> >>",
    )

    stream(
        cs4,
        "",
        "q\n"
        # White background
        "1 1 1 rg 0 0 595.276 841.89 re f\n"
        # Heading (opaque)
        "BT /F1 14 Tf 0 0 0 rg 50 780 Td "
        "(PAGE 4: Transparency and Gradient) Tj ET\n"
        # Apply transparency ExtGState (50% opacity, Multiply blend)
        "/GS3 gs\n"
        # Semi-transparent blue rectangle
        "0.2 0.4 0.8 rg 50 600 300 130 re f\n"
        "BT /F1 10 Tf 0 0 0 rg 60 660 Td "
        "(50%% opacity, Multiply blend mode) Tj ET\n"
        # Semi-transparent overlapping rectangle
        "0.8 0.2 0.2 rg 150 560 300 130 re f\n"
        # Reset for gradient label
        "/GS1 gs\n"
        "BT /F1 10 Tf 0 0 0 rg 50 380 Td "
        "(Axial gradient using PantoneWarmRed spot colour:) Tj ET\n"
        # Paint shading with clip region
        "q 50 200 400 160 re W n /Sh1 sh Q\n"
        "Q\n",
    )

    # ==================================================================
    # Assemble PDF
    # ==================================================================
    buf = bytearray()
    buf.extend(b"%PDF-1.7\n%\xe2\xe3\xcf\xd3\n\n")

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

    # ------------------------------------------------------------------
    # Write output
    # ------------------------------------------------------------------
    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(bytes(buf))

    print(f"Generated: {output_path}")
    print(f"Size: {len(buf):,} bytes ({len(buf)/1024:.1f} KB)")
    print(f"Pages: 4")
    print()
    print("Expected preflight issues by check type:")
    print()
    print("  FILE")
    print("    file.interactive_elements  — form widget on page 2")
    print("    file.metadata.present      — Author field missing")
    print()
    print("  PDF")
    print("    pdf.annotations            — sticky note on page 1")
    print("    pdf.transparency           — transparency group + ExtGState on page 4")
    print("    pdf.all_text_outlined      — live text on all pages")
    print("    pdf.linearized             — not linearized")
    print("    pdf.tagged                 — not tagged")
    print("    pdf.conformance            — no PDF/X or PDF/A markers")
    print()
    print("  PAGES")
    print("    pages.mixed_sizes          — A4 (p1,3,4) vs US Letter (p2)")
    print("    pages.rotation             — page 3 rotated 90 degrees")
    print()
    print("  MARKS")
    print("    marks.trim_box_set         — page 2 has no trim box")
    print("    marks.art_slug_box         — page 2 has art box set")
    print("    marks.bleed_zero           — page 3 trim box = media box")
    print("    marks.bleed_nonzero        — pages 1, 4 have bleed")
    print("    marks.bleed_non_uniform    — page 1 has 5mm bottom / 3mm sides")
    print("    marks.bleed_greater_than   — page 1 bottom bleed is 5mm")
    print("    marks.bleed_less_than      — page 1 side bleeds are 3mm")
    print()
    print("  COLOUR")
    print("    colour.space_used          — DeviceRGB (p1), DeviceCMYK (p2-4)")
    print("    colour.spot_used           — Pantone185C, PantoneWarmRed")
    print("    colour.spot_count          — 4 spot colours total")
    print("    colour.registration        — All separation on page 3")
    print("    colour.unnamed_spot        — empty-name spot on page 3")
    print("    colour.rich_black          — C60/M40/Y40/K100 on page 2")
    print("    colour.ink_coverage        — 330% on page 3")
    print("    colour.overprint           — fill/stroke/text/white on page 2")
    print("    colour.named_gradient      — PantoneWarmRed in shading on page 4")
    print()
    print("  FONTS")
    print("    fonts.not_embedded         — Helvetica is not embedded")
    print("    fonts.type                 — Type1 font")
    print("    fonts.size                 — 4pt and 5pt text on page 1")
    print()
    print("  IMAGES")
    print("    images.alpha               — SMask on RGB image")
    print("    images.colour_mode         — DeviceRGB image")
    print("    images.icc_missing         — no ICC profile on image")
    print("    images.resolution_below    — ~26 PPI effective resolution")
    print("    images.scaled              — 72px scaled to 200pt")
    print()
    print("  LINES")
    print("    lines.zero_width           — 0pt stroke on page 1")
    print("    lines.stroke_below         — 0.1pt stroke on page 1")


if __name__ == "__main__":
    main()
