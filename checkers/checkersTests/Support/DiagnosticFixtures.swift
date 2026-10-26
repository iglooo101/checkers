import Foundation

@testable import checkers

/// Diagnostic payloads as MetricKit's `jsonRepresentation()` delivers them
/// (specs/008-release-1-0/contracts/diagnostics.md, "Accepted payload JSON"). The key names are
/// written out here rather than taken from the app, so a wrong key in the parser fails the tests.
nonisolated enum DiagnosticFixtures {
    static let begin = "2026-10-25 21:00:00 +0000"
    static let end = "2026-10-25 21:59:00 +0000"

    /// Each kind's array in a payload.
    static let arrayKeys: [DiagnosticKind: String] = [
        .crash: "crashDiagnostics",
        .hang: "hangDiagnostics",
        .cpuException: "cpuExceptionDiagnostics",
        .diskWriteException: "diskWriteExceptionDiagnostics",
        .launch: "appLaunchDiagnostics",
    ]

    /// The metadata of `one(_:)`'s diagnostic, with its keys in no particular order.
    static let metadata = """
        { "signal": 11, "deviceType": "iPhone17,3", "appVersion": "1.0", "osVersion": "iPhone OS 27.0.1 (24A350)" }
        """

    /// The same metadata with its keys in another order.
    static let reorderedMetadata = """
        { "osVersion": "iPhone OS 27.0.1 (24A350)", "appVersion": "1.0", "signal": 11, "deviceType": "iPhone17,3" }
        """

    /// `metadata` as a diagnostic's detail: re-encoded with sorted keys.
    static let detail =
        #"{"appVersion":"1.0","deviceType":"iPhone17,3","osVersion":"iPhone OS 27.0.1 (24A350)","signal":11}"#

    /// A payload object with both time stamps and these members.
    static func payload(_ members: String...) -> Data {
        let stamps = [#""timeStampBegin": "\#(begin)""#, #""timeStampEnd": "\#(end)""#]
        return Data("{ \((stamps + members).joined(separator: ", ")) }".utf8)
    }

    /// One diagnostic of this kind, with `metadata` and a call stack the app ignores; the other
    /// four arrays are present and empty.
    static func one(_ kind: DiagnosticKind, metadata: String = metadata) -> Data {
        let item = #"{ "diagnosticMetaData": \#(metadata), "callStackTree": {} }"#
        let members = DiagnosticKind.allCases.map { other in
            #""\#(arrayKeys[other]!)": [\#(other == kind ? item : "")]"#
        }
        return payload(members.joined(separator: ", "))
    }

    /// Two crashes, the second without metadata, and a hang; the hang's array comes first.
    static let twoCrashesAndAHang = payload(
        #""hangDiagnostics": [{ "diagnosticMetaData": { "hangDuration": "3 sec" } }]"#,
        #""crashDiagnostics": [{ "diagnosticMetaData": { "signal": 11 } }, { "callStackTree": {} }]"#
    )

    /// Both time stamps and none of the five arrays.
    static let noArrays = payload()

    /// Bytes no report can be read from, each with a label.
    static let damaged: [(String, Data)] = [
        ("bytes that are not JSON", Data([0xFF, 0x00, 0x7B, 0x22])),
        ("text that is not JSON", Data("crashDiagnostics".utf8)),
        (
            "no timeStampEnd",
            Data(#"{ "timeStampBegin": "\#(begin)", "crashDiagnostics": [] }"#.utf8)
        ),
        (
            "an empty timeStampBegin",
            Data(#"{ "timeStampBegin": "", "timeStampEnd": "\#(end)" }"#.utf8)
        ),
        (
            "a timeStampBegin that is a number",
            Data(#"{ "timeStampBegin": 1761426000, "timeStampEnd": "\#(end)" }"#.utf8)
        ),
        ("crashDiagnostics holding strings", payload(#""crashDiagnostics": ["crash"]"#)),
        ("hangDiagnostics that is an object", payload(#""hangDiagnostics": {}"#)),
        (
            "a top-level array",
            Data(#"[{ "timeStampBegin": "\#(begin)", "timeStampEnd": "\#(end)" }]"#.utf8)
        ),
    ]
}
