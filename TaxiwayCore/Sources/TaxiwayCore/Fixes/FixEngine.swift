import Foundation
import PDFKit

public struct FixProgress: Sendable {
    public let stage: String
    public let detail: String?

    public init(stage: String, detail: String? = nil) {
        self.stage = stage
        self.detail = detail
    }
}

public enum FixError: Error, Sendable, LocalizedError {
    case ghostscriptNotAvailable
    case noFixesRequested
    case ghostscriptFailed(GhostscriptError)
    case pdfKitFailed(String)

    public var errorDescription: String? {
        switch self {
        case .ghostscriptNotAvailable:
            return "Ghostscript not found. Install it with: brew install ghostscript"
        case .noFixesRequested:
            return "No fixes were queued to apply."
        case .ghostscriptFailed(let gsError):
            return gsError.localizedDescription
        case .pdfKitFailed(let reason):
            return reason
        }
    }
}

public struct QueuedFix: Sendable {
    public let descriptor: FixDescriptor
    public let parametersJSON: String?

    public init(descriptor: FixDescriptor, parametersJSON: String? = nil) {
        self.descriptor = descriptor
        self.parametersJSON = parametersJSON
    }
}

private let mmToPoints: Double = 72.0 / 25.4

public struct FixEngine: Sendable {
    private let gsRunner: GhostscriptRunner?

    public init(gsRunner: GhostscriptRunner? = .system()) {
        self.gsRunner = gsRunner
    }

    public var ghostscriptAvailable: Bool { gsRunner != nil }

