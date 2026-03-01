import Foundation

public enum CheckRegistryError: Error, Equatable {
    case unknownTypeID(String)
    case decodingFailed(String)
}

public struct CheckRegistry: @unchecked Sendable {
    private var factories: [String: @Sendable (UUID, Data, CheckSeverity?) throws -> any Check] = [:]

    public init() {}

    public mutating func register<C: ParameterisedCheck>(_ type: C.Type) {
        factories[C.typeID] = { id, data, severityOverride in
            let params = try JSONDecoder().decode(C.Parameters.self, from: data)
            return C(id: id, parameters: params, severityOverride: severityOverride)
        }
    }

    public func instantiate(from entry: CheckEntry) throws -> any Check {
        guard let factory = factories[entry.typeID] else {
            throw CheckRegistryError.unknownTypeID(entry.typeID)
        }
        do {
            return try factory(UUID(), entry.parametersJSON, entry.severityOverride)
        } catch let error as CheckRegistryError {
            throw error
        } catch {
            throw CheckRegistryError.decodingFailed(entry.typeID)
        }
    }

    public var registeredTypeIDs: [String] {
        Array(factories.keys).sorted()
    }
}
