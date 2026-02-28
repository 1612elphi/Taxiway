import Testing
import Foundation
@testable import TaxiwayCore

// MARK: - Test Helpers

/// Helper to create an ImageInfo with sensible defaults, overriding only what's needed.
private func makeImage(
    id: String = "img_test",
    pageIndex: Int = 0,
    widthPixels: Int = 2400,
    heightPixels: Int = 1600,
    effectiveWidthPoints: Double = 576.0,
    effectiveHeightPoints: Double = 384.0,
    colourMode: ImageColourMode = .deviceCMYK,
    compressionType: ImageCompressionType = .jpeg,
    bitsPerComponent: Int = 8,
    hasICCProfile: Bool = true,
    hasICCOverride: Bool = false,
    hasAlphaChannel: Bool = false,
    blendMode: BlendMode = .normal,
    opacity: Double = 1.0
) -> ImageInfo {
    ImageInfo(
        id: id, pageIndex: pageIndex,
        widthPixels: widthPixels, heightPixels: heightPixels,
        effectiveWidthPoints: effectiveWidthPoints, effectiveHeightPoints: effectiveHeightPoints,
        colourMode: colourMode, compressionType: compressionType,
        bitsPerComponent: bitsPerComponent, hasICCProfile: hasICCProfile,
        hasICCOverride: hasICCOverride, hasAlphaChannel: hasAlphaChannel,
        blendMode: blendMode, opacity: opacity
    )
}

// MARK: - ImageTypeCheck

@Suite("ImageTypeCheck")
struct ImageTypeCheckTests {

    @Test("Passes when no images in document")
    func passNoImages() {
        let doc = TaxiwayDocument.sample.withImages([])
        let check = ImageTypeCheck(parameters: .init(compressionType: .jpeg, operator: .is))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
        #expect(result.message.contains("No images"))
    }

    @Test("Fails with .is operator when image uses target compression")
    func failIsJPEG() {
        // Sample image is JPEG
        let check = ImageTypeCheck(parameters: .init(compressionType: .jpeg, operator: .is))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.message.contains("JPEG"))
        #expect(result.affectedItems.count == 1)
    }

    @Test("Passes with .is operator when no image uses target compression")
    func passIsFlate() {
        // Sample image is JPEG, not Flate
        let check = ImageTypeCheck(parameters: .init(compressionType: .flate, operator: .is))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("No images use Flate"))
    }

    @Test("Fails with .isNot operator when image does not use target compression")
    func failIsNotFlate() {
        // Sample is JPEG; check that it's not Flate — should fail because image doesn't use Flate
        let check = ImageTypeCheck(parameters: .init(compressionType: .flate, operator: .isNot))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.message.contains("do not use"))
    }

    @Test("Passes with .isNot operator when all images use target compression")
    func passIsNotJPEG() {
        // Sample is JPEG; check isNot JPEG — should pass since all images use JPEG
        let check = ImageTypeCheck(parameters: .init(compressionType: .jpeg, operator: .isNot))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("All images use JPEG"))
    }

    @Test("Reports multiple affected images")
    func multipleAffected() {
        let doc = TaxiwayDocument.sample.withImages([
            makeImage(id: "img_1", compressionType: .jpeg),
            makeImage(id: "img_2", compressionType: .flate),
            makeImage(id: "img_3", compressionType: .jpeg),
        ])
        let check = ImageTypeCheck(parameters: .init(compressionType: .jpeg, operator: .is))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 2)
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = ImageTypeCheck(parameters: .init(compressionType: .jpeg, operator: .is))
        #expect(check.defaultSeverity == .warning)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(ImageTypeCheck.typeID == "images.type")
    }
}

// MARK: - ImageColourModeCheck

@Suite("ImageColourModeCheck")
struct ImageColourModeCheckTests {

