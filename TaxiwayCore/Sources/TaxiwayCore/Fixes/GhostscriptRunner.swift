import Foundation

public enum GhostscriptError: Error, Sendable {
    case binaryNotFound
    case executionFailed(String)
    case nonZeroExit(code: Int32, stderr: String)
}

public struct GhostscriptRunner: Sendable {
    public let binaryURL: URL
    public let libURL: URL

    public init(binaryURL: URL, libURL: URL) {
        self.binaryURL = binaryURL
        self.libURL = libURL
    }

    /// Attempts to locate a bundled Ghostscript in the app's Resources/gs/ directory.
    public static func bundled() -> GhostscriptRunner? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let gsDir = resourceURL.appendingPathComponent("gs")
        let binaryURL = gsDir.appendingPathComponent("bin/gs")
        let libURL = gsDir.appendingPathComponent("lib")

        guard FileManager.default.fileExists(atPath: binaryURL.path) else { return nil }
        return GhostscriptRunner(binaryURL: binaryURL, libURL: libURL)
    }

    /// Runs Ghostscript with the given arguments, reading from inputURL and writing to outputURL.
    /// Returns the combined stdout output on success.
    @discardableResult
    public func run(arguments: [String], inputURL: URL, outputURL: URL) throws -> String {
        guard FileManager.default.fileExists(atPath: binaryURL.path) else {
            throw GhostscriptError.binaryNotFound
        }

        let process = Process()
        process.executableURL = binaryURL
        process.environment = ProcessInfo.processInfo.environment.merging(
            ["GS_LIB": libURL.path]
        ) { _, new in new }

        var args = [
            "-dNOPAUSE", "-dBATCH", "-dQUIET",
            "-sDEVICE=pdfwrite",
            "-sOutputFile=\(outputURL.path)",
        ]
        args.append(contentsOf: arguments)
        args.append(inputURL.path)
        process.arguments = args

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw GhostscriptError.executionFailed(error.localizedDescription)
        }
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stdoutString = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderrString = String(data: stderrData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw GhostscriptError.nonZeroExit(code: process.terminationStatus, stderr: stderrString)
        }

        return stdoutString
    }
}
