import Foundation
import MetricKit

/// Receives the diagnostics the system collects for the app (crashes, hangs, CPU and disk-write
/// exceptions, launch problems) and logs them (FR-008 to FR-010; specs/008-release-1-0/
/// contracts/diagnostics.md). Nothing is stored, shown or sent.
///
/// `nonisolated`: the app target's default isolation is the main actor, and the system calls
/// `didReceive(_:)` on a background queue.
nonisolated final class DiagnosticsSubscriber: NSObject, MXMetricManagerSubscriber, Sendable {
    let log: any DiagnosticsLog

    init(log: any DiagnosticsLog) {
        self.log = log
        super.init()
    }

    /// Asks the system for diagnostics; they arrive while the app runs, at most about once a day.
    func start() {
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        Self.handle(payloads.map { $0.jsonRepresentation() }, log: log)
    }

    /// Records each payload's report, or its failure; one payload's failure does not stop the
    /// others (FR-010).
    static func handle(_ payloads: [Data], log: any DiagnosticsLog) {
        for json in payloads {
            do throws(DiagnosticError) {
                log.record(try DiagnosticReport(json: json))
            } catch {
                log.recordUnreadable()
            }
        }
    }
}
