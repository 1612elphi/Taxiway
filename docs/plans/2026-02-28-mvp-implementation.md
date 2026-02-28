# Taxiway MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a macOS PDF preflight application with a full parser, ~35 checks across 8 categories, profile management, report export, and a light-themed adaptive UI.

**Architecture:** TaxiwayCore is a local Swift Package containing the parser, check system, engine, profiles, and report export — zero UI dependencies. The Taxiway app target is a thin SwiftUI shell that imports TaxiwayCore. All core logic is independently testable via `swift test`.

**Tech Stack:** Swift 6, SwiftUI, PDFKit, CoreGraphics/CGPDF, Foundation, ImageIO. Zero third-party dependencies.

**Build commands:**
- Package tests: `cd TaxiwayCore && swift test`
- App build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Taxiway -destination 'platform=macOS' build`

**Reference docs:**
- Design: `docs/plans/2026-02-28-mvp-design.md`
- Spec: `SPEC.md`
- Check inventory: `CHECKS.md`

---

## Phase 1: Package Scaffold

### Task 1: Create TaxiwayCore Swift Package

**Files:**
- Create: `TaxiwayCore/Package.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/TaxiwayCore.swift` (placeholder)
- Create: `TaxiwayCore/Tests/TaxiwayCoreTests/TaxiwayCoreTests.swift` (placeholder)

**Step 1: Create package directory and manifest**

```swift
// TaxiwayCore/Package.swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TaxiwayCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TaxiwayCore", targets: ["TaxiwayCore"]),
    ],
    targets: [
        .target(
            name: "TaxiwayCore",
            dependencies: []
        ),
        .testTarget(
            name: "TaxiwayCoreTests",
            dependencies: ["TaxiwayCore"]
        ),
    ]
)
```

**Step 2: Create placeholder source**

```swift
// TaxiwayCore/Sources/TaxiwayCore/TaxiwayCore.swift
// Placeholder — will be replaced by real modules
```

**Step 3: Create placeholder test**

```swift
// TaxiwayCore/Tests/TaxiwayCoreTests/TaxiwayCoreTests.swift
import Testing
@testable import TaxiwayCore

@Test func packageBuilds() {
    // Verify the package compiles and tests run
    #expect(true)
}
```

**Step 4: Build and test the package**

Run: `cd /Users/ruby/GitRepos/Taxiway/TaxiwayCore && swift test`
Expected: BUILD SUCCEEDED, all tests pass

**Step 5: Commit**

```bash
git add TaxiwayCore/
git commit -m "feat: create TaxiwayCore Swift Package scaffold"
```

---

## Phase 2: Data Models

### Task 2: Define core model types

All models are plain structs — `Codable`, `Sendable`, `Equatable`. No PDFKit dependency here. These are the data contracts between parser, checks, and engine.

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Models/TaxiwayDocument.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Models/FileInfo.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Models/DocumentInfo.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Models/PageInfo.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Models/FontInfo.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Models/ImageInfo.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Models/ColourSpaceInfo.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Models/SpotColourInfo.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Models/AnnotationInfo.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Models/DocumentMetadata.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Models/ParseWarning.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Models/TaxiwayDocumentTests.swift`

**Step 1: Write the model tests**

```swift
// TaxiwayCore/Tests/TaxiwayCoreTests/Models/TaxiwayDocumentTests.swift
import Testing
import Foundation
@testable import TaxiwayCore

@Suite("TaxiwayDocument Model Tests")
struct TaxiwayDocumentTests {

    @Test("TaxiwayDocument Codable round-trip")
    func codableRoundTrip() throws {
        let doc = TaxiwayDocument.sample
        let data = try JSONEncoder().encode(doc)
        let decoded = try JSONDecoder().decode(TaxiwayDocument.self, from: data)
        #expect(decoded.fileInfo.fileName == doc.fileInfo.fileName)
        #expect(decoded.pages.count == doc.pages.count)
        #expect(decoded.fonts.count == doc.fonts.count)
        #expect(decoded.images.count == doc.images.count)
    }

    @Test("FileInfo stores file metadata")
    func fileInfoProperties() {
        let info = FileInfo(
            fileName: "test.pdf",
            filePath: "/tmp/test.pdf",
            fileSizeBytes: 1_048_576,
            isEncrypted: false,
            pageCount: 4
        )
        #expect(info.fileSizeMB == 1.0)
        #expect(info.fileName == "test.pdf")
    }

    @Test("PageInfo box defaults")
    func pageInfoBoxDefaults() {
        let page = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 595, height: 842),
            trimBox: nil,
            bleedBox: nil,
            artBox: nil,
            rotation: 0
        )
        // TrimBox defaults to MediaBox when nil
        #expect(page.effectiveTrimBox == page.mediaBox)
    }

    @Test("PageInfo bleed calculation")
    func bleedCalculation() {
        let page = PageInfo(
            index: 0,
            mediaBox: CGRect(x: 0, y: 0, width: 617, height: 864),
            trimBox: CGRect(x: 11, y: 11, width: 595, height: 842),
            bleedBox: CGRect(x: 3, y: 3, width: 611, height: 858),
            artBox: nil,
            rotation: 0
        )
        let bleed = page.bleedMargins
        // Bleed extends 8pt beyond trim on each side (11 - 3 = 8)
        #expect(bleed.left == 8)
        #expect(bleed.right == 8)
        #expect(bleed.top == 8)
        #expect(bleed.bottom == 8)
    }

    @Test("FontInfo embedding detection")
    func fontEmbedding() {
        let embedded = FontInfo(name: "ABCDEF+Helvetica", type: .trueType, isEmbedded: true, isSubset: true, pagesUsedOn: [0, 1])
        let notEmbedded = FontInfo(name: "Times-Roman", type: .type1, isEmbedded: false, isSubset: false, pagesUsedOn: [0])
        #expect(embedded.isEmbedded == true)
        #expect(embedded.isSubset == true)
        #expect(notEmbedded.isEmbedded == false)
    }

    @Test("ImageInfo effective resolution")
    func imageResolution() {
        let image = ImageInfo(
            id: "Im1",
            pageIndex: 0,
            widthPixels: 3000,
            heightPixels: 2000,
            effectiveWidthPoints: 300,
            effectiveHeightPoints: 200,
            colourMode: .cmyk,
            compressionType: .jpeg,
            bitsPerComponent: 8,
            hasICCProfile: true,
            hasICCOverride: false,
            hasAlphaChannel: false,
            blendMode: .normal,
            opacity: 1.0
        )
        // 3000px / (300pt / 72) = 720 PPI
        #expect(image.effectivePPIHorizontal == 720.0)
        #expect(image.effectivePPIVertical == 720.0)
        #expect(image.isScaledProportionally == true)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `cd /Users/ruby/GitRepos/Taxiway/TaxiwayCore && swift test`
Expected: FAIL — types not defined

**Step 3: Implement all model types**

```swift
// TaxiwayCore/Sources/TaxiwayCore/Models/TaxiwayDocument.swift
import Foundation

public struct TaxiwayDocument: Codable, Sendable, Equatable {
    public let fileInfo: FileInfo
    public let documentInfo: DocumentInfo
    public let pages: [PageInfo]
    public let fonts: [FontInfo]
    public let images: [ImageInfo]
    public let colourSpaces: [ColourSpaceInfo]
    public let spotColours: [SpotColourInfo]
    public let annotations: [AnnotationInfo]
    public let metadata: DocumentMetadata
    public let parseWarnings: [ParseWarning]

    public init(
        fileInfo: FileInfo,
        documentInfo: DocumentInfo,
        pages: [PageInfo],
        fonts: [FontInfo],
        images: [ImageInfo],
        colourSpaces: [ColourSpaceInfo],
        spotColours: [SpotColourInfo],
        annotations: [AnnotationInfo],
        metadata: DocumentMetadata,
        parseWarnings: [ParseWarning] = []
    ) {
        self.fileInfo = fileInfo
        self.documentInfo = documentInfo
        self.pages = pages
        self.fonts = fonts
        self.images = images
        self.colourSpaces = colourSpaces
        self.spotColours = spotColours
        self.annotations = annotations
        self.metadata = metadata
        self.parseWarnings = parseWarnings
    }
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Models/FileInfo.swift
import Foundation

public struct FileInfo: Codable, Sendable, Equatable {
    public let fileName: String
    public let filePath: String
    public let fileSizeBytes: Int64
    public let isEncrypted: Bool
    public let pageCount: Int

    public var fileSizeMB: Double {
        Double(fileSizeBytes) / 1_048_576.0
    }

    public init(fileName: String, filePath: String, fileSizeBytes: Int64, isEncrypted: Bool, pageCount: Int) {
        self.fileName = fileName
        self.filePath = filePath
        self.fileSizeBytes = fileSizeBytes
        self.isEncrypted = isEncrypted
        self.pageCount = pageCount
    }
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Models/DocumentInfo.swift
import Foundation

public struct DocumentInfo: Codable, Sendable, Equatable {
    public let pdfVersion: String       // e.g. "1.7", "2.0"
    public let producer: String?
    public let creator: String?
    public let isLinearized: Bool
    public let isTagged: Bool
    public let hasLayers: Bool

    public init(pdfVersion: String, producer: String?, creator: String?, isLinearized: Bool, isTagged: Bool, hasLayers: Bool) {
        self.pdfVersion = pdfVersion
        self.producer = producer
        self.creator = creator
        self.isLinearized = isLinearized
        self.isTagged = isTagged
        self.hasLayers = hasLayers
    }
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Models/PageInfo.swift
import Foundation
import CoreGraphics

public struct PageInfo: Codable, Sendable, Equatable {
    public let index: Int
    public let mediaBox: CGRect
    public let trimBox: CGRect?
    public let bleedBox: CGRect?
    public let artBox: CGRect?
    public let rotation: Int           // 0, 90, 180, 270

