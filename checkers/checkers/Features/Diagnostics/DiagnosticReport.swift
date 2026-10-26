import Foundation

/// A kind of diagnostic the system collects for the app (FR-008; specs/008-release-1-0/
/// data-model.md). The order of the cases is the order a report logs them in.
nonisolated enum DiagnosticKind: CaseIterable, Sendable {
    case crash
    case hang
    case cpuException
    case diskWriteException
    case launch

    /// The payload's array of diagnostics of this kind.
    var arrayKey: String {
        switch self {
        case .crash: "crashDiagnostics"
        case .hang: "hangDiagnostics"
        case .cpuException: "cpuExceptionDiagnostics"
        case .diskWriteException: "diskWriteExceptionDiagnostics"
        case .launch: "appLaunchDiagnostics"
        }
    }

    /// The kind as its log entry starts with it (contracts/diagnostics.md, "Log entries").
    var logName: String {
        switch self {
        case .crash: "Crash"
        case .hang: "Hang"
        case .cpuException: "CPU exception"
        case .diskWriteException: "Disk-write exception"
        case .launch: "Launch"
        }
    }
}

/// Why a payload's JSON gives no report (FR-010).
nonisolated enum DiagnosticError: Error, Equatable, Sendable {
    /// Not a JSON object with both time stamps and arrays of objects.
    case unreadable
}

/// One diagnostic of a report.
nonisolated struct Diagnostic: Equatable, Sendable {
    let kind: DiagnosticKind
    /// Its `diagnosticMetaData` re-encoded as JSON with sorted keys, so the same metadata always
    /// gives the same text; nil without one.
    let detail: String?

    /// The detail as logged.
    var detailText: String {
        detail ?? "none"
    }
}

/// The diagnostics of one payload the system delivers, read from its JSON
/// (contracts/diagnostics.md, "Accepted payload JSON").
nonisolated struct DiagnosticReport: Equatable, Sendable {
    /// The payload's `timeStampBegin`, as written.
    let begin: String
    /// The payload's `timeStampEnd`, as written.
    let end: String
    /// One per item of the five arrays, in kind order.
    let diagnostics: [Diagnostic]

    init(begin: String, end: String, diagnostics: [Diagnostic]) {
        self.begin = begin
        self.end = end
        self.diagnostics = diagnostics
    }

    /// Reads a payload: a JSON object with non-empty string time stamps; each of the five arrays
    /// may be missing (none of that kind) but, when present, must be an array of objects. Unknown
    /// keys are ignored. Anything else is `DiagnosticError.unreadable`.
    init(json: Data) throws(DiagnosticError) {
        guard let payload = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
            let begin = payload["timeStampBegin"] as? String, !begin.isEmpty,
            let end = payload["timeStampEnd"] as? String, !end.isEmpty
        else { throw .unreadable }

        var diagnostics: [Diagnostic] = []
        for kind in DiagnosticKind.allCases {
            guard let array = payload[kind.arrayKey] else { continue }
            guard let items = array as? [Any] else { throw .unreadable }
            for item in items {
                guard let item = item as? [String: Any] else { throw .unreadable }
                let detail = try Self.detail(item["diagnosticMetaData"])
                diagnostics.append(Diagnostic(kind: kind, detail: detail))
            }
        }
        self.init(begin: begin, end: end, diagnostics: diagnostics)
    }

    /// The metadata as JSON text with sorted keys, or nil without metadata.
    private static func detail(_ metadata: Any?) throws(DiagnosticError) -> String? {
        guard let metadata else { return nil }
        let options: JSONSerialization.WritingOptions = [.sortedKeys, .fragmentsAllowed]
        guard let data = try? JSONSerialization.data(withJSONObject: metadata, options: options),
            let text = String(bytes: data, encoding: .utf8)
        else { throw .unreadable }
        return text
    }
}
