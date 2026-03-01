File
    File Size
        Greater than X
        Less than X
    Encryption
        Encrypted
        Not Encrypted
    Interactive Elements
        Present
        Not Present
    Metadata
        Field Present
        Field Not Present
        Field Matches Value
        Field Does Not Match Value
    Embedded Files / Attachments
        Present
        Not Present
    JavaScript
        Present
        Not Present

PDF
    PDF Version
        Is X
        Is Not X
            → Fixer: Set PDF Version [ghostscript]
    PDF Standard Compliance
        Conforms to X (e.g. PDF/X-1a, PDF/X-4, PDF/A-1b, PDF/UA-1)
        Does Not Conform to X
    Output Intent
        Present
        Not Present
    Linearized (Fast Web View)
        Is Set
        Is Not Set
    Tagged
        Is Tagged
        Is Not Tagged
    All Text Outlined
        Is Outlined
        Is Not Outlined
    Transparency
        Used
            → Fixer: Flatten Transparency [ghostscript]
        Not Used
    Layers (Optional Content Groups)
        Present
            → Fixer: Flatten Layers [ghostscript]
        Not Present
    Annotations
        Present
            → Fixer: Remove Annotations [pdfkit]
        Not Present

Pages
    Page Count
        Equals X
        Less than X
        More than X
    Page Size
        Matches X
        Does Not Match X
        Mixed Sizes Present
    Page Rotation
        Non-Zero Rotation Present

Marks & Bleed
    Bleed
        Zero
        Non-Zero
        Less than X
        Non-Zero and Less than X
        Greater than X
        Non-Uniform
    Trim Box
        Set
        Not Set
    Art / Slug Box
        Set
        Not Set

Colour
    Colour Space
        Is X
        Is Not X
            → Fixer: Convert to CMYK [ghostscript]
    Text Colour Mode
        Is X
        Is Not X
            → Fixer: Convert to CMYK [ghostscript]
    Registration Colour
        Used
        Not Used
    Spot Colours
        Used
        Not Used
        Count Exceeds X
        Unnamed / Undefined Spot Colour Used
    Rich Black
        Used
            → Fixer: Convert Rich Black [ghostscript]
        Not Used
    Overprint
        Overprint Fill Used
        Overprint Stroke Used
        Overprint Text Used
        White Overprint Used
    Ink Coverage (Colour Sum)
        Exceeds X%
            → Fixer: Limit Ink Coverage [ghostscript]
        Below X%
    Named Colour Used in Gradient

Fonts
    Embedding
        Used and Not Embedded
            → Fixer: Embed Fonts [ghostscript]
        Used and Embedded
    Font Type
        Is X (e.g. Type 1, TrueType, OpenType CFF)
        Is Not X
    Size
        Used Below X pt
        Used Above X pt

Images
    File Type
        Is X (e.g. JPEG, JPEG 2000, JBIG2, CCITT)
        Is Not X
    Colour Mode
        Is X
        Is Not X
    Resolution
        Below X PPI
        Above X PPI
            → Fixer: Downsample Images [ghostscript]
        Out of Range (combined min/max)
        Scaled (effective resolution differs from actual)
        Scaled Non-Proportionally
    ICC Profile
        Missing
            → Fixer: Assign Default ICC [ghostscript]
        Override Present
    Alpha Channel
        Present
            → Fixer: Flatten Alpha [ghostscript]
    Blend Mode
        Non-Normal Blend Mode Used
    Opacity
        Not 100%
    AI / GenAI Metadata
        Content Credentials Present
        GenAI Metadata Detected

Lines
    Stroke Weight
        Below X pt
        Zero Width (device-dependent hairline)

---

Proactive Tools (available regardless of check results)
    Add/Change Bleed [ghostscript]
    Change Page Size [ghostscript]
    Set PDF Version [ghostscript]
    Add Trim Marks [ghostscript]

Manual Fixes (no automation — user must fix in source application)
    Low resolution images — resupply at higher resolution, upsampling is destructive
    Missing fonts — install or relicense the font, then re-export
    Non-uniform bleed — adjust artboard/document setup in source application
    Page rotation — re-export with correct orientation from source
    Missing metadata fields — set in source application or Acrobat
    PDF/X conformance — re-export from source with correct PDF/X preset
    Spot colour cleanup — remap or delete spots in source application
    Overprint corrections — fix overprint attributes in source application
    JavaScript — remove in Acrobat or re-export clean
    Embedded files — remove in Acrobat or re-export clean