    @Test("Passes when no images in document")
    func passNoImages() {
        let doc = TaxiwayDocument.sample.withImages([])
        let check = ImageColourModeCheck(parameters: .init(colourMode: .deviceRGB, operator: .is))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Fails with .is operator when image uses target colour mode")
    func failIsCMYK() {
        // Sample image is CMYK
        let check = ImageColourModeCheck(parameters: .init(colourMode: .deviceCMYK, operator: .is))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.message.contains("DeviceCMYK"))
        #expect(result.affectedItems.count == 1)
    }

    @Test("Passes with .is operator when no image uses target colour mode")
    func passIsRGB() {
        // Sample image is CMYK, not RGB
        let check = ImageColourModeCheck(parameters: .init(colourMode: .deviceRGB, operator: .is))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Fails with .isNot when images do not use target mode")
    func failIsNotRGB() {
        let check = ImageColourModeCheck(parameters: .init(colourMode: .deviceRGB, operator: .isNot))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.message.contains("do not use"))
    }

    @Test("Passes with .isNot when all images use target mode")
    func passIsNotCMYK() {
        let check = ImageColourModeCheck(parameters: .init(colourMode: .deviceCMYK, operator: .isNot))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("All images use DeviceCMYK"))
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = ImageColourModeCheck(parameters: .init(colourMode: .deviceRGB, operator: .is))
        #expect(check.defaultSeverity == .warning)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(ImageColourModeCheck.typeID == "images.colour_mode")
    }
}

// MARK: - ResolutionBelowCheck

@Suite("ResolutionBelowCheck")
struct ResolutionBelowCheckTests {

    // Sample image: 2400x1600 px, 576x384 pt -> 300 PPI both directions

    @Test("Passes when no images in document")
    func passNoImages() {
        let doc = TaxiwayDocument.sample.withImages([])
        let check = ResolutionBelowCheck(parameters: .init(thresholdPPI: 300))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Passes when all images meet minimum resolution")
    func passAboveThreshold() {
        // Sample is 300 PPI, threshold 200
        let check = ResolutionBelowCheck(parameters: .init(thresholdPPI: 200))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("200"))
    }

    @Test("Fails when image is below threshold")
    func failBelowThreshold() {
        // Sample is 300 PPI, threshold 400
        let check = ResolutionBelowCheck(parameters: .init(thresholdPPI: 400))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.message.contains("1 image"))
        #expect(result.affectedItems.count == 1)
    }

    @Test("Passes at exact threshold boundary")
    func passExactThreshold() {
        // Sample is exactly 300 PPI
        let check = ResolutionBelowCheck(parameters: .init(thresholdPPI: 300))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Uses min of horizontal and vertical PPI")
    func usesMinPPI() {
        // Image with different H and V PPI
        // 1000px wide, 500pt wide -> 1000/(500/72) = 144 PPI horizontal
        // 800px tall, 400pt tall -> 800/(400/72) = 144 PPI vertical
        // But let's make them different:
        // 1000px wide, 500pt -> H=144 PPI, 800px tall, 200pt -> V=288 PPI
        let img = makeImage(
            widthPixels: 1000, heightPixels: 800,
            effectiveWidthPoints: 500, effectiveHeightPoints: 200
        )
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = ResolutionBelowCheck(parameters: .init(thresholdPPI: 200))
        let result = check.run(on: doc)

        // min PPI = 144, threshold 200, so should fail
        #expect(result.status == .fail)
    }

    @Test("Reports PPI in detail")
    func detailContainsPPI() {
        let check = ResolutionBelowCheck(parameters: .init(thresholdPPI: 400))
        let result = check.run(on: .sample)

        #expect(result.detail != nil)
        #expect(result.detail!.contains("300"))
    }

    @Test("Default severity is error")
    func defaultSeverity() {
        let check = ResolutionBelowCheck(parameters: .init(thresholdPPI: 300))
        #expect(check.defaultSeverity == .error)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(ResolutionBelowCheck.typeID == "images.resolution_below")
    }
}

// MARK: - ResolutionAboveCheck

@Suite("ResolutionAboveCheck")
struct ResolutionAboveCheckTests {

