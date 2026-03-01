import Foundation
import TaxiwayCore

@Observable
final class SessionStore {
    var sessions: [UUID: PreflightSession] = [:]

    func createSession(url: URL, profile: PreflightProfile) -> UUID {
        let session = PreflightSession(fileURL: url, profile: profile)
        sessions[session.id] = session
        return session.id
    }

    func removeSession(id: UUID) {
        sessions.removeValue(forKey: id)
    }
}