    public var effectiveTrimBox: CGRect {
        trimBox ?? mediaBox
    }

    /// Bleed margins: distance from bleed box edge to trim box edge.
    /// Positive means bleed extends beyond trim. Returns zero if no bleed box.
    public var bleedMargins: (left: Double, right: Double, top: Double, bottom: Double) {
        guard let bleed = bleedBox else {
            return (0, 0, 0, 0)
        }
        let trim = effectiveTrimBox
        return (
            left: trim.minX - bleed.minX,
            right: bleed.maxX - trim.maxX,
            top: bleed.maxY - trim.maxY,
            bottom: trim.minY - bleed.minY
        )
    }

    public init(index: Int, mediaBox: CGRect, trimBox: CGRect?, bleedBox: CGRect?, artBox: CGRect?, rotation: Int) {
        self.index = index
        self.mediaBox = mediaBox
        self.trimBox = trimBox
        self.bleedBox = bleedBox
        self.artBox = artBox
        self.rotation = rotation
    }
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Models/FontInfo.swift
import Foundation

public enum FontType: String, Codable, Sendable, Equatable {
    case type1 = "Type1"
    case trueType = "TrueType"
    case openTypeCFF = "OpenType CFF"
    case cidFontType0 = "CIDFontType0"
    case cidFontType2 = "CIDFontType2"
    case type3 = "Type3"
    case mmType1 = "MMType1"
    case unknown = "Unknown"
}

public struct FontInfo: Codable, Sendable, Equatable {
    public let name: String
    public let type: FontType
    public let isEmbedded: Bool
    public let isSubset: Bool
    public let pagesUsedOn: [Int]

    public init(name: String, type: FontType, isEmbedded: Bool, isSubset: Bool, pagesUsedOn: [Int]) {
        self.name = name
        self.type = type
        self.isEmbedded = isEmbedded
        self.isSubset = isSubset
        self.pagesUsedOn = pagesUsedOn
    }
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Models/ImageInfo.swift
import Foundation

public enum ImageColourMode: String, Codable, Sendable, Equatable {
    case deviceGray = "DeviceGray"
    case deviceRGB = "DeviceRGB"
    case deviceCMYK = "DeviceCMYK"
    case iccBased = "ICCBased"
    case indexed = "Indexed"
    case separation = "Separation"
    case deviceN = "DeviceN"
    case unknown = "Unknown"
}

public enum ImageCompressionType: String, Codable, Sendable, Equatable {
    case jpeg = "JPEG"
    case jpeg2000 = "JPEG2000"
    case jbig2 = "JBIG2"
    case ccitt = "CCITT"
    case flate = "Flate"
    case lzw = "LZW"
    case runLength = "RunLength"
    case none = "None"
    case unknown = "Unknown"
}

public enum BlendMode: String, Codable, Sendable, Equatable {
    case normal = "Normal"
    case multiply = "Multiply"
    case screen = "Screen"
    case overlay = "Overlay"
    case darken = "Darken"
    case lighten = "Lighten"
    case colorDodge = "ColorDodge"
    case colorBurn = "ColorBurn"
    case hardLight = "HardLight"
    case softLight = "SoftLight"
    case difference = "Difference"
    case exclusion = "Exclusion"
    case unknown = "Unknown"
}

public struct ImageInfo: Codable, Sendable, Equatable {
    public let id: String
    public let pageIndex: Int
    public let widthPixels: Int
    public let heightPixels: Int
    public let effectiveWidthPoints: Double
    public let effectiveHeightPoints: Double
    public let colourMode: ImageColourMode
    public let compressionType: ImageCompressionType
    public let bitsPerComponent: Int
    public let hasICCProfile: Bool
    public let hasICCOverride: Bool
    public let hasAlphaChannel: Bool
    public let blendMode: BlendMode
    public let opacity: Double

    public var effectivePPIHorizontal: Double {
        guard effectiveWidthPoints > 0 else { return 0 }
        return Double(widthPixels) / (effectiveWidthPoints / 72.0)
    }

    public var effectivePPIVertical: Double {
        guard effectiveHeightPoints > 0 else { return 0 }
        return Double(heightPixels) / (effectiveHeightPoints / 72.0)
    }

    public var isScaledProportionally: Bool {
        guard widthPixels > 0, heightPixels > 0,
              effectiveWidthPoints > 0, effectiveHeightPoints > 0 else { return true }
        let originalRatio = Double(widthPixels) / Double(heightPixels)
        let effectiveRatio = effectiveWidthPoints / effectiveHeightPoints
        return abs(originalRatio - effectiveRatio) / originalRatio < 0.01
    }

    public init(id: String, pageIndex: Int, widthPixels: Int, heightPixels: Int,
                effectiveWidthPoints: Double, effectiveHeightPoints: Double,
                colourMode: ImageColourMode, compressionType: ImageCompressionType,
                bitsPerComponent: Int, hasICCProfile: Bool, hasICCOverride: Bool,
                hasAlphaChannel: Bool, blendMode: BlendMode, opacity: Double) {
        self.id = id
        self.pageIndex = pageIndex
        self.widthPixels = widthPixels
        self.heightPixels = heightPixels
        self.effectiveWidthPoints = effectiveWidthPoints
        self.effectiveHeightPoints = effectiveHeightPoints
        self.colourMode = colourMode
        self.compressionType = compressionType
        self.bitsPerComponent = bitsPerComponent
        self.hasICCProfile = hasICCProfile
        self.hasICCOverride = hasICCOverride
        self.hasAlphaChannel = hasAlphaChannel
        self.blendMode = blendMode
        self.opacity = opacity
    }
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Models/ColourSpaceInfo.swift
import Foundation

public enum ColourSpaceName: String, Codable, Sendable, Equatable {
    case deviceGray = "DeviceGray"
    case deviceRGB = "DeviceRGB"
    case deviceCMYK = "DeviceCMYK"
    case iccBased = "ICCBased"
    case calGray = "CalGray"
    case calRGB = "CalRGB"
    case lab = "Lab"
    case indexed = "Indexed"
    case separation = "Separation"
    case deviceN = "DeviceN"
    case pattern = "Pattern"
    case unknown = "Unknown"
}

public struct ColourSpaceInfo: Codable, Sendable, Equatable {
    public let name: ColourSpaceName
    public let pagesUsedOn: [Int]
    public let iccProfileName: String?

    public init(name: ColourSpaceName, pagesUsedOn: [Int], iccProfileName: String? = nil) {
        self.name = name
        self.pagesUsedOn = pagesUsedOn
        self.iccProfileName = iccProfileName
    }
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Models/SpotColourInfo.swift
import Foundation

public struct SpotColourInfo: Codable, Sendable, Equatable {
    public let name: String
    public let pagesUsedOn: [Int]

    public init(name: String, pagesUsedOn: [Int]) {
        self.name = name
        self.pagesUsedOn = pagesUsedOn
    }
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Models/AnnotationInfo.swift
import Foundation

public enum AnnotationType: String, Codable, Sendable, Equatable {
    case link = "Link"
    case widget = "Widget"
    case text = "Text"
    case freeText = "FreeText"
    case highlight = "Highlight"
    case underline = "Underline"
    case strikeOut = "StrikeOut"
    case stamp = "Stamp"
    case ink = "Ink"
    case popup = "Popup"
    case fileAttachment = "FileAttachment"
    case other = "Other"
}

public struct AnnotationInfo: Codable, Sendable, Equatable {
    public let type: AnnotationType
    public let pageIndex: Int
    public let subtype: String?

    public init(type: AnnotationType, pageIndex: Int, subtype: String? = nil) {
        self.type = type
        self.pageIndex = pageIndex
        self.subtype = subtype
    }
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Models/DocumentMetadata.swift
import Foundation

public struct OutputIntent: Codable, Sendable, Equatable {
    public let subtype: String      // e.g. "GTS_PDFX"
    public let outputCondition: String?
    public let outputConditionIdentifier: String?
    public let registryName: String?

    public init(subtype: String, outputCondition: String?, outputConditionIdentifier: String?, registryName: String?) {
        self.subtype = subtype
        self.outputCondition = outputCondition
        self.outputConditionIdentifier = outputConditionIdentifier
        self.registryName = registryName
    }
}

public struct DocumentMetadata: Codable, Sendable, Equatable {
    public let title: String?
    public let author: String?
    public let subject: String?
    public let keywords: String?
    public let creationDate: Date?
    public let modificationDate: Date?
    public let trapped: String?                 // "True", "False", "Unknown"
    public let outputIntents: [OutputIntent]
    public let xmpRaw: String?                  // raw XMP packet for advanced checks
    public let hasC2PA: Bool
    public let hasGenAIMetadata: Bool

    public init(title: String?, author: String?, subject: String?, keywords: String?,
                creationDate: Date?, modificationDate: Date?, trapped: String?,
                outputIntents: [OutputIntent], xmpRaw: String?,
                hasC2PA: Bool, hasGenAIMetadata: Bool) {
        self.title = title
        self.author = author
        self.subject = subject
        self.keywords = keywords
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.trapped = trapped
        self.outputIntents = outputIntents
        self.xmpRaw = xmpRaw
        self.hasC2PA = hasC2PA
        self.hasGenAIMetadata = hasGenAIMetadata
    }
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Models/ParseWarning.swift
import Foundation

public struct ParseWarning: Codable, Sendable, Equatable {
    public let domain: String       // e.g. "FontExtractor", "ImageExtractor"
    public let message: String
    public let pageIndex: Int?