    @Test("Passes when no images in document")
    func passNoImages() {
        let doc = TaxiwayDocument.sample.withImages([])
        let check = ResolutionAboveCheck(parameters: .init(thresholdPPI: 300))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Passes when all images are within threshold")
    func passWithinThreshold() {
        // Sample is 300 PPI, threshold 600
        let check = ResolutionAboveCheck(parameters: .init(thresholdPPI: 600))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Fails when image exceeds threshold")
    func failAboveThreshold() {
        // Sample is 300 PPI, threshold 200
        let check = ResolutionAboveCheck(parameters: .init(thresholdPPI: 200))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 1)
    }

    @Test("Passes at exact threshold boundary")
    func passExactThreshold() {
        // Sample is exactly 300 PPI, threshold 300 -> not exceeded (not strictly >)
        let check = ResolutionAboveCheck(parameters: .init(thresholdPPI: 300))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Uses max of horizontal and vertical PPI")
    func usesMaxPPI() {
        // H=144 PPI, V=288 PPI
        let img = makeImage(
            widthPixels: 1000, heightPixels: 800,
            effectiveWidthPoints: 500, effectiveHeightPoints: 200
        )
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = ResolutionAboveCheck(parameters: .init(thresholdPPI: 250))
        let result = check.run(on: doc)

        // max PPI = 288, threshold 250, should fail
        #expect(result.status == .fail)
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = ResolutionAboveCheck(parameters: .init(thresholdPPI: 300))
        #expect(check.defaultSeverity == .warning)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(ResolutionAboveCheck.typeID == "images.resolution_above")
    }
}

// MARK: - ResolutionRangeCheck

@Suite("ResolutionRangeCheck")
struct ResolutionRangeCheckTests {

    @Test("Passes when no images in document")
    func passNoImages() {
        let doc = TaxiwayDocument.sample.withImages([])
        let check = ResolutionRangeCheck(parameters: .init(minPPI: 150, maxPPI: 600))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Passes when image is within range")
    func passWithinRange() {
        // Sample is 300 PPI, range 150-600
        let check = ResolutionRangeCheck(parameters: .init(minPPI: 150, maxPPI: 600))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("150"))
        #expect(result.message.contains("600"))
    }

    @Test("Fails when image is below range")
    func failBelowRange() {
        // Sample is 300 PPI, range 400-600
        let check = ResolutionRangeCheck(parameters: .init(minPPI: 400, maxPPI: 600))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
    }

    @Test("Fails when image is above range")
    func failAboveRange() {
        // Sample is 300 PPI, range 100-200
        let check = ResolutionRangeCheck(parameters: .init(minPPI: 100, maxPPI: 200))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
    }

    @Test("Passes at exact boundary values")
    func passExactBoundary() {
        // Sample is 300 PPI, range 300-300
        let check = ResolutionRangeCheck(parameters: .init(minPPI: 300, maxPPI: 300))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("Reports affected images with both PPI values")
    func detailContainsPPIValues() {
        let check = ResolutionRangeCheck(parameters: .init(minPPI: 400, maxPPI: 600))
        let result = check.run(on: .sample)

        #expect(result.detail != nil)
        #expect(result.detail!.contains("300"))
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = ResolutionRangeCheck(parameters: .init(minPPI: 150, maxPPI: 600))
        #expect(check.defaultSeverity == .warning)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(ResolutionRangeCheck.typeID == "images.resolution_range")
    }
}

// MARK: - ImageScaledCheck

@Suite("ImageScaledCheck")
struct ImageScaledCheckTests {

    @Test("Passes when no images in document")
    func passNoImages() {
        let doc = TaxiwayDocument.sample.withImages([])
        let check = ImageScaledCheck(parameters: .init(tolerancePercent: 5))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Passes when image is placed at 1:1 scale")
    func passOneToOne() {
        // 100px wide placed at 100pt -> scale factor = 100/100 = 1.0
        let img = makeImage(
            widthPixels: 100, heightPixels: 100,
            effectiveWidthPoints: 100, effectiveHeightPoints: 100
        )
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = ImageScaledCheck(parameters: .init(tolerancePercent: 5))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Fails when image is scaled down significantly")
    func failScaledDown() {
        // Sample: 2400px, 576pt -> scale factor = 576/2400 = 0.24 -> 76% deviation
        let check = ImageScaledCheck(parameters: .init(tolerancePercent: 5))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 1)
    }

    @Test("Passes when scaling is within tolerance")
    func passWithinTolerance() {
        // 100px wide placed at 103pt -> scale factor = 1.03 -> 3% deviation
        let img = makeImage(
            widthPixels: 100, heightPixels: 100,
            effectiveWidthPoints: 103, effectiveHeightPoints: 103
        )
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = ImageScaledCheck(parameters: .init(tolerancePercent: 5))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Fails when image is scaled up beyond tolerance")
    func failScaledUp() {
        // 100px wide placed at 200pt -> scale factor = 2.0 -> 100% deviation
        let img = makeImage(
            widthPixels: 100, heightPixels: 100,
            effectiveWidthPoints: 200, effectiveHeightPoints: 200
        )
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = ImageScaledCheck(parameters: .init(tolerancePercent: 5))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
    }

    @Test("Reports scale percentage in detail")
    func detailContainsScalePercent() {
        let check = ImageScaledCheck(parameters: .init(tolerancePercent: 5))
        let result = check.run(on: .sample)

        #expect(result.detail != nil)
        #expect(result.detail!.contains("%"))
    }

    @Test("Skips images with zero dimensions")
    func skipsZeroDimensions() {
        let img = makeImage(widthPixels: 0, effectiveWidthPoints: 0)
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = ImageScaledCheck(parameters: .init(tolerancePercent: 5))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = ImageScaledCheck(parameters: .init(tolerancePercent: 5))
        #expect(check.defaultSeverity == .warning)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(ImageScaledCheck.typeID == "images.scaled")
    }
}

// MARK: - ImageScaledNonProportionallyCheck

@Suite("ImageScaledNonProportionallyCheck")
struct ImageScaledNonProportionallyCheckTests {

    @Test("Passes when no images in document")
    func passNoImages() {
        let doc = TaxiwayDocument.sample.withImages([])
        let check = ImageScaledNonProportionallyCheck(parameters: .init(tolerancePercent: 1))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Passes when image is scaled proportionally")
    func passProportional() {
        // 2400x1600 placed at 576x384 -> scaleX = 576/2400 = 0.24, scaleY = 384/1600 = 0.24
        let check = ImageScaledNonProportionallyCheck(parameters: .init(tolerancePercent: 1))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("proportionally"))
    }

    @Test("Fails when image is scaled non-proportionally")
    func failNonProportional() {
        // scaleX = 500/1000 = 0.5, scaleY = 400/1000 = 0.4 -> diff/max = 0.1/0.5 = 20%
        let img = makeImage(
            widthPixels: 1000, heightPixels: 1000,
            effectiveWidthPoints: 500, effectiveHeightPoints: 400
        )
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = ImageScaledNonProportionallyCheck(parameters: .init(tolerancePercent: 1))
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 1)
    }

    @Test("Passes when scale difference is within tolerance")
    func passWithinTolerance() {
        // scaleX = 100/1000 = 0.1, scaleY = 100.5/1000 = 0.1005 -> diff/max = 0.005
        let img = makeImage(
            widthPixels: 1000, heightPixels: 1000,
            effectiveWidthPoints: 100, effectiveHeightPoints: 100.5
        )
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = ImageScaledNonProportionallyCheck(parameters: .init(tolerancePercent: 1))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Skips images with zero pixel dimensions")
    func skipsZeroDimensions() {
        let img = makeImage(widthPixels: 0, heightPixels: 0, effectiveWidthPoints: 100, effectiveHeightPoints: 100)
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = ImageScaledNonProportionallyCheck(parameters: .init(tolerancePercent: 1))
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Reports scale factors in detail")
    func detailContainsScaleFactors() {
        let img = makeImage(
            widthPixels: 1000, heightPixels: 1000,
            effectiveWidthPoints: 500, effectiveHeightPoints: 300
        )
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = ImageScaledNonProportionallyCheck(parameters: .init(tolerancePercent: 1))
        let result = check.run(on: doc)

        #expect(result.detail != nil)
        #expect(result.detail!.contains("X="))
        #expect(result.detail!.contains("Y="))
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = ImageScaledNonProportionallyCheck(parameters: .init(tolerancePercent: 1))
        #expect(check.defaultSeverity == .warning)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(ImageScaledNonProportionallyCheck.typeID == "images.scaled_non_proportional")
    }
}

// MARK: - ICCProfileMissingCheck

@Suite("ICCProfileMissingCheck")
struct ICCProfileMissingCheckTests {

    @Test("Passes when no images in document")
    func passNoImages() {
        let doc = TaxiwayDocument.sample.withImages([])
        let check = ICCProfileMissingCheck()
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Passes when all images have ICC profiles")
    func passAllHaveICC() {
        // Sample image has ICC profile
        let check = ICCProfileMissingCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("All images have ICC"))
    }

    @Test("Fails when an image is missing ICC profile")
    func failMissingICC() {
        let img = makeImage(hasICCProfile: false)
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = ICCProfileMissingCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.message.contains("missing ICC"))
        #expect(result.affectedItems.count == 1)
    }

    @Test("Reports only images without ICC, not those with")
    func reportsOnlyMissing() {
        let doc = TaxiwayDocument.sample.withImages([
            makeImage(id: "with_icc", hasICCProfile: true),
            makeImage(id: "without_icc", hasICCProfile: false),
        ])
        let check = ICCProfileMissingCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 1)
        #expect(result.detail!.contains("without_icc"))
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = ICCProfileMissingCheck()
        #expect(check.defaultSeverity == .warning)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(ICCProfileMissingCheck.typeID == "images.icc_missing")
    }
}

// MARK: - AlphaChannelCheck

@Suite("AlphaChannelCheck")
struct AlphaChannelCheckTests {

    @Test("Passes when no images in document")
    func passNoImages() {
        let doc = TaxiwayDocument.sample.withImages([])
        let check = AlphaChannelCheck()
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Passes when no images have alpha channels")
    func passNoAlpha() {
        // Sample image has no alpha
        let check = AlphaChannelCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("No images have alpha"))
    }

    @Test("Fails when image has alpha channel")
    func failWithAlpha() {
        let img = makeImage(hasAlphaChannel: true)
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = AlphaChannelCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.message.contains("alpha"))
        #expect(result.affectedItems.count == 1)
    }

    @Test("Reports only images with alpha, not those without")
    func reportsOnlyAlpha() {
        let doc = TaxiwayDocument.sample.withImages([
            makeImage(id: "no_alpha", hasAlphaChannel: false),
            makeImage(id: "has_alpha", hasAlphaChannel: true),
        ])
        let check = AlphaChannelCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 1)
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = AlphaChannelCheck()
        #expect(check.defaultSeverity == .warning)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(AlphaChannelCheck.typeID == "images.alpha")
    }
}

// MARK: - BlendModeOpacityCheck

@Suite("BlendModeOpacityCheck")
struct BlendModeOpacityCheckTests {

    @Test("Passes when no images in document")
    func passNoImages() {
        let doc = TaxiwayDocument.sample.withImages([])
        let check = BlendModeOpacityCheck()
        let result = check.run(on: doc)

        #expect(result.status == .pass)
    }

    @Test("Passes when all images use normal blend at full opacity")
    func passNormalFull() {
        // Sample image: normal blend, 1.0 opacity
        let check = BlendModeOpacityCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("normal blend"))
    }

    @Test("Fails when image has non-normal blend mode")
    func failNonNormalBlend() {
        let img = makeImage(blendMode: .multiply)
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = BlendModeOpacityCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.detail!.contains("Multiply"))
    }

