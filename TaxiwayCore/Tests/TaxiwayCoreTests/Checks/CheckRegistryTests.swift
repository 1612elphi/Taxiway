import Testing
import Foundation
@testable import TaxiwayCore

@Suite("CheckRegistry & CheckEntry")
struct CheckRegistryTests {

    // MARK: - CheckEntry

    @Test("CheckEntry round-trip through JSON")
    func checkEntryJSONCodable() throws {
        let params = FileSizeMaxCheck.Parameters(maxSizeMB: 10.0)
        let entry = try CheckEntry(typeID: "file.size.max", enabled: true, parameters: params, severityOverride: .warning)

        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(CheckEntry.self, from: data)

        #expect(decoded.typeID == entry.typeID)
        #expect(decoded.enabled == entry.enabled)
        #expect(decoded.severityOverride == .warning)
        #expect(decoded.parametersJSON == entry.parametersJSON)
    }

    @Test("CheckEntry init with raw parametersJSON")
    func checkEntryRawInit() throws {
        let params = FileSizeMaxCheck.Parameters(maxSizeMB: 5.0)
        let jsonData = try JSONEncoder().encode(params)
        let entry = CheckEntry(typeID: "file.size.max", enabled: false, parametersJSON: jsonData)

        #expect(entry.typeID == "file.size.max")
        #expect(entry.enabled == false)
        #expect(entry.severityOverride == nil)
        #expect(entry.parametersJSON == jsonData)
    }

    @Test("CheckEntry with nil severityOverride")
    func checkEntryNilSeverity() throws {
        let params = FileSizeMaxCheck.Parameters(maxSizeMB: 10.0)
        let entry = try CheckEntry(typeID: "file.size.max", enabled: true, parameters: params)

        #expect(entry.severityOverride == nil)
    }

    // MARK: - CheckRegistry

    @Test("Register and instantiate FileSizeMaxCheck")
    func registerAndInstantiate() throws {
        var registry = CheckRegistry()
        registry.register(FileSizeMaxCheck.self)

        let params = FileSizeMaxCheck.Parameters(maxSizeMB: 10.0)
        let entry = try CheckEntry(typeID: "file.size.max", enabled: true, parameters: params)

        let check = try registry.instantiate(from: entry)
        #expect(type(of: check) == FileSizeMaxCheck.self)
        #expect(check.name == "File Size (max)")
        #expect(check.category == .file)
    }