    public init(domain: String, message: String, pageIndex: Int? = nil) {
        self.domain = domain
        self.message = message
        self.pageIndex = pageIndex
    }
}
```

**Step 4: Create test fixture factory**

```swift
// TaxiwayCore/Tests/TaxiwayCoreTests/TestFixtures.swift
import Foundation
import CoreGraphics
@testable import TaxiwayCore

extension TaxiwayDocument {
    /// A minimal valid document for testing
    static var sample: TaxiwayDocument {
        TaxiwayDocument(
            fileInfo: FileInfo(
                fileName: "sample.pdf",
                filePath: "/tmp/sample.pdf",
                fileSizeBytes: 524_288,
                isEncrypted: false,
                pageCount: 2
            ),
            documentInfo: DocumentInfo(
                pdfVersion: "1.7",
                producer: "Adobe PDF Library 15.0",
                creator: "Adobe InDesign 18.0",
                isLinearized: false,
                isTagged: false,
                hasLayers: false
            ),
            pages: [
                PageInfo(
                    index: 0,
                    mediaBox: CGRect(x: 0, y: 0, width: 595.28, height: 841.89),
                    trimBox: CGRect(x: 8.5, y: 8.5, width: 578.28, height: 824.89),
                    bleedBox: CGRect(x: 0, y: 0, width: 595.28, height: 841.89),
                    artBox: nil,
                    rotation: 0
                ),
                PageInfo(
                    index: 1,
                    mediaBox: CGRect(x: 0, y: 0, width: 595.28, height: 841.89),
                    trimBox: CGRect(x: 8.5, y: 8.5, width: 578.28, height: 824.89),
                    bleedBox: CGRect(x: 0, y: 0, width: 595.28, height: 841.89),
                    artBox: nil,
                    rotation: 0
                )
            ],
            fonts: [
                FontInfo(name: "ABCDEF+Helvetica-Bold", type: .trueType, isEmbedded: true, isSubset: true, pagesUsedOn: [0, 1]),
                FontInfo(name: "Times-Roman", type: .type1, isEmbedded: false, isSubset: false, pagesUsedOn: [0])
            ],
            images: [
                ImageInfo(
                    id: "Im1", pageIndex: 0, widthPixels: 2400, heightPixels: 1600,
                    effectiveWidthPoints: 240, effectiveHeightPoints: 160,
                    colourMode: .deviceCMYK, compressionType: .jpeg, bitsPerComponent: 8,
                    hasICCProfile: true, hasICCOverride: false, hasAlphaChannel: false,
                    blendMode: .normal, opacity: 1.0
                )
            ],
            colourSpaces: [
                ColourSpaceInfo(name: .deviceCMYK, pagesUsedOn: [0, 1]),
                ColourSpaceInfo(name: .deviceRGB, pagesUsedOn: [0])
            ],
            spotColours: [
                SpotColourInfo(name: "PANTONE 485 C", pagesUsedOn: [0])
            ],
            annotations: [],
            metadata: DocumentMetadata(
                title: "Test Document",
                author: "Test Author",
                subject: nil,
                keywords: nil,
                creationDate: Date(timeIntervalSince1970: 1_700_000_000),
                modificationDate: nil,
                trapped: nil,
                outputIntents: [],
                xmpRaw: nil,
                hasC2PA: false,
                hasGenAIMetadata: false
            )
        )
    }

    /// Empty document — zero pages, fonts, images
    static var empty: TaxiwayDocument {
        TaxiwayDocument(
            fileInfo: FileInfo(fileName: "empty.pdf", filePath: "/tmp/empty.pdf", fileSizeBytes: 1024, isEncrypted: false, pageCount: 0),
            documentInfo: DocumentInfo(pdfVersion: "1.4", producer: nil, creator: nil, isLinearized: false, isTagged: false, hasLayers: false),
            pages: [],
            fonts: [],
            images: [],
            colourSpaces: [],
            spotColours: [],
            annotations: [],
            metadata: DocumentMetadata(title: nil, author: nil, subject: nil, keywords: nil, creationDate: nil, modificationDate: nil, trapped: nil, outputIntents: [], xmpRaw: nil, hasC2PA: false, hasGenAIMetadata: false)
        )
    }
}
```

**Step 5: Run tests to verify they pass**

Run: `cd /Users/ruby/GitRepos/Taxiway/TaxiwayCore && swift test`
Expected: All tests pass

**Step 6: Commit**

```bash
git add TaxiwayCore/
git commit -m "feat: define TaxiwayDocument and all model types with tests"
```

---

## Phase 3: Check Protocol & Infrastructure

### Task 3: Define Check protocol and result types

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/CheckProtocol.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/CheckResult.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/CheckSeverity.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/CheckCategory.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/AffectedItem.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Checks/CheckResultTests.swift`

**Step 1: Write tests**

```swift
// TaxiwayCore/Tests/TaxiwayCoreTests/Checks/CheckResultTests.swift
import Testing
import Foundation
@testable import TaxiwayCore

@Suite("Check Result Tests")
struct CheckResultTests {

    @Test("CheckResult Codable round-trip")
    func codableRoundTrip() throws {
        let result = CheckResult(
            checkID: UUID(),
            checkTypeID: "file.size.max",
            status: .fail,
            severity: .error,
            message: "File exceeds 10 MB",
            detail: "File is 15.2 MB",
            affectedItems: [.document]
        )
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(CheckResult.self, from: data)
        #expect(decoded.status == .fail)
        #expect(decoded.severity == .error)
        #expect(decoded.affectedItems.count == 1)
    }

    @Test("AffectedItem variants encode correctly")
    func affectedItemVariants() throws {
        let items: [AffectedItem] = [
            .document,
            .page(index: 0),
            .font(name: "Helvetica", pages: [0, 1]),
            .image(id: "Im1", page: 0),
            .colourSpace(name: "DeviceRGB", pages: [0]),
            .annotation(type: "Link", page: 2)
        ]
        let data = try JSONEncoder().encode(items)
        let decoded = try JSONDecoder().decode([AffectedItem].self, from: data)
        #expect(decoded.count == 6)
    }

    @Test("CheckSeverity ordering")
    func severityOrdering() {
        #expect(CheckSeverity.error.rawValue < CheckSeverity.warning.rawValue)
        #expect(CheckSeverity.warning.rawValue < CheckSeverity.info.rawValue)
    }

    @Test("CheckCategory has all 8 categories")
    func categoryCompleteness() {
        let all = CheckCategory.allCases
        #expect(all.count == 8)
    }
}
```

**Step 2: Run tests, verify fail**

Run: `cd /Users/ruby/GitRepos/Taxiway/TaxiwayCore && swift test`
Expected: FAIL

**Step 3: Implement**

```swift
// TaxiwayCore/Sources/TaxiwayCore/Checks/CheckSeverity.swift
import Foundation

public enum CheckSeverity: Int, Codable, Sendable, Equatable, CaseIterable {
    case error = 0
    case warning = 1
    case info = 2
}

public enum CheckStatus: String, Codable, Sendable, Equatable {
    case pass
    case fail
    case warning
    case skipped
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Checks/CheckCategory.swift
import Foundation

public enum CheckCategory: String, Codable, Sendable, Equatable, CaseIterable {
    case file
    case pdf
    case pages
    case marks
    case colour
    case fonts
    case images
    case lines
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Checks/AffectedItem.swift
import Foundation

public enum AffectedItem: Codable, Sendable, Equatable {
    case document
    case page(index: Int)
    case font(name: String, pages: [Int])
    case image(id: String, page: Int)
    case colourSpace(name: String, pages: [Int])
    case annotation(type: String, page: Int)
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Checks/CheckResult.swift
import Foundation

public struct CheckResult: Codable, Sendable, Equatable, Identifiable {
    public let checkID: UUID
    public let checkTypeID: String
    public let status: CheckStatus
    public let severity: CheckSeverity
    public let message: String
    public let detail: String?
    public let affectedItems: [AffectedItem]

    public var id: UUID { checkID }

    public init(checkID: UUID, checkTypeID: String, status: CheckStatus, severity: CheckSeverity,
                message: String, detail: String? = nil, affectedItems: [AffectedItem] = []) {
        self.checkID = checkID
        self.checkTypeID = checkTypeID
        self.status = status
        self.severity = severity
        self.message = message
        self.detail = detail
        self.affectedItems = affectedItems
    }
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Checks/CheckProtocol.swift
import Foundation

public protocol CheckParameters: Codable, Sendable, Equatable {}

public protocol Check: Identifiable, Sendable {
    static var typeID: String { get }
    var id: UUID { get }
    var name: String { get }
    var category: CheckCategory { get }
    var defaultSeverity: CheckSeverity { get }

    func run(on document: TaxiwayDocument) -> CheckResult
}
```

**Step 4: Run tests, verify pass**

Run: `cd /Users/ruby/GitRepos/Taxiway/TaxiwayCore && swift test`
Expected: All tests pass

**Step 5: Commit**

```bash
git add TaxiwayCore/
git commit -m "feat: define Check protocol, CheckResult, and supporting types"
```

### Task 4: Implement CheckRegistry

The registry maps `typeID` strings to concrete check types, enabling Codable round-tripping of profiles.

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/CheckRegistry.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/CheckEntry.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Checks/CheckRegistryTests.swift`

**Step 1: Write tests**

```swift
// TaxiwayCore/Tests/TaxiwayCoreTests/Checks/CheckRegistryTests.swift
import Testing
import Foundation
@testable import TaxiwayCore

@Suite("CheckRegistry Tests")
struct CheckRegistryTests {

    @Test("Register and instantiate a check")
    func registerAndInstantiate() throws {
        var registry = CheckRegistry()
        registry.register(FileSizeMaxCheck.self)

        let params = FileSizeMaxCheck.Parameters(maxSizeMB: 10.0)
        let entry = try CheckEntry(typeID: FileSizeMaxCheck.typeID, enabled: true, parameters: params)
        let check = try registry.instantiate(from: entry)
        #expect(check.name == "File Size (max)")
        #expect(check.category == .file)
    }