    @Test("Fails when image has reduced opacity")
    func failReducedOpacity() {
        let img = makeImage(opacity: 0.5)
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = BlendModeOpacityCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.detail!.contains("50%"))
    }

    @Test("Fails when image has both non-normal blend and reduced opacity")
    func failBothIssues() {
        let img = makeImage(blendMode: .screen, opacity: 0.75)
        let doc = TaxiwayDocument.sample.withImages([img])
        let check = BlendModeOpacityCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.detail!.contains("Screen"))
        #expect(result.detail!.contains("75%"))
    }

    @Test("Ignores normal blend images at full opacity in mixed set")
    func mixedImages() {
        let doc = TaxiwayDocument.sample.withImages([
            makeImage(id: "normal", blendMode: .normal, opacity: 1.0),
            makeImage(id: "multiply", blendMode: .multiply, opacity: 1.0),
        ])
        let check = BlendModeOpacityCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.affectedItems.count == 1)
    }

    @Test("Default severity is info")
    func defaultSeverity() {
        let check = BlendModeOpacityCheck()
        #expect(check.defaultSeverity == .info)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(BlendModeOpacityCheck.typeID == "images.blend_mode")
    }
}

// MARK: - C2PACheck

@Suite("C2PACheck")
struct C2PACheckTests {

