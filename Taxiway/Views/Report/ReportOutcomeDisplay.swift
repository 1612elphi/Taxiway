import TaxiwayCore

enum DisplayOutcome {
    case pass
    case warn
    case fail
}

extension PreflightReport {
    var displayOutcome: DisplayOutcome {
        // Any error-severity failure → hard fail
        if results.contains(where: { $0.status == .fail && $0.severity == .error }) {
            return .fail
        }
        // Any warning status or warning-severity failure → warn
        if results.contains(where: {
            $0.status == .warning || ($0.status == .fail && $0.severity == .warning)
        }) {
            return .warn
        }
        return .pass
    }
}