    @Test("Instantiate unknown typeID throws unknownTypeID error")
    func unknownTypeIDThrows() throws {
        let registry = CheckRegistry()
        let entry = CheckEntry(typeID: "nonexistent.check", enabled: true, parametersJSON: Data("{}".utf8))

        #expect(throws: CheckRegistryError.unknownTypeID("nonexistent.check")) {
            try registry.instantiate(from: entry)
        }
    }

    @Test("Instantiate with invalid JSON throws decodingFailed error")
    func invalidJSONThrows() throws {
        var registry = CheckRegistry()
        registry.register(FileSizeMaxCheck.self)

        let entry = CheckEntry(typeID: "file.size.max", enabled: true, parametersJSON: Data("not json".utf8))

        #expect(throws: CheckRegistryError.decodingFailed("file.size.max")) {
            try registry.instantiate(from: entry)
        }
    }

    @Test("registeredTypeIDs returns registered IDs sorted")
    func registeredTypeIDs() {
        var registry = CheckRegistry()
        #expect(registry.registeredTypeIDs.isEmpty)

        registry.register(FileSizeMaxCheck.self)
        #expect(registry.registeredTypeIDs == ["file.size.max"])
    }

    // MARK: - FileSizeMaxCheck execution

    @Test("FileSizeMaxCheck passes when file is under limit")
    func fileSizeMaxPassCase() {
        // Sample document is 5 MB
        let check = FileSizeMaxCheck(parameters: .init(maxSizeMB: 10.0))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
        #expect(result.message.contains("OK"))
        #expect(result.affectedItems.isEmpty)
    }

    @Test("FileSizeMaxCheck fails when file exceeds limit")
    func fileSizeMaxFailCase() {
        // Sample document is 5 MB, limit is 0.1 MB
        let check = FileSizeMaxCheck(parameters: .init(maxSizeMB: 0.1))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
        #expect(result.message.contains("exceeds"))
        #expect(result.detail != nil)
        #expect(result.affectedItems == [.document])
    }

    @Test("FileSizeMaxCheck passes when file is exactly at limit")
    func fileSizeMaxExactLimit() {
        // Sample is exactly 5 MB
        let check = FileSizeMaxCheck(parameters: .init(maxSizeMB: 5.0))
        let result = check.run(on: .sample)

        #expect(result.status == .pass)
    }

    @Test("FileSizeMaxCheck fails when file is just over limit")
    func fileSizeMaxJustOverLimit() {
        // Sample is 5 MB, limit is 4.999
        let check = FileSizeMaxCheck(parameters: .init(maxSizeMB: 4.999))
        let result = check.run(on: .sample)

        #expect(result.status == .fail)
    }

    @Test("FileSizeMaxCheck with empty document passes")
    func fileSizeMaxEmptyDocument() {
        // Empty doc is 1024 bytes ≈ 0.001 MB
        let check = FileSizeMaxCheck(parameters: .init(maxSizeMB: 1.0))
        let result = check.run(on: .empty)

        #expect(result.status == .pass)
    }

    // MARK: - Severity override

    @Test("Severity override changes effectiveSeverity")
    func severityOverride() {
        let check = FileSizeMaxCheck(parameters: .init(maxSizeMB: 10.0), severityOverride: .info)

        #expect(check.defaultSeverity == .error)
        #expect(check.effectiveSeverity == .info)
    }

    @Test("Severity override propagates to CheckResult")
    func severityOverrideInResult() {
        let check = FileSizeMaxCheck(parameters: .init(maxSizeMB: 10.0), severityOverride: .warning)
        let result = check.run(on: .sample)

        #expect(result.severity == .warning)
    }

    @Test("No severity override uses defaultSeverity")
    func noSeverityOverride() {
        let check = FileSizeMaxCheck(parameters: .init(maxSizeMB: 10.0))

        #expect(check.severityOverride == nil)
        #expect(check.effectiveSeverity == .error)
    }

    // MARK: - ParameterisedCheck helpers

    @Test("ParameterisedCheck pass helper produces correct result")
    func passHelper() {
        let check = FileSizeMaxCheck(parameters: .init(maxSizeMB: 10.0))
        let result = check.pass(message: "All good")

        #expect(result.status == .pass)
        #expect(result.checkTypeID == "file.size.max")
        #expect(result.message == "All good")
        #expect(result.detail == nil)
        #expect(result.affectedItems.isEmpty)
    }

    @Test("ParameterisedCheck fail helper produces correct result")
    func failHelper() {
        let check = FileSizeMaxCheck(parameters: .init(maxSizeMB: 10.0))
        let result = check.fail(
            message: "Too big",
            detail: "Way too big",
            affectedItems: [.document, .page(index: 0)]
        )

        #expect(result.status == .fail)
        #expect(result.checkTypeID == "file.size.max")
        #expect(result.message == "Too big")
        #expect(result.detail == "Way too big")
        #expect(result.affectedItems.count == 2)
    }

    @Test("ParameterisedCheck skip helper produces correct result")
    func skipHelper() {
        let check = FileSizeMaxCheck(parameters: .init(maxSizeMB: 10.0))
        let result = check.skip(message: "Not applicable")

        #expect(result.status == .skipped)
        #expect(result.checkTypeID == "file.size.max")
        #expect(result.message == "Not applicable")
        #expect(result.detail == nil)
        #expect(result.affectedItems.isEmpty)
    }

    // MARK: - Registry round-trip with severity override

    @Test("Registry instantiation preserves severity override")
    func registryWithSeverityOverride() throws {
        var registry = CheckRegistry()
        registry.register(FileSizeMaxCheck.self)

        let params = FileSizeMaxCheck.Parameters(maxSizeMB: 10.0)
        let entry = try CheckEntry(typeID: "file.size.max", enabled: true, parameters: params, severityOverride: .info)

        let check = try registry.instantiate(from: entry)
        let fileSizeCheck = try #require(check as? FileSizeMaxCheck)

        #expect(fileSizeCheck.severityOverride == .info)
        #expect(fileSizeCheck.effectiveSeverity == .info)
        #expect(fileSizeCheck.parameters.maxSizeMB == 10.0)
    }
}