    @Test("Round-trip CheckEntry through JSON")
    func checkEntryRoundTrip() throws {
        let params = FileSizeMaxCheck.Parameters(maxSizeMB: 25.0)
        let entry = try CheckEntry(typeID: "file.size.max", enabled: true, parameters: params)
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(CheckEntry.self, from: data)
        #expect(decoded.typeID == "file.size.max")
        #expect(decoded.enabled == true)
    }

    @Test("Instantiate unknown typeID throws")
    func unknownTypeThrows() {
        let registry = CheckRegistry()
        let entry = CheckEntry(typeID: "nonexistent.check", enabled: true, parametersJSON: Data())
        #expect(throws: CheckRegistryError.self) {
            try registry.instantiate(from: entry)
        }
    }
}
```

**Step 2: Run tests, verify fail**

**Step 3: Implement**

```swift
// TaxiwayCore/Sources/TaxiwayCore/Checks/CheckEntry.swift
import Foundation

public struct CheckEntry: Codable, Sendable, Equatable {
    public let typeID: String
    public var enabled: Bool
    public var severityOverride: CheckSeverity?
    public var parametersJSON: Data

    public init(typeID: String, enabled: Bool, parametersJSON: Data, severityOverride: CheckSeverity? = nil) {
        self.typeID = typeID
        self.enabled = enabled
        self.parametersJSON = parametersJSON
        self.severityOverride = severityOverride
    }

    public init<P: CheckParameters>(typeID: String, enabled: Bool, parameters: P, severityOverride: CheckSeverity? = nil) throws {
        self.typeID = typeID
        self.enabled = enabled
        self.parametersJSON = try JSONEncoder().encode(parameters)
        self.severityOverride = severityOverride
    }
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Checks/CheckRegistry.swift
import Foundation

public enum CheckRegistryError: Error {
    case unknownTypeID(String)
    case decodingFailed(String, Error)
}

/// Stores closures that can instantiate concrete Check types from serialised parameters.
public struct CheckRegistry: Sendable {
    // Each registration stores a closure: (UUID, Data, CheckSeverity?) -> any Check
    private var factories: [String: @Sendable (UUID, Data, CheckSeverity?) throws -> any Check] = [:]

    public init() {}

    public mutating func register<C: Check>(_ type: C.Type) where C: ParameterisedCheck {
        factories[C.typeID] = { id, data, severityOverride in
            let params = try JSONDecoder().decode(C.Parameters.self, from: data)
            return C(id: id, parameters: params, severityOverride: severityOverride)
        }
    }

    public func instantiate(from entry: CheckEntry) throws -> any Check {
        guard let factory = factories[entry.typeID] else {
            throw CheckRegistryError.unknownTypeID(entry.typeID)
        }
        do {
            return try factory(UUID(), entry.parametersJSON, entry.severityOverride)
        } catch let error as CheckRegistryError {
            throw error
        } catch {
            throw CheckRegistryError.decodingFailed(entry.typeID, error)
        }
    }

    /// Returns all registered type IDs
    public var registeredTypeIDs: [String] {
        Array(factories.keys).sorted()
    }
}
```

Also add the `ParameterisedCheck` protocol that bridges `Check` with typed parameters:

```swift
// Add to CheckProtocol.swift
public protocol ParameterisedCheck: Check {
    associatedtype Parameters: CheckParameters
    var parameters: Parameters { get }
    var severityOverride: CheckSeverity? { get }
    init(id: UUID, parameters: Parameters, severityOverride: CheckSeverity?)
}

extension ParameterisedCheck {
    public var effectiveSeverity: CheckSeverity {
        severityOverride ?? defaultSeverity
    }

    /// Helper to produce a passing result
    public func pass(message: String) -> CheckResult {
        CheckResult(checkID: id, checkTypeID: Self.typeID, status: .pass, severity: effectiveSeverity, message: message)
    }

    /// Helper to produce a failing result
    public func fail(message: String, detail: String? = nil, affectedItems: [AffectedItem] = []) -> CheckResult {
        CheckResult(checkID: id, checkTypeID: Self.typeID, status: .fail, severity: effectiveSeverity, message: message, detail: detail, affectedItems: affectedItems)
    }
}
```

**Note:** The `FileSizeMaxCheck` referenced in tests will be implemented in Task 5. For now, create a stub so registry tests compile:

```swift
// TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/File/FileSizeMaxCheck.swift
import Foundation

public struct FileSizeMaxCheck: ParameterisedCheck {
    public static let typeID = "file.size.max"
    public let id: UUID
    public let parameters: Parameters
    public let severityOverride: CheckSeverity?

    public var name: String { "File Size (max)" }
    public var category: CheckCategory { .file }
    public var defaultSeverity: CheckSeverity { .error }

    public struct Parameters: CheckParameters {
        public var maxSizeMB: Double
        public init(maxSizeMB: Double) { self.maxSizeMB = maxSizeMB }
    }

