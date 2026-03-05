import Foundation

public enum GhostscriptError: Error, Sendable, LocalizedError {
    case binaryNotFound
    case executionFailed(String)
    case nonZeroExit(code: Int32, stderr: String)

    public var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "Ghostscript not found. Install it with: brew install ghostscript"
        case .executionFailed(let reason):
            return "Ghostscript failed to launch: \(reason)"
        case .nonZeroExit(let code, let stderr):
            let detail = stderr.isEmpty ? "exit code \(code)" : stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            return "Ghostscript exited with error: \(detail)"
        }
    }
}

public struct GhostscriptRunner: Sendable {
    public let binaryPath: String

    public init(binaryPath: String) {
        self.binaryPath = binaryPath
    }

    /// Well-known paths where Ghostscript may be installed.
    private static let searchPaths = [
        "/opt/homebrew/bin/gs",    // Apple Silicon Homebrew
        "/usr/local/bin/gs",       // Intel Homebrew / manual install
        "/usr/bin/gs",             // System install
    ]

    /// Finds a system-installed Ghostscript, or nil if not found.
    public static func system() -> GhostscriptRunner? {
        // Try `which gs` first (covers PATH customizations)
        if let path = whichGS() {
            return GhostscriptRunner(binaryPath: path)
        }
        // Fall back to well-known paths
        for path in searchPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return GhostscriptRunner(binaryPath: path)
            }
        }
        return nil
    }

    /// Runs `which gs` to locate the binary on PATH.
    private static func whichGS() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["gs"]
        // Inherit a basic shell PATH so Homebrew locations are visible.
        var env = ProcessInfo.processInfo.environment
        let extra = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        env["PATH"] = env["PATH"].map { "\(extra):\($0)" } ?? extra
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let path, !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) else {
            return nil
        }
        return path
    }

    /// Runs Ghostscript with the given arguments, reading from inputURL and writing to outputURL.
    @discardableResult
    public func run(arguments: [String], inputURL: URL, outputURL: URL) throws -> String {
        guard FileManager.default.isExecutableFile(atPath: binaryPath) else {
            throw GhostscriptError.binaryNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)

        var args = [
            "-dNOPAUSE", "-dBATCH", "-dQUIET",
            "-sDEVICE=pdfwrite",
            "-sOutputFile=\(outputURL.path)",
        ]
        args.append(contentsOf: arguments)
        args.append(inputURL.path)
        process.arguments = args

        // Log reproducible command for debugging
        let cmdStr = ([binaryPath] + args).map { arg in
            arg.contains(" ") || arg.contains("'") ? "'\(arg)'" : arg
        }.joined(separator: " ")
        print("[GhostscriptRunner] \(cmdStr)")

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
