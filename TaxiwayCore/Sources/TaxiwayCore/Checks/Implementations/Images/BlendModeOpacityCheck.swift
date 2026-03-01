import Foundation

public struct BlendModeOpacityCheck: ParameterisedCheck {
    public static let typeID = "images.blend_mode"
    public let id: UUID
    public let parameters: EmptyParameters
    public let severityOverride: CheckSeverity?

    public var name: String { "Blend Mode / Opacity" }
    public var category: CheckCategory { .images }
    public var defaultSeverity: CheckSeverity { .info }

    public init(id: UUID = UUID(), parameters: EmptyParameters = EmptyParameters(), severityOverride: CheckSeverity? = nil) {
        self.id = id
        self.parameters = parameters
        self.severityOverride = severityOverride
    }

    public func run(on document: TaxiwayDocument) -> CheckResult {
        let images = document.images
        if images.isEmpty {
            return pass(message: "No images in document")
        }

        let affected = images.filter { $0.blendMode != .normal || $0.opacity < 1.0 }

        if affected.isEmpty {
            return pass(message: "All images use normal blend mode at full opacity")
        }

        let affectedItems = affected.map { AffectedItem.image(id: $0.id, page: $0.pageIndex, bounds: $0.bounds) }
        let details = affected.map { img in
            var parts: [String] = []
            if img.blendMode != .normal {
                parts.append("blend: \(img.blendMode.rawValue)")
            }
            if img.opacity < 1.0 {
                parts.append("opacity: \(String(format: "%.0f", img.opacity * 100))%")
            }
            return "\(img.id): \(parts.joined(separator: ", "))"
        }.joined(separator: "; ")

        return fail(
            message: "\(affected.count) image(s) use non-normal blend mode or reduced opacity",
            detail: details,
            affectedItems: affectedItems
        )
    }
}