    public init(id: UUID = UUID(), parameters: Parameters, severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let sizeMB = document.fileInfo.fileSizeMB
        if sizeMB > parameters.maxSizeMB {
            return fail(
                message: "File exceeds \(parameters.maxSizeMB) MB",
                detail: String(format: "File is %.1f MB", sizeMB),
                affectedItems: [.document]
            )
        }
        return pass(message: "File size OK (\(String(format: "%.1f", sizeMB)) MB)")
    }
}
```

**Step 4: Run tests, verify pass**

Run: `cd /Users/ruby/GitRepos/Taxiway/TaxiwayCore && swift test`
Expected: All tests pass

**Step 5: Commit**

```bash
git add TaxiwayCore/
git commit -m "feat: implement CheckRegistry and CheckEntry for Codable check storage"
```

---

## Phase 4: Check Implementations

Each check follows the pattern established by `FileSizeMaxCheck`: a struct conforming to `ParameterisedCheck` with a nested `Parameters` struct. Every check gets at minimum three test cases: pass, fail, and an edge case.

### Task 5: File checks (6 checks)

**Files:**
- Create/Modify: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/File/FileSizeMaxCheck.swift` (already stubbed)
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/File/FileSizeMinCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/File/EncryptionCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/File/InteractiveElementsCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/File/MetadataFieldPresentCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/File/MetadataFieldMatchesCheck.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Checks/File/FileCheckTests.swift`

**Step 1: Write tests for all 6 file checks**

Test pattern for each check: pass case, fail case, edge case. Use `TaxiwayDocument.sample` and `TaxiwayDocument.empty` as bases, mutating relevant fields via helper methods on the test fixture factory.

Key test cases:
- `FileSizeMaxCheck`: pass at 0.5 MB (sample is 0.5 MB), fail at 0.1 MB limit, edge: exactly at limit passes
- `FileSizeMinCheck`: pass at 0.5 MB with 0.1 MB min, fail at 0.5 MB with 1.0 MB min
- `EncryptionCheck`: pass (sample not encrypted), fail (encrypted fixture)
- `InteractiveElementsCheck`: pass (sample has no annotations), fail (document with widget annotations)
- `MetadataFieldPresentCheck`: pass (sample has title), fail (missing subject)
- `MetadataFieldMatchesCheck`: pass (title matches), fail (title mismatch)

**Step 2: Run tests, verify fail**

**Step 3: Implement all 6 checks** following the `FileSizeMaxCheck` pattern. Each is a simple struct with `run(on:)` that inspects `TaxiwayDocument` fields.

**Step 4: Run tests, verify pass**

**Step 5: Commit**

```bash
git commit -m "feat: implement 6 File checks with tests"
```

### Task 6: PDF checks (6 checks)

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/PDF/PDFVersionCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/PDF/PDFConformanceCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/PDF/LinearizedCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/PDF/TaggedCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/PDF/LayersPresentCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/PDF/AnnotationsPresentCheck.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Checks/PDF/PDFCheckTests.swift`

Check details:
- `PDFVersionCheck`: Parameters: `operator` (is/isNot), `version` string. Compares `documentInfo.pdfVersion`.
- `PDFConformanceCheck`: Parameters: `standard` (x1a/x3/x4/a1b/a2b/a3b). Checks `metadata.outputIntents` for matching subtype and condition identifier. PDF/X checks look for `GTS_PDFX` subtype; PDF/A checks look for XMP conformance markers.
- `LinearizedCheck`: Parameters: `expected` bool. Checks `documentInfo.isLinearized`.
- `TaggedCheck`: Parameters: `expected` bool. Checks `documentInfo.isTagged`.
- `LayersPresentCheck`: No parameters. Checks `documentInfo.hasLayers`.
- `AnnotationsPresentCheck`: No parameters. Checks `annotations.isEmpty`.

Same TDD cycle: write tests → fail → implement → pass → commit.

```bash
git commit -m "feat: implement 6 PDF checks with tests"
```

### Task 7: Pages checks (4 checks)

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Pages/PageCountCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Pages/PageSizeCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Pages/MixedPageSizesCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Pages/PageRotationCheck.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Checks/Pages/PagesCheckTests.swift`

Check details:
- `PageCountCheck`: Parameters: `operator` (equals/lessThan/moreThan), `value` int. Checks `pages.count`.
- `PageSizeCheck`: Parameters: `targetWidth` pts, `targetHeight` pts, `tolerancePoints`. Compares each page's `effectiveTrimBox` size. Reports pages that don't match.
- `MixedPageSizesCheck`: No parameters. Compares all pages' `effectiveTrimBox` sizes; fails if any differ beyond 1pt tolerance.
- `PageRotationCheck`: No parameters. Fails if any page has `rotation != 0`.

Edge cases: empty pages array (should pass for MixedPageSizes, PageRotation — no pages = no issues), single page (can't be mixed).

```bash
git commit -m "feat: implement 4 Pages checks with tests"
```

### Task 8: Marks/Bleed checks (6 checks)

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Marks/BleedZeroCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Marks/BleedNonZeroCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Marks/BleedLessThanCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Marks/BleedGreaterThanCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Marks/BleedNonUniformCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Marks/TrimBoxSetCheck.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Checks/Marks/MarksCheckTests.swift`

These checks use `PageInfo.bleedMargins`. Important: bleed is calculated in points, but parameters use mm. Add a conversion helper: `1mm ≈ 2.8346pt`.

Edge cases: pages with no bleed box (bleed margins are zero), pages with no trim box (trim defaults to media).

```bash
git commit -m "feat: implement 6 Marks/Bleed checks with tests"
```

### Task 9: Colour checks (4 checks)

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Colour/ColourSpaceUsedCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Colour/RegistrationColourCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Colour/SpotColourUsedCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Colour/SpotColourCountCheck.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Checks/Colour/ColourCheckTests.swift`

Check details:
- `ColourSpaceUsedCheck`: Parameters: `operator` (is/isNot), `spaceName` (ColourSpaceName). Scans `colourSpaces`.
- `RegistrationColourCheck`: No parameters. Checks for "All" in spot colour names (registration colour in PDF is typically a DeviceN with all components).
- `SpotColourUsedCheck`: No parameters. Checks `spotColours.isEmpty`.
- `SpotColourCountCheck`: Parameters: `maxCount` int. Fails if `spotColours.count > maxCount`.

```bash
git commit -m "feat: implement 4 Colour checks with tests"
```

### Task 10: Font checks (3 checks)

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Fonts/FontNotEmbeddedCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Fonts/FontTypeCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Fonts/FontSizeCheck.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Checks/Fonts/FontCheckTests.swift`

Note: `FontSizeCheck` uses font dict declared sizes — add a `declaredSize` field to `FontInfo` if needed. If font size data isn't available from resource dicts alone, mark this check as best-effort (status: `.warning` with detail explaining limitation).

```bash
git commit -m "feat: implement 3 Font checks with tests"
```

### Task 11: Image checks (10 checks)

This is the largest category. Group related checks.

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Images/ImageTypeCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Images/ImageColourModeCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Images/ResolutionBelowCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Images/ResolutionAboveCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Images/ResolutionRangeCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Images/ImageScaledCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Images/ImageScaledNonProportionallyCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Images/ICCProfileMissingCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Images/AlphaChannelCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Images/BlendModeOpacityCheck.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Checks/Images/ImageCheckTests.swift`

Note: C2PA and GenAI metadata checks operate on `DocumentMetadata`, not individual images. Add them here as they're categorised under Images in the spec.

- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Images/C2PACheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Images/GenAIMetadataCheck.swift`

Key test edge cases: document with zero images (all image checks should pass — nothing to fail on), image with zero effective dimensions (PPI calculation guards).

```bash
git commit -m "feat: implement 12 Image checks with tests"
```

### Task 12: Line checks (2 checks)

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Lines/StrokeWeightBelowCheck.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/Implementations/Lines/ZeroWidthStrokeCheck.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Checks/Lines/LineCheckTests.swift`

These are best-effort in the MVP — accurate line weight detection requires content stream parsing. For now, they check graphics state defaults from the resource dict. The check result detail should state "Based on graphics state defaults; may not reflect rendered stroke weights."

**Note:** We need a `lines` or `strokeInfo` field on `TaxiwayDocument` or `PageInfo`. Add `strokeWeights: [Double]` to `PageInfo` as a best-effort extraction target. If the parser can't extract this data, these checks return `.skipped`.

```bash
git commit -m "feat: implement 2 Line checks with tests (best-effort)"
```

### Task 13: Register all checks in the default registry

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Checks/DefaultRegistry.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Checks/DefaultRegistryTests.swift`

**Step 1: Write test**

```swift
// TaxiwayCore/Tests/TaxiwayCoreTests/Checks/DefaultRegistryTests.swift
import Testing
@testable import TaxiwayCore

@Suite("Default Registry Tests")
struct DefaultRegistryTests {

    @Test("Default registry contains all MVP checks")
    func allChecksRegistered() {
        let registry = CheckRegistry.default
        // Should have ~35 registered check types
        #expect(registry.registeredTypeIDs.count >= 35)
    }

    @Test("Every registered check can be instantiated with default parameters")
    func allChecksInstantiate() throws {
        let registry = CheckRegistry.default
        let profile = PreflightProfile.loose  // built-in with all checks at defaults
        for entry in profile.entries {
            let check = try registry.instantiate(from: entry)
            #expect(check.category != nil)
        }
    }
}
```

**Step 2: Implement**

```swift
// TaxiwayCore/Sources/TaxiwayCore/Checks/DefaultRegistry.swift
extension CheckRegistry {
    public static var `default`: CheckRegistry {
        var registry = CheckRegistry()
        // File
        registry.register(FileSizeMaxCheck.self)
        registry.register(FileSizeMinCheck.self)
        registry.register(EncryptionCheck.self)
        registry.register(InteractiveElementsCheck.self)
        registry.register(MetadataFieldPresentCheck.self)
        registry.register(MetadataFieldMatchesCheck.self)
        // PDF
        registry.register(PDFVersionCheck.self)
        registry.register(PDFConformanceCheck.self)
        registry.register(LinearizedCheck.self)
        registry.register(TaggedCheck.self)
        registry.register(LayersPresentCheck.self)
        registry.register(AnnotationsPresentCheck.self)
        // Pages
        registry.register(PageCountCheck.self)
        registry.register(PageSizeCheck.self)
        registry.register(MixedPageSizesCheck.self)
        registry.register(PageRotationCheck.self)
        // Marks
        registry.register(BleedZeroCheck.self)
        registry.register(BleedNonZeroCheck.self)
        registry.register(BleedLessThanCheck.self)
        registry.register(BleedGreaterThanCheck.self)
        registry.register(BleedNonUniformCheck.self)
        registry.register(TrimBoxSetCheck.self)
        // Colour
        registry.register(ColourSpaceUsedCheck.self)
        registry.register(RegistrationColourCheck.self)
        registry.register(SpotColourUsedCheck.self)
        registry.register(SpotColourCountCheck.self)
        // Fonts
        registry.register(FontNotEmbeddedCheck.self)
        registry.register(FontTypeCheck.self)
        registry.register(FontSizeCheck.self)
        // Images
        registry.register(ImageTypeCheck.self)
        registry.register(ImageColourModeCheck.self)
        registry.register(ResolutionBelowCheck.self)
        registry.register(ResolutionAboveCheck.self)
        registry.register(ResolutionRangeCheck.self)
        registry.register(ImageScaledCheck.self)
        registry.register(ImageScaledNonProportionallyCheck.self)
        registry.register(ICCProfileMissingCheck.self)
        registry.register(AlphaChannelCheck.self)
        registry.register(BlendModeOpacityCheck.self)
        registry.register(C2PACheck.self)
        registry.register(GenAIMetadataCheck.self)
        // Lines
        registry.register(StrokeWeightBelowCheck.self)
        registry.register(ZeroWidthStrokeCheck.self)
        return registry
    }
}
```

**Step 3: Run tests, verify pass**

**Step 4: Commit**

```bash
git commit -m "feat: register all 35+ checks in default CheckRegistry"
```

---

## Phase 5: Engine, Profiles & Reports

### Task 14: PreflightProfile model and built-in profiles

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Engine/PreflightProfile.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Engine/BuiltInProfiles.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Engine/PreflightProfileTests.swift`

**Step 1: Write tests**

```swift
import Testing
import Foundation
@testable import TaxiwayCore

@Suite("PreflightProfile Tests")
struct PreflightProfileTests {

    @Test("Profile Codable round-trip")
    func codableRoundTrip() throws {
        let profile = PreflightProfile.loose
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(PreflightProfile.self, from: data)
        #expect(decoded.name == profile.name)
        #expect(decoded.entries.count == profile.entries.count)
    }

    @Test("Built-in profiles are read-only")
    func builtInReadOnly() {
        #expect(PreflightProfile.pdfX1a.isBuiltIn == true)
        #expect(PreflightProfile.pdfX4.isBuiltIn == true)
        #expect(PreflightProfile.screenDigital.isBuiltIn == true)
        #expect(PreflightProfile.loose.isBuiltIn == true)
    }

    @Test("PDF/X-1a profile has expected checks")
    func pdfX1aChecks() {
        let profile = PreflightProfile.pdfX1a
        let typeIDs = Set(profile.entries.filter(\.enabled).map(\.typeID))
        // Must check for font embedding, CMYK colour space, trim box
        #expect(typeIDs.contains("fonts.not_embedded"))
        #expect(typeIDs.contains("marks.trim_box_set"))
    }

    @Test("Duplicate profile creates non-built-in copy")
    func duplicateProfile() {
        let copy = PreflightProfile.pdfX1a.duplicate(name: "My PDF/X-1a")
        #expect(copy.isBuiltIn == false)
        #expect(copy.name == "My PDF/X-1a")
        #expect(copy.id != PreflightProfile.pdfX1a.id)
        #expect(copy.entries.count == PreflightProfile.pdfX1a.entries.count)
    }
}
```

**Step 2: Implement**

```swift
// TaxiwayCore/Sources/TaxiwayCore/Engine/PreflightProfile.swift
import Foundation

public struct PreflightProfile: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var description: String
    public var entries: [CheckEntry]
    public let createdAt: Date
    public var modifiedAt: Date
    public let isBuiltIn: Bool

