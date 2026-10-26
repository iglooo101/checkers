import OSLog
import Synchronization

/// Where the diagnostics the system delivers are written (FR-008). Called on a background queue.
nonisolated protocol DiagnosticsLog: Sendable {
    /// One entry per diagnostic of the report, in order.
    func record(_ report: DiagnosticReport)
    /// One entry for a payload that could not be read (FR-010).
    func recordUnreadable()
}

/// Writes to the app's log under the `diagnostics` category, on the phone only
/// (specs/008-release-1-0/contracts/diagnostics.md, "Log entries"). The kind and the time stamps
/// are public; the detail keeps the default private redaction (FR-009, Constitution IX.3).
nonisolated struct OSLogDiagnosticsLog: DiagnosticsLog {
    func record(_ report: DiagnosticReport) {
        let (begin, end) = (report.begin, report.end)
        for diagnostic in report.diagnostics {
            let kind = diagnostic.kind.logName
            let detail = diagnostic.detailText
            // `.default` is the notice level.
            let level: OSLogType = diagnostic.kind == .crash ? .error : .default
            Log.diagnostics.log(
                level: level,
                "\(kind, privacy: .public) reported for \(begin, privacy: .public) to \(end, privacy: .public); details: \(detail)"
            )
        }
    }

    func recordUnreadable() {
        Log.diagnostics.error("A diagnostic report could not be read")
    }
}

/// Keeps the reports and failures it is given, in order, and writes nothing: for tests.
nonisolated final class RecordingDiagnosticsLog: DiagnosticsLog {
    nonisolated enum Entry: Equatable, Sendable {
        case report(DiagnosticReport)
        case unreadable
    }

    private let recorded = Mutex<[Entry]>([])

    /// Everything recorded so far, in order.
    var entries: [Entry] {
        recorded.withLock { $0 }
    }

    func record(_ report: DiagnosticReport) {
        recorded.withLock { $0.append(.report(report)) }
    }

    func recordUnreadable() {
        recorded.withLock { $0.append(.unreadable) }
    }
}
