import Foundation

extension CheckRegistry {
    /// A registry pre-loaded with every check type shipped in TaxiwayCore.
    public static var `default`: CheckRegistry {
        var registry = CheckRegistry()

        // File
        registry.register(FileSizeMaxCheck.self)
        registry.register(FileSizeMinCheck.self)
        registry.register(EncryptionCheck.self)
        registry.register(InteractiveElementsCheck.self)
        registry.register(MetadataFieldMatchesCheck.self)
        registry.register(MetadataFieldPresentCheck.self)

        // Colour
        registry.register(ColourSpaceUsedCheck.self)
        registry.register(InkCoverageCheck.self)
        registry.register(NamedColourGradientCheck.self)
        registry.register(OverprintCheck.self)
        registry.register(RegistrationColourCheck.self)
        registry.register(RichBlackCheck.self)
        registry.register(SpotColourCountCheck.self)
        registry.register(SpotColourUsedCheck.self)
        registry.register(TextColourModeCheck.self)
        registry.register(UnnamedSpotColourCheck.self)

        // Fonts
        registry.register(FontNotEmbeddedCheck.self)
        registry.register(FontSizeCheck.self)
        registry.register(FontTypeCheck.self)

        // Images
        registry.register(AlphaChannelCheck.self)
        registry.register(BlendModeOpacityCheck.self)
        registry.register(C2PACheck.self)
        registry.register(GenAIMetadataCheck.self)
        registry.register(ICCProfileMissingCheck.self)
        registry.register(ImageColourModeCheck.self)
        registry.register(ImageScaledCheck.self)
        registry.register(ImageScaledNonProportionallyCheck.self)
        registry.register(ImageTypeCheck.self)
        registry.register(ResolutionAboveCheck.self)
        registry.register(ResolutionBelowCheck.self)
        registry.register(ResolutionRangeCheck.self)

        // Lines
        registry.register(StrokeWeightBelowCheck.self)
        registry.register(ZeroWidthStrokeCheck.self)

        // Marks
        registry.register(ArtSlugBoxCheck.self)
        registry.register(BleedGreaterThanCheck.self)
        registry.register(BleedLessThanCheck.self)
        registry.register(BleedNonUniformCheck.self)
        registry.register(BleedNonZeroCheck.self)
        registry.register(BleedZeroCheck.self)
        registry.register(TrimBoxSetCheck.self)

        // Pages
        registry.register(MixedPageSizesCheck.self)
        registry.register(PageCountCheck.self)
        registry.register(PageRotationCheck.self)
        registry.register(PageSizeCheck.self)

        // PDF
        registry.register(AllTextOutlinedCheck.self)
        registry.register(AnnotationsPresentCheck.self)
        registry.register(LayersPresentCheck.self)
        registry.register(LinearizedCheck.self)
        registry.register(PDFConformanceCheck.self)
        registry.register(PDFVersionCheck.self)
        registry.register(TaggedCheck.self)
        registry.register(TransparencyCheck.self)

        return registry
    }
}
