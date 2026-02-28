import Foundation

public struct CheckEntry: Codable, Sendable, Equatable {
    public let typeID: String
    public var enabled: Bool
    public var severityOverride: CheckSeverity?
    public var parametersJSON: Data

    public init(typeID: String, enabled: Bool, parametersJSON: Data, severityOverride: CheckSeverity? = nil) {
        self.typeID = typeID
        self.enabled = enabled
        self.parametersJSON = parametersJSON
        self.severityOverride = severityOverride
    }

    public init<P: CheckParameters>(typeID: String, enabled: Bool, parameters: P, severityOverride: CheckSeverity? = nil) throws {
        self.typeID = typeID
        self.enabled = enabled
        self.parametersJSON = try JSONEncoder().encode(parameters)
        self.severityOverride = severityOverride
    }
}