    /// Applies the given fixes to the input PDF, writing the result to outputURL.
    public func apply(
        fixes: [QueuedFix],
        inputURL: URL,
        outputURL: URL,
        progress: @Sendable (FixProgress) -> Void
    ) throws(FixError) {
        guard !fixes.isEmpty else { throw .noFixesRequested }

        let gsFixes = fixes.filter { $0.descriptor.category == .ghostscript }
        let pdfKitFixes = fixes.filter { $0.descriptor.category == .pdfkit }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("taxiway-fix-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        var currentInput = inputURL

        // Ghostscript phase
        if !gsFixes.isEmpty {
            guard let gs = gsRunner else { throw .ghostscriptNotAvailable }

            progress(FixProgress(stage: "Running Ghostscript",
                                 detail: gsFixes.map(\.descriptor.name).joined(separator: ", ")))

            let gsOutput = tempDir.appendingPathComponent("gs-output.pdf")
            let gsArgs = Self.buildGSArguments(for: gsFixes)

            do {
                try gs.run(arguments: gsArgs, inputURL: currentInput, outputURL: gsOutput)
            } catch let error as GhostscriptError {
                throw .ghostscriptFailed(error)
            } catch {
                throw .ghostscriptFailed(.executionFailed(error.localizedDescription))
            }
            currentInput = gsOutput
        }

        // PDFKit phase
        if !pdfKitFixes.isEmpty {
            progress(FixProgress(stage: "Applying PDFKit fixes",
                                 detail: pdfKitFixes.map(\.descriptor.name).joined(separator: ", ")))

            let pdfKitOutput = tempDir.appendingPathComponent("pdfkit-output.pdf")

            guard let doc = PDFDocument(url: currentInput) else {
                throw .pdfKitFailed("Failed to open PDF for annotation removal")
            }

            for fix in pdfKitFixes {
                if fix.descriptor.id == "fix.remove_annotations" {
                    for pageIndex in 0..<doc.pageCount {
                        guard let page = doc.page(at: pageIndex) else { continue }
                        for annotation in page.annotations {
                            page.removeAnnotation(annotation)
                        }
                    }
                }
            }

            guard doc.write(to: pdfKitOutput) else {
                throw .pdfKitFailed("Failed to write PDF after annotation removal")
            }
            currentInput = pdfKitOutput
        }

        // Move final output
        progress(FixProgress(stage: "Finalizing"))
        do {
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
            try FileManager.default.copyItem(at: currentInput, to: outputURL)
        } catch {
            throw .pdfKitFailed("Failed to write output: \(error.localizedDescription)")
        }
    }

    // MARK: - Ghostscript Argument Building

    /// Builds the combined Ghostscript arguments for all GS-category fixes.
    /// This method is static and pure for testability.
    public static func buildGSArguments(for fixes: [QueuedFix]) -> [String] {
        var args: [String] = [
            // Baseline font-safety flags: ensure pdfwrite preserves font
            // encodings and embedding through the round-trip, and prevent
            // unexpected page rotation.
            "-dEmbedAllFonts=true",
            "-dSubsetFonts=true",
            "-dAutoRotatePages=/None",
        ]
        var preambles: [String] = []

        let fixIDs = Set(fixes.map(\.descriptor.id))

        // --- Reactive fix arguments ---

        // CMYK conversion — shared by convert_cmyk, convert_rich_black, limit_ink_coverage, assign_default_icc
        let cmykConversionFixes: Set<String> = [
            "fix.convert_cmyk", "fix.convert_rich_black", "fix.limit_ink_coverage", "fix.assign_default_icc",
        ]
        if !cmykConversionFixes.isDisjoint(with: fixIDs) {
            args.append(contentsOf: [
                "-dColorConversionStrategy=/CMYK",
                "-dProcessColorModel=/DeviceCMYK",
            ])
        }

        // Note: fix.embed_fonts is handled by the baseline args above
        // (-dEmbedAllFonts, -dSubsetFonts). No additional arguments needed.

        if fixIDs.contains("fix.downsample_images") {
            args.append(contentsOf: [
                "-dDownsampleColorImages=true",
                "-dColorImageResolution=300",
                "-dDownsampleGrayImages=true",
                "-dGrayImageResolution=300",
                "-dDownsampleMonoImages=true",
                "-dMonoImageResolution=300",
            ])
        }

        // Transparency flattening — shared by flatten_transparency and flatten_alpha
        let transparencyFixes: Set<String> = ["fix.flatten_transparency", "fix.flatten_alpha"]
        if !transparencyFixes.isDisjoint(with: fixIDs) {
            args.append(contentsOf: [
                "-dHaveTransparency=false",
                "-dCompatibilityLevel=1.4",
            ])
        }

        if fixIDs.contains("fix.flatten_layers") {
            args.append(contentsOf: [
                "-dCompatibilityLevel=1.4",
                "-dPreserveOCProperties=false",
            ])
        }

        // --- Proactive fix arguments ---

        if let fix = fixes.first(where: { $0.descriptor.id == "fix.set_pdf_version" }) {
            let version = decodeParam(fix.parametersJSON, key: "version", fallback: "1.4")
            args.append("-dCompatibilityLevel=\(version)")
        }

        if let fix = fixes.first(where: { $0.descriptor.id == "fix.change_page_size" }) {
            let wMM = decodeParam(fix.parametersJSON, key: "widthMM", fallback: 210.0)
            let hMM = decodeParam(fix.parametersJSON, key: "heightMM", fallback: 297.0)
            let wPt = wMM * mmToPoints
            let hPt = hMM * mmToPoints
            args.append(contentsOf: [
                "-dFIXEDMEDIA",
                "-dDEVICEWIDTHPOINTS=\(Int(wPt.rounded()))",
                "-dDEVICEHEIGHTPOINTS=\(Int(hPt.rounded()))",
                "-dPDFFitPage=true",
            ])
        }

        if let fix = fixes.first(where: { $0.descriptor.id == "fix.add_bleed" }) {
            let bleedMM = decodeParam(fix.parametersJSON, key: "bleedMM", fallback: 3.0)
            let pageW = decodeParam(fix.parametersJSON, key: "pageWidthPt", fallback: 595.0)
            let pageH = decodeParam(fix.parametersJSON, key: "pageHeightPt", fallback: 842.0)
            let bleedPt = bleedMM * mmToPoints
            let totalW = Int((pageW + bleedPt * 2).rounded())
            let totalH = Int((pageH + bleedPt * 2).rounded())
            args.append(contentsOf: [
                "-dFIXEDMEDIA",
                "-dDEVICEWIDTHPOINTS=\(totalW)",
                "-dDEVICEHEIGHTPOINTS=\(totalH)",
            ])
            let bleedStr = String(format: "%.4f", bleedPt)
            preambles.append("\(bleedStr) \(bleedStr) translate")
        }

        if let fix = fixes.first(where: { $0.descriptor.id == "fix.add_trim_marks" }) {
            let offsetMM = decodeParam(fix.parametersJSON, key: "offsetMM", fallback: 3.0)
            let lengthMM = decodeParam(fix.parametersJSON, key: "lengthMM", fallback: 6.0)
            let offsetPt = String(format: "%.4f", offsetMM * mmToPoints)
            let lengthPt = String(format: "%.4f", lengthMM * mmToPoints)
            preambles.append(
                "/TXWoff \(offsetPt) def /TXWlen \(lengthPt) def "
                + "<< /EndPage { "
                + "exch pop 0 eq { "
                + "gsave 0 setgray 0.25 setlinewidth "
                + "currentpagedevice /PageSize get aload pop "
                + "/pH exch def /pW exch def "
                // Bottom-left corner
                + "newpath 0 TXWoff moveto TXWlen 0 rlineto stroke "
                + "newpath TXWoff 0 moveto 0 TXWlen rlineto stroke "
                // Bottom-right corner
                + "newpath pW TXWoff moveto TXWlen neg 0 rlineto stroke "
                + "newpath pW TXWoff sub 0 moveto 0 TXWlen rlineto stroke "
                // Top-left corner
                + "newpath 0 pH TXWoff sub moveto TXWlen 0 rlineto stroke "
                + "newpath TXWoff pH moveto 0 TXWlen neg rlineto stroke "
                // Top-right corner
                + "newpath pW pH TXWoff sub moveto TXWlen neg 0 rlineto stroke "
                + "newpath pW TXWoff sub pH moveto 0 TXWlen neg rlineto stroke "
                + "grestore true "
                + "} { false } ifelse "
                + "} >> setpagedevice"
            )
        }

        // If any PostScript preambles were generated, wrap them in -c ... -f
        if !preambles.isEmpty {
            args.append("-c")
            args.append(preambles.joined(separator: " "))
            args.append("-f")
        }

        return args
    }
}

// MARK: - JSON Parameter Decoding Helpers

private func decodeParam(_ json: String?, key: String, fallback: Double) -> Double {
    guard let json, let data = json.data(using: .utf8),
          let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let value = dict[key] as? Double else { return fallback }
    return value
}

private func decodeParam(_ json: String?, key: String, fallback: String) -> String {
    guard let json, let data = json.data(using: .utf8),
          let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let value = dict[key] as? String else { return fallback }
    return value
}
