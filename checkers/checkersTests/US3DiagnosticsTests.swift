import Foundation
import Testing

@testable import checkers

/// Diagnostics after release (specs/008-release-1-0/spec.md, US3; contracts/diagnostics.md): each
/// payload the system delivers becomes a report whose diagnostics are logged one by one, in kind
/// order, or one failure when it cannot be read. `MXDiagnosticPayload` cannot be created in tests,
/// so they hand the subscriber the payloads' JSON.
struct US3DiagnosticsTests {
    /// What the subscriber records for these payloads.
    static func entries(_ payloads: [Data]) -> [RecordingDiagnosticsLog.Entry] {
        let log = RecordingDiagnosticsLog()
        DiagnosticsSubscriber.handle(payloads, log: log)
        return log.entries
    }

    /// A report over the fixtures' time stamps.
    static func report(_ diagnostics: [Diagnostic]) -> RecordingDiagnosticsLog.Entry {
        .report(
            DiagnosticReport(
                begin: DiagnosticFixtures.begin, end: DiagnosticFixtures.end,
                diagnostics: diagnostics))
    }

    @Test(
        "US3 FR-008: each kind of diagnostic gives exactly one entry, with the payload's times",
        arguments: DiagnosticKind.allCases
    )
    func oneEntryPerKind(_ kind: DiagnosticKind) {
        #expect(
            Self.entries([DiagnosticFixtures.one(kind)]) == [
                Self.report([Diagnostic(kind: kind, detail: DiagnosticFixtures.detail)])
            ])
    }

    @Test("US3 FR-008: the kinds are logged in the contract's order, under its names")
    func kindsInOrder() {
        #expect(
            DiagnosticKind.allCases.map(\.logName) == [
                "Crash", "Hang", "CPU exception", "Disk-write exception", "Launch",
            ])
    }

    @Test("US3 FR-008: a payload with two crashes and a hang gives three entries, in kind order")
    func severalDiagnostics() {
        #expect(
            Self.entries([DiagnosticFixtures.twoCrashesAndAHang]) == [
                Self.report([
                    Diagnostic(kind: .crash, detail: #"{"signal":11}"#),
                    Diagnostic(kind: .crash, detail: nil),
                    Diagnostic(kind: .hang, detail: #"{"hangDuration":"3 sec"}"#),
                ])
            ])
    }

    @Test("US3 FR-008: a payload without diagnostics is read and gives no entry")
    func noDiagnostics() {
        #expect(Self.entries([DiagnosticFixtures.noArrays]) == [Self.report([])])
    }

    @Test("US3 FR-010: a payload that cannot be read gives one failure entry and no report")
    func unreadablePayload() {
        for (label, data) in DiagnosticFixtures.damaged {
            #expect(throws: DiagnosticError.unreadable, "\(label)") {
                try DiagnosticReport(json: data)
            }
            #expect(Self.entries([data]) == [.unreadable], "\(label)")
        }
    }

    @Test("US3 FR-010: after a payload that cannot be read, the next one is handled as usual")
    func failureDoesNotStopTheNext() {
        for (label, data) in DiagnosticFixtures.damaged {
            #expect(
                Self.entries([data, DiagnosticFixtures.one(.hang)]) == [
                    .unreadable,
                    Self.report([Diagnostic(kind: .hang, detail: DiagnosticFixtures.detail)]),
                ], "\(label)")
        }
    }

    @Test("US3 FR-009: a detail is the metadata with sorted keys, the same text every time")
    func detailText() throws {
        let first = try DiagnosticReport(json: DiagnosticFixtures.one(.crash))
        let again = try DiagnosticReport(json: DiagnosticFixtures.one(.crash))
        let reordered = try DiagnosticReport(
            json: DiagnosticFixtures.one(.crash, metadata: DiagnosticFixtures.reorderedMetadata))
        #expect(first.diagnostics.map(\.detailText) == [DiagnosticFixtures.detail])
        #expect(again == first)
        #expect(reordered == first)
    }

    @Test("US3 FR-009: a diagnostic without metadata has no detail, logged as \"none\"")
    func noDetail() throws {
        let report = try DiagnosticReport(json: DiagnosticFixtures.twoCrashesAndAHang)
        let bare = try #require(report.diagnostics.first { $0.detail == nil })
        #expect(bare.detailText == "none")
    }
}