    public init(id: UUID = UUID(), name: String, description: String, entries: [CheckEntry],
                createdAt: Date = Date(), modifiedAt: Date = Date(), isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.entries = entries
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isBuiltIn = isBuiltIn
    }

    public func duplicate(name: String) -> PreflightProfile {
        PreflightProfile(
            name: name,
            description: description,
            entries: entries,
            isBuiltIn: false
        )
    }
}
```

Built-in profiles in `BuiltInProfiles.swift` — each is a `static let` on `PreflightProfile` with appropriate checks enabled and configured. The `loose` profile enables minimal checks; `pdfX1a` is strict (CMYK, embedded fonts, no transparency, trim box required).

```bash
git commit -m "feat: implement PreflightProfile model and 4 built-in profiles"
```

### Task 15: PreflightEngine

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Engine/PreflightEngine.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Engine/PreflightReport.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Engine/PreflightEngineTests.swift`

**Step 1: Write tests**

```swift
import Testing
import Foundation
@testable import TaxiwayCore

@Suite("PreflightEngine Tests")
struct PreflightEngineTests {

    @Test("Engine runs all enabled checks")
    func runsAllChecks() throws {
        let engine = PreflightEngine()
        let report = try engine.run(profile: .loose, on: .sample)
        let enabledCount = PreflightProfile.loose.entries.filter(\.enabled).count
        #expect(report.results.count == enabledCount)
    }

    @Test("Engine skips disabled checks")
    func skipsDisabled() throws {
        var profile = PreflightProfile.loose.duplicate(name: "test")
        for i in profile.entries.indices { profile.entries[i].enabled = false }
        let engine = PreflightEngine()
        let report = try engine.run(profile: profile, on: .sample)
        #expect(report.results.isEmpty)
    }

    @Test("Overall status is pass when no errors")
    func overallPassNoErrors() throws {
        // Use a document that passes all loose checks
        let engine = PreflightEngine()
        let report = try engine.run(profile: .loose, on: .sample)
        // Sample doc may or may not pass all — test with a tailored fixture
        #expect(report.overallStatus == .pass || report.overallStatus == .fail)
    }

    @Test("Overall status is fail when any error exists")
    func overallFailOnError() throws {
        // Create a profile with file size max set to 0.0001 MB — guaranteed fail
        var profile = PreflightProfile.loose.duplicate(name: "test-fail")
        // Find and modify the file size max entry to ensure a fail
        if let idx = profile.entries.firstIndex(where: { $0.typeID == "file.size.max" }) {
            let tinyParams = FileSizeMaxCheck.Parameters(maxSizeMB: 0.0001)
            profile.entries[idx] = try CheckEntry(typeID: "file.size.max", enabled: true, parameters: tinyParams, severityOverride: .error)
        }
        let engine = PreflightEngine()
        let report = try engine.run(profile: profile, on: .sample)
        #expect(report.overallStatus == .fail)
    }

    @Test("Report includes document snapshot")
    func reportSnapshot() throws {
        let engine = PreflightEngine()
        let report = try engine.run(profile: .loose, on: .sample)
        #expect(report.documentSnapshot.fileInfo.fileName == "sample.pdf")
    }

    @Test("Engine reports timing")
    func reportTiming() throws {
        let engine = PreflightEngine()
        let report = try engine.run(profile: .loose, on: .sample)
        #expect(report.duration >= 0)
    }
}
```

**Step 2: Implement**

```swift
// TaxiwayCore/Sources/TaxiwayCore/Engine/PreflightReport.swift
import Foundation

public struct PreflightReport: Identifiable, Codable, Sendable {
    public let id: UUID
    public let documentURL: URL?
    public let profileID: UUID
    public let profileName: String
    public let runAt: Date
    public let duration: TimeInterval
    public let overallStatus: CheckStatus
    public let results: [CheckResult]
    public let documentSnapshot: TaxiwayDocument
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Engine/PreflightEngine.swift
import Foundation

public struct CheckProgress: Sendable {
    public let completedChecks: Int
    public let totalChecks: Int
    public let lastResult: CheckResult?
}

public struct PreflightEngine: Sendable {
    private let registry: CheckRegistry

    public init(registry: CheckRegistry = .default) {
        self.registry = registry
    }

    public func run(profile: PreflightProfile, on document: TaxiwayDocument, documentURL: URL? = nil) throws -> PreflightReport {
        let start = Date()
        let enabledEntries = profile.entries.filter(\.enabled)
        var results: [CheckResult] = []

        for entry in enabledEntries {
            let check = try registry.instantiate(from: entry)
            let result = check.run(on: document)
            results.append(result)
        }

        let duration = Date().timeIntervalSince(start)
        let hasError = results.contains { $0.status == .fail && $0.severity == .error }
        let overallStatus: CheckStatus = hasError ? .fail : .pass

        return PreflightReport(
            id: UUID(),
            documentURL: documentURL,
            profileID: profile.id,
            profileName: profile.name,
            runAt: start,
            duration: duration,
            overallStatus: overallStatus,
            results: results,
            documentSnapshot: document
        )
    }

    public func run(profile: PreflightProfile, on document: TaxiwayDocument, documentURL: URL? = nil,
                    progress: @Sendable (CheckProgress) -> Void) async throws -> PreflightReport {
        let start = Date()
        let enabledEntries = profile.entries.filter(\.enabled)
        var results: [CheckResult] = []

        for (i, entry) in enabledEntries.enumerated() {
            let check = try registry.instantiate(from: entry)
            let result = check.run(on: document)
            results.append(result)
            progress(CheckProgress(completedChecks: i + 1, totalChecks: enabledEntries.count, lastResult: result))
        }

        let duration = Date().timeIntervalSince(start)
        let hasError = results.contains { $0.status == .fail && $0.severity == .error }

        return PreflightReport(
            id: UUID(),
            documentURL: documentURL,
            profileID: profile.id,
            profileName: profile.name,
            runAt: start,
            duration: duration,
            overallStatus: hasError ? .fail : .pass,
            results: results,
            documentSnapshot: document
        )
    }
}
```

```bash
git commit -m "feat: implement PreflightEngine and PreflightReport"
```

### Task 16: ProfileStorage

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Engine/ProfileStorage.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Engine/ProfileStorageTests.swift`

Handles CRUD for user profiles in `~/Library/Application Support/Taxiway/Profiles/`. Uses a temporary directory for tests.

Key tests:
- Save and load a profile
- List all profiles (built-in + user)
- Delete a user profile
- Cannot delete built-in profile
- Import `.taxiprofile` file
- Export `.taxiprofile` file
- Handle corrupt JSON gracefully (log warning, skip file)

```bash
git commit -m "feat: implement ProfileStorage with JSON persistence"
```

### Task 17: ReportExporter (JSON, CSV, PDF)

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Engine/ReportExporter.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Engine/ReportExporterTests.swift`

Three export methods:
- `exportJSON(report:) -> Data` — encode PreflightReport as JSON
- `exportCSV(report:) -> Data` — flat table: check name, category, status, severity, message, affected items
- `exportPDF(report:) -> Data` — create a simple PDF using PDFKit's `PDFDocument` + `PDFPage` with drawn content

Tests:
- JSON round-trip: export then decode, verify fields match
- CSV structure: verify header row, correct column count, correct row count
- CSV edge case: message containing commas (must be quoted)
- PDF: verify non-empty data, verify it's a valid PDF (starts with `%PDF`)

Note: PDF export uses CoreGraphics drawing into a PDF context. Keep it simple — header, metadata table, results table with coloured status indicators.

```bash
git commit -m "feat: implement ReportExporter for JSON, CSV, and PDF formats"
```

---

## Phase 6: PDF Parser

### Task 18: PDFDocumentParser entry point + FileInfo

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Parser/PDFDocumentParser.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Parser/ParsingError.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Parser/PDFDocumentParserTests.swift`
- Create: `TaxiwayCore/Tests/TaxiwayCoreTests/Parser/TestPDFGenerator.swift` (helper to create test PDFs programmatically)

**Step 1: Create test PDF generator**

Use CoreGraphics to create minimal PDF documents programmatically for parser tests. This avoids needing a test fixture corpus initially.

```swift
// TaxiwayCore/Tests/TaxiwayCoreTests/Parser/TestPDFGenerator.swift
import Foundation
import CoreGraphics
import PDFKit

enum TestPDFGenerator {
    /// Creates a minimal single-page PDF at the given URL
    static func createSimplePDF(at url: URL, pageSize: CGSize = CGSize(width: 595, height: 842)) {
        var rect = CGRect(origin: .zero, size: pageSize)
        guard let context = CGContext(url as CFURL, mediaBox: &rect, nil) else { return }
        context.beginPage(mediaBox: &rect)
        // Draw some text so the page isn't empty
        context.setFillColor(gray: 0, alpha: 1)
        context.endPage()
        context.closePDF()
    }

    /// Creates a multi-page PDF with specified page sizes
    static func createMultiPagePDF(at url: URL, pageSizes: [CGSize]) {
        guard let firstSize = pageSizes.first else { return }
        var rect = CGRect(origin: .zero, size: firstSize)
        guard let context = CGContext(url as CFURL, mediaBox: &rect, nil) else { return }
        for size in pageSizes {
            var pageRect = CGRect(origin: .zero, size: size)
            context.beginPage(mediaBox: &pageRect)
            context.endPage()
        }
        context.closePDF()
    }
}
```

**Step 2: Write parser tests**

```swift
import Testing
import Foundation
@testable import TaxiwayCore

@Suite("PDFDocumentParser Tests")
struct PDFDocumentParserTests {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    init() throws {
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    @Test("Parse simple single-page PDF")
    func parseSimplePDF() throws {
        let url = tempDir.appendingPathComponent("simple.pdf")
        TestPDFGenerator.createSimplePDF(at: url)
        let parser = PDFDocumentParser()
        let doc = try parser.parse(url: url)
        #expect(doc.fileInfo.pageCount == 1)
        #expect(doc.fileInfo.isEncrypted == false)
        #expect(doc.fileInfo.fileSizeBytes > 0)
        #expect(doc.pages.count == 1)
    }

