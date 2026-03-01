import Foundation

public struct TaxiwayDocument: Codable, Sendable, Equatable {
    public let fileInfo: FileInfo
    public let documentInfo: DocumentInfo
    public let pages: [PageInfo]
    public let fonts: [FontInfo]
    public let images: [ImageInfo]
    public let colourSpaces: [ColourSpaceInfo]
    public let spotColours: [SpotColourInfo]
    public let colourUsages: [ColourUsageInfo]
    public let annotations: [AnnotationInfo]
    public let textFrames: [TextFrameInfo]
    public let metadata: DocumentMetadata
    public let parseWarnings: [ParseWarning]

    public init(fileInfo: FileInfo, documentInfo: DocumentInfo, pages: [PageInfo], fonts: [FontInfo],
                images: [ImageInfo], colourSpaces: [ColourSpaceInfo], spotColours: [SpotColourInfo],
                colourUsages: [ColourUsageInfo] = [], annotations: [AnnotationInfo],
                textFrames: [TextFrameInfo] = [],
                metadata: DocumentMetadata, parseWarnings: [ParseWarning] = []) {
        self.fileInfo = fileInfo
        self.documentInfo = documentInfo
        self.pages = pages
        self.fonts = fonts
        self.images = images
        self.colourSpaces = colourSpaces
        self.spotColours = spotColours
        self.colourUsages = colourUsages
        self.annotations = annotations
        self.textFrames = textFrames
        self.metadata = metadata
        self.parseWarnings = parseWarnings
    }
}
