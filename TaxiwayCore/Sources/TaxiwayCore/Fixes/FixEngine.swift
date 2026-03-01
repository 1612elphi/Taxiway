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

public enum FixError: Error, Sendable {
    case ghostscriptNotAvailable
    case noFixesRequested
    case ghostscriptFailed(GhostscriptError)
    case pdfKitFailed(String)
}

public struct FixEngine: Sendable {
    private let gsRunner: GhostscriptRunner?

    public init(gsRunner: GhostscriptRunner? = .bundled()) {
        self.gsRunner = gsRunner
    }

    public var ghostscriptAvailable: Bool { gsRunner != nil }

    /// Applies the given fixes to the input PDF, writing the result to outputURL.
    public func apply(
        fixes: [FixDescriptor],
        inputURL: URL,
        outputURL: URL,
        progress: @Sendable (FixProgress) -> Void
    ) throws(FixError) {
        guard !fixes.isEmpty else { throw .noFixesRequested }

        let gsFixes = fixes.filter { $0.category == .ghostscript }
        let pdfKitFixes = fixes.filter { $0.category == .pdfkit }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("taxiway-fix-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        var currentInput = inputURL

        // Ghostscript phase
        if !gsFixes.isEmpty {
            guard let gs = gsRunner else { throw .ghostscriptNotAvailable }

            progress(FixProgress(stage: "Running Ghostscript", detail: gsFixes.map(\.name).joined(separator: ", ")))

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
            progress(FixProgress(stage: "Applying PDFKit fixes", detail: pdfKitFixes.map(\.name).joined(separator: ", ")))

            let pdfKitOutput = tempDir.appendingPathComponent("pdfkit-output.pdf")

            guard let doc = PDFDocument(url: currentInput) else {
                throw .pdfKitFailed("Failed to open PDF for annotation removal")
            }

            for fix in pdfKitFixes {
                if fix.id == "fix.remove_annotations" {
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

    /// Builds the combined Ghostscript arguments for all GS-category fixes.
    /// This method is static and pure for testability.
    public static func buildGSArguments(for fixes: [FixDescriptor]) -> [String] {
        var args: [String] = []

        let fixIDs = Set(fixes.map(\.id))

        if fixIDs.contains("fix.convert_cmyk") {
            args.append(contentsOf: [
                "-dColorConversionStrategy=/CMYK",
                "-dProcessColorModel=/DeviceCMYK",
            ])
        }

        if fixIDs.contains("fix.embed_fonts") {
            args.append(contentsOf: [
                "-dEmbedAllFonts=true",
                "-dSubsetFonts=true",
            ])
        }

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

        if fixIDs.contains("fix.flatten_transparency") {
            args.append(contentsOf: [
                "-dHaveTransparency=false",
                "-dCompatibilityLevel=1.4",
            ])
        }

        return args
    }
}
