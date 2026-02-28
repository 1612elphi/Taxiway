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