    @Test("Passes when document has no C2PA credentials")
    func passNoC2PA() {
        // Sample has hasC2PA = false
        let check = C2PACheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("No C2PA"))
    }

    @Test("Fails when document has C2PA credentials")
    func failWithC2PA() {
        let doc = TaxiwayDocument.sample.withMetadata { meta in
            DocumentMetadata(
                title: meta.title, author: meta.author, subject: meta.subject,
                keywords: meta.keywords, creationDate: meta.creationDate,
                modificationDate: meta.modificationDate, trapped: meta.trapped,
                outputIntents: meta.outputIntents, xmpRaw: meta.xmpRaw,
                hasC2PA: true, hasGenAIMetadata: meta.hasGenAIMetadata
            )
        }
        let check = C2PACheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.message.contains("C2PA"))
        #expect(result.affectedItems == [.document])
    }

    @Test("Passes on empty document (no C2PA)")
    func passEmptyDocument() {
        let check = C2PACheck()
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("Default severity is info")
    func defaultSeverity() {
        let check = C2PACheck()
        #expect(check.defaultSeverity == .info)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(C2PACheck.typeID == "images.c2pa")
    }
}

// MARK: - GenAIMetadataCheck

@Suite("GenAIMetadataCheck")
struct GenAIMetadataCheckTests {