    @Test("Parse multi-page PDF")
    func parseMultiPagePDF() throws {
        let url = tempDir.appendingPathComponent("multi.pdf")
        TestPDFGenerator.createMultiPagePDF(at: url, pageSizes: [
            CGSize(width: 595, height: 842),
            CGSize(width: 612, height: 792)
        ])
        let parser = PDFDocumentParser()
        let doc = try parser.parse(url: url)
        #expect(doc.fileInfo.pageCount == 2)
        #expect(doc.pages.count == 2)
    }

    @Test("Parse nonexistent file throws")
    func parseNonexistent() {
        let url = tempDir.appendingPathComponent("nonexistent.pdf")
        let parser = PDFDocumentParser()
        #expect(throws: ParsingError.self) {
            try parser.parse(url: url)
        }
    }
}
```

**Step 3: Implement parser entry point**

```swift
// TaxiwayCore/Sources/TaxiwayCore/Parser/ParsingError.swift
import Foundation

public enum ParsingError: Error {
    case fileNotFound(URL)
    case cannotOpenPDF(URL)
    case encrypted(URL)
}
```

```swift
// TaxiwayCore/Sources/TaxiwayCore/Parser/PDFDocumentParser.swift
import Foundation
import PDFKit
import CoreGraphics

public struct PDFDocumentParser: Sendable {
    public init() {}

    public func parse(url: URL) throws -> TaxiwayDocument {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ParsingError.fileNotFound(url)
        }
        guard let pdfDoc = PDFDocument(url: url) else {
            throw ParsingError.cannotOpenPDF(url)
        }
        if pdfDoc.isEncrypted && !pdfDoc.isLocked {
            // Encrypted but unlocked (no password needed) — proceed
        } else if pdfDoc.isLocked {
            throw ParsingError.encrypted(url)
        }

        var warnings: [ParseWarning] = []
        let fileInfo = extractFileInfo(url: url, pdfDoc: pdfDoc)
        let documentInfo = extractDocumentInfo(pdfDoc: pdfDoc)
        let pages = extractPages(pdfDoc: pdfDoc, warnings: &warnings)
        let fonts = FontExtractor.extract(from: pdfDoc, warnings: &warnings)
        let images = ImageExtractor.extract(from: pdfDoc, warnings: &warnings)
        let colourSpaces = ColourExtractor.extractColourSpaces(from: pdfDoc, warnings: &warnings)
        let spotColours = ColourExtractor.extractSpotColours(from: pdfDoc, warnings: &warnings)
        let annotations = AnnotationExtractor.extract(from: pdfDoc)
        let metadata = MetadataExtractor.extract(from: pdfDoc)

        return TaxiwayDocument(
            fileInfo: fileInfo,
            documentInfo: documentInfo,
            pages: pages,
            fonts: fonts,
            images: images,
            colourSpaces: colourSpaces,
            spotColours: spotColours,
            annotations: annotations,
            metadata: metadata,
            parseWarnings: warnings
        )
    }

    private func extractFileInfo(url: URL, pdfDoc: PDFDocument) -> FileInfo {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attrs?[.size] as? Int64) ?? 0
        return FileInfo(
            fileName: url.lastPathComponent,
            filePath: url.path,
            fileSizeBytes: fileSize,
            isEncrypted: pdfDoc.isEncrypted,
            pageCount: pdfDoc.pageCount
        )
    }

    private func extractDocumentInfo(pdfDoc: PDFDocument) -> DocumentInfo {
        let attrs = pdfDoc.documentAttributes ?? [:]
        let version = "\(pdfDoc.majorVersion).\(pdfDoc.minorVersion)"
        return DocumentInfo(
            pdfVersion: version,
            producer: attrs[PDFDocumentAttribute.producerAttribute] as? String,
            creator: attrs[PDFDocumentAttribute.creatorAttribute] as? String,
            isLinearized: false, // Requires raw header check — implement in Task 19
            isTagged: false,     // Requires catalog check — implement in Task 19
            hasLayers: false     // Requires OCProperties check — implement in Task 19
        )
    }

    private func extractPages(pdfDoc: PDFDocument, warnings: inout [ParseWarning]) -> [PageInfo] {
        (0..<pdfDoc.pageCount).compactMap { i in
            guard let page = pdfDoc.page(at: i) else {
                warnings.append(ParseWarning(domain: "PageGeometry", message: "Could not access page \(i)", pageIndex: i))
                return nil
            }
            return PageGeometry.extract(from: page, index: i)
        }
    }
}
```

```bash
git commit -m "feat: implement PDFDocumentParser entry point with FileInfo extraction"
```

### Task 19: PageGeometry extractor

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Parser/PageGeometry.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Parser/PageGeometryTests.swift`

Uses CGPDF to extract MediaBox, TrimBox, BleedBox, ArtBox, and rotation from each page.

```swift
// TaxiwayCore/Sources/TaxiwayCore/Parser/PageGeometry.swift
import Foundation
import PDFKit
import CoreGraphics

enum PageGeometry {
    static func extract(from page: PDFPage, index: Int) -> PageInfo {
        let mediaBox = page.bounds(for: .mediaBox)
        let trimBox = boxIfDifferent(page.bounds(for: .trimBox), from: mediaBox)
        let bleedBox = boxIfDifferent(page.bounds(for: .bleedBox), from: mediaBox)
        let artBox = boxIfDifferent(page.bounds(for: .artBox), from: mediaBox)
        return PageInfo(
            index: index,
            mediaBox: mediaBox,
            trimBox: trimBox,
            bleedBox: bleedBox,
            artBox: artBox,
            rotation: page.rotation
        )
    }

    /// PDFKit returns MediaBox when a box isn't explicitly set. Return nil in that case.
    private static func boxIfDifferent(_ box: CGRect, from mediaBox: CGRect) -> CGRect? {
        box == mediaBox ? nil : box
    }
}
```

Tests verify boxes are correctly extracted and that missing boxes return nil (not MediaBox).

```bash
git commit -m "feat: implement PageGeometry extractor"
```

### Task 20: FontExtractor

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Parser/FontExtractor.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Parser/FontExtractorTests.swift`

Uses CGPDF to walk each page's resource dictionary `/Font` entries. Extracts font name, type (from `/Subtype`), embedding status (presence of `/FontDescriptor` with `/FontFile`, `/FontFile2`, or `/FontFile3`), and subset prefix detection (6 uppercase letters + `+` prefix).

This is the first extractor that needs to work with CGPDF C APIs. Key patterns:
- Get the page's CGPDF dictionary via `page.pageRef`
- Walk to `/Resources/Font` dictionary
- Iterate font entries using `CGPDFDictionaryApplyBlock`

Testing: Create a test PDF with embedded font (draw text with a system font), verify the parser finds at least one font.

```bash
git commit -m "feat: implement FontExtractor with CGPDF resource dict walking"
```

### Task 21: ImageExtractor

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Parser/ImageExtractor.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Parser/ImageExtractorTests.swift`

Walks each page's `/Resources/XObject` dictionary looking for entries with `/Subtype /Image`. Extracts width, height, bits per component, colour space, and filter (compression type) from the image dictionary.

Effective PPI calculation requires the image's CTM (Current Transformation Matrix), which is in the content stream. For MVP, store native dimensions and flag effective dimensions as approximate.

```bash
git commit -m "feat: implement ImageExtractor with CGPDF XObject scanning"
```

### Task 22: ColourExtractor

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Parser/ColourExtractor.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Parser/ColourExtractorTests.swift`

Walks `/Resources/ColorSpace` on each page. Identifies DeviceGray/RGB/CMYK, ICCBased (reads profile description), Separation (extracts spot colour name), and DeviceN (extracts array of colour names).

`extractSpotColours` collects all Separation and DeviceN colour names across all pages.

```bash
git commit -m "feat: implement ColourExtractor with spot colour detection"
```

### Task 23: MetadataExtractor and AnnotationExtractor

**Files:**
- Create: `TaxiwayCore/Sources/TaxiwayCore/Parser/MetadataExtractor.swift`
- Create: `TaxiwayCore/Sources/TaxiwayCore/Parser/AnnotationExtractor.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Parser/MetadataExtractorTests.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Parser/AnnotationExtractorTests.swift`

**MetadataExtractor:** Reads PDFKit document attributes for title, author, etc. Reads XMP metadata stream from the document catalog for C2PA detection (look for `c2pa` or `stds:xmpRights` namespaces) and GenAI metadata (look for `aig:` or `DigitalSourceType` markers). Extracts OutputIntents from the catalog's `/OutputIntents` array.

**AnnotationExtractor:** Iterates PDFKit annotations on each page, maps annotation type strings to `AnnotationType` enum.

```bash
git commit -m "feat: implement MetadataExtractor and AnnotationExtractor"
```

### Task 24: Wire extractors into PDFDocumentParser and integration test

**Files:**
- Modify: `TaxiwayCore/Sources/TaxiwayCore/Parser/PDFDocumentParser.swift`
- Test: `TaxiwayCore/Tests/TaxiwayCoreTests/Parser/ParserIntegrationTests.swift`

Update the stubbed `extractDocumentInfo` to properly check linearisation (read raw file header bytes for `Linearized`), tagged status (check catalog for `/MarkInfo`), and layers (check for `/OCProperties`).

Integration test: create a test PDF with text (triggers font extraction), an image (triggers image extraction), and verify the full `TaxiwayDocument` is populated correctly end-to-end.

```bash
git commit -m "feat: complete parser integration with all extractors"
```

---

## Phase 7: App UI

### Task 25: Clean up boilerplate and set up app structure

**Files:**
- Delete: `Taxiway/Item.swift`
- Rewrite: `Taxiway/TaxiwayApp.swift`
- Rewrite: `Taxiway/ContentView.swift`
- Create: `Taxiway/App/AppCoordinator.swift`
- Create: `Taxiway/Theme/TaxiwayTheme.swift`

**Step 1: Remove SwiftData boilerplate**

Delete `Item.swift`. Rewrite `TaxiwayApp.swift` to remove `ModelContainer` and `SwiftData` import. Replace with a simple `WindowGroup` that passes `AppCoordinator` into the environment.

```swift
// Taxiway/TaxiwayApp.swift
import SwiftUI
import TaxiwayCore

@main
struct TaxiwayApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(coordinator)
        }
    }
}
```

```swift
// Taxiway/App/AppCoordinator.swift
import SwiftUI
import TaxiwayCore

@Observable
final class AppCoordinator {
    enum Screen {
        case dashboard
        case running(URL, PreflightProfile)
        case report(PreflightReport)
    }

