import SwiftUI
import TaxiwayCore

struct PreflightWindowView: View {
    let session: PreflightSession
    @Environment(SessionStore.self) var sessionStore

    var body: some View {
        Group {
            switch session.phase {
            case .running:
                RunningView(session: session)
            case .report(let report):
                ReportView(session: session, report: report)
            }
        }
        .navigationTitle(session.fileURL.lastPathComponent)
        .onDisappear {
            sessionStore.removeSession(id: session.id)
        }
    }
}