    @Test("Passes when document has no GenAI metadata")
    func passNoGenAI() {
        // Sample has hasGenAIMetadata = false
        let check = GenAIMetadataCheck()
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("No generative AI"))
    }

    @Test("Fails when document has GenAI metadata")
    func failWithGenAI() {
        let doc = TaxiwayDocument.sample.withMetadata { meta in
            DocumentMetadata(
                title: meta.title, author: meta.author, subject: meta.subject,
                keywords: meta.keywords, creationDate: meta.creationDate,
                modificationDate: meta.modificationDate, trapped: meta.trapped,
                outputIntents: meta.outputIntents, xmpRaw: meta.xmpRaw,
                hasC2PA: meta.hasC2PA, hasGenAIMetadata: true
            )
        }
        let check = GenAIMetadataCheck()
        let result = check.run(on: doc)

        #expect(result.status == .fail)
        #expect(result.message.contains("Generative AI"))
        #expect(result.affectedItems == [.document])
    }

    @Test("Passes on empty document (no GenAI)")
    func passEmptyDocument() {
        let check = GenAIMetadataCheck()
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    @Test("Default severity is warning")
    func defaultSeverity() {
        let check = GenAIMetadataCheck()
        #expect(check.defaultSeverity == .warning)
    }

    @Test("TypeID is correct")
    func typeID() {
        #expect(GenAIMetadataCheck.typeID == "images.genai")
    }
}