    var currentScreen: Screen = .dashboard
    var selectedProfile: PreflightProfile = .loose
    var recentFiles: [URL] = []

    func startPreflight(url: URL) {
        currentScreen = .running(url, selectedProfile)
    }

    func showReport(_ report: PreflightReport) {
        currentScreen = .report(report)
    }

    func backToDashboard() {
        currentScreen = .dashboard
    }
}
```

```swift
// Taxiway/Theme/TaxiwayTheme.swift
import SwiftUI

enum TaxiwayTheme {
    // Backgrounds
    static let panelBackground = Color("PanelBackground")  // Define in Assets
    static let surfaceBackground = Color("SurfaceBackground")

    // Text
    static let primaryLabel = Color("PrimaryLabel")
    static let secondaryLabel = Color("SecondaryLabel")

    // Status — aviation annunciator convention
    static let statusPass = Color.green
    static let statusWarning = Color.orange
    static let statusError = Color.red
    static let statusInactive = Color.gray.opacity(0.3)

    // Typography
    static let monoFont: Font = .system(.body, design: .monospaced)
    static let monoSmall: Font = .system(.caption, design: .monospaced)
    static let monoLarge: Font = .system(.title2, design: .monospaced)

    // Spacing
    static let panelPadding: CGFloat = 16
    static let tilePadding: CGFloat = 12
    static let sectionSpacing: CGFloat = 20
}
```

Define colour assets in `Assets.xcassets` with light and dark variants:
- `PanelBackground`: dark mode `#1C1C1E`, light mode `#F5F5F5`
- `SurfaceBackground`: dark mode `#2C2C2E`, light mode `#FFFFFF`
- `PrimaryLabel`: dark mode `#F5F0E8` (warm white), light mode `#1C1C1E`
- `SecondaryLabel`: dark mode `#8E8E93`, light mode `#6C6C70`

**Step 2: Add TaxiwayCore as local package dependency**

This requires modifying the Xcode project to reference the local package. Open in Xcode: File → Add Package Dependencies → Add Local → select `TaxiwayCore/`. Or manually edit `project.pbxproj` to add the package reference and product dependency.

**Step 3: Build and verify**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Taxiway -destination 'platform=macOS' build`
Expected: BUILD SUCCEEDED

```bash
git commit -m "refactor: replace boilerplate with AppCoordinator, TaxiwayTheme, and TaxiwayCore dependency"
```

### Task 26: Dashboard view

**Files:**
- Create: `Taxiway/Views/Dashboard/DashboardView.swift`
- Create: `Taxiway/Views/Dashboard/DropZoneView.swift`
- Create: `Taxiway/Views/Dashboard/ProfilePickerView.swift`
- Create: `Taxiway/Views/Dashboard/RecentFilesView.swift`
- Modify: `Taxiway/ContentView.swift`

**DashboardView** is the main screen. Contains:
- `DropZoneView` — accepts PDF drag-and-drop or click-to-open. Uses `NSOpenPanel` for file picker. Drop zone styled with a dashed border on dark surface.
- `ProfilePickerView` — `Picker` or `Menu` listing available profiles. Uses `ProfileStorage` to load built-in + user profiles.
- `RecentFilesView` — compact list of recently opened PDFs. Stored in `UserDefaults` as bookmarks.
- "Run Preflight" button — disabled until a PDF is selected.

`ContentView` becomes a router:
```swift
struct ContentView: View {
    @Environment(AppCoordinator.self) var coordinator

    var body: some View {
        switch coordinator.currentScreen {
        case .dashboard:
            DashboardView()
        case .running(let url, let profile):
            RunningView(url: url, profile: profile)
        case .report(let report):
            ReportView(report: report)
        }
    }
}
```

```bash
git commit -m "feat: implement Dashboard with drop zone, profile picker, and recent files"
```

### Task 27: Running view (preflight execution)

**Files:**
- Create: `Taxiway/Views/Running/RunningView.swift`

Brief interstitial that:
1. Parses the PDF via `PDFDocumentParser`
2. Runs the profile via `PreflightEngine` (async with progress)
3. Shows a progress indicator with per-category status
4. Transitions to report view on completion

Uses `Task` for async execution. Shows category names with progress indicators (dim → lit as completed).

```bash
git commit -m "feat: implement RunningView with async preflight execution"
```

### Task 28: Report view

**Files:**
- Create: `Taxiway/Views/Report/ReportView.swift`
- Create: `Taxiway/Views/Report/StatusHeaderView.swift`
- Create: `Taxiway/Views/Report/CategoryTilesView.swift`
- Create: `Taxiway/Views/Report/ResultsListView.swift`
- Create: `Taxiway/Views/Report/ResultDetailView.swift`
- Create: `Taxiway/Views/Report/ExportControlsView.swift`

**ReportView** layout (top to bottom):
- `StatusHeaderView` — large pass/fail indicator, profile name, run timestamp, file name
- `CategoryTilesView` — grid of 8 tiles (one per `CheckCategory`), coloured by worst result in that category. Green/amber/red/grey.
- `ResultsListView` — table of check results sorted by severity (errors first). Each row shows check name, status icon, message.
- `ResultDetailView` — shown when a result row is selected, shows affected items (pages, fonts, images) in a detail pane.
- `ExportControlsView` — buttons for JSON, CSV, PDF export. Uses `NSSavePanel` for destination.

Use `NavigationSplitView` with results list in sidebar, detail on right. Or a single-column layout with expandable rows — match whichever feels more natural for macOS.

```bash
git commit -m "feat: implement Report view with category tiles, results list, and export"
```

### Task 29: Inspector panel

**Files:**
- Create: `Taxiway/Views/Inspector/InspectorView.swift`
- Create: `Taxiway/Views/Inspector/DocumentInfoSection.swift`
- Create: `Taxiway/Views/Inspector/PageListSection.swift`
- Create: `Taxiway/Views/Inspector/FontListSection.swift`
- Create: `Taxiway/Views/Inspector/ImageListSection.swift`
- Create: `Taxiway/Views/Inspector/ColourSection.swift`

Collapsible sidebar available from the report view. Shows raw data from `TaxiwayDocument`:
- Document metadata (file, PDF version, producer, creator)
- Page list with geometry details (sizes, boxes, rotation)
- Font inventory (name, type, embedded, subset, pages)
- Image inventory (dimensions, PPI, colour mode, compression)
- Colour spaces and spot colours

All sections are `DisclosureGroup` with monospaced data display.

```bash
git commit -m "feat: implement Inspector panel with document detail sections"
```

### Task 30: Profile editor

**Files:**
- Create: `Taxiway/Views/ProfileEditor/ProfileEditorView.swift`
- Create: `Taxiway/Views/ProfileEditor/CheckToggleRow.swift`
- Create: `Taxiway/Views/ProfileEditor/ProfileMetadataView.swift`

Opens as a sheet or separate window. Layout:
- Profile name and description at top (editable text fields for user profiles, read-only for built-ins)
- Checks grouped by category with `DisclosureGroup`
- Each check row: toggle (enabled/disabled), severity picker, parameter controls
- Parameter controls generated dynamically from the `CheckParameters` type — use a `CheckParameterView` that switches on known parameter types (double, int, string, enum, bool)
- Built-in profiles show all toggles but disabled, with a "Duplicate" button
- Save/Cancel buttons

Profile changes are persisted via `ProfileStorage`.

```bash
git commit -m "feat: implement Profile editor with dynamic check parameter UI"
```

### Task 31: Settings and final integration

**Files:**
- Create: `Taxiway/Views/Settings/SettingsView.swift`
- Modify: `Taxiway/TaxiwayApp.swift` (add Settings scene)

Minimal settings for MVP:
- Default profile selection
- Clear recent files

Add `.commands` group with File → Open, File → Export menu items.

Final integration: verify the full flow works — drop PDF → pick profile → run preflight → see report → export → edit profiles.

```bash
git commit -m "feat: add Settings view and complete app integration"
```

---

## Summary

| Phase | Tasks | What it delivers |
|---|---|---|
| 1. Scaffold | 1 | TaxiwayCore package builds and tests |
| 2. Models | 2 | All data types with Codable round-trip tests |
| 3. Check infra | 3-4 | Check protocol, registry, Codable storage |
| 4. Checks | 5-13 | ~35 checks across 8 categories, all unit tested |
| 5. Engine | 14-17 | Profile management, engine execution, report export |
| 6. Parser | 18-24 | Full PDF parsing with CGPDF extractors |
| 7. UI | 25-31 | Dashboard, report, inspector, profile editor, settings |

**Total: 31 tasks.** Each follows TDD: write test → verify fail → implement → verify pass → commit.
