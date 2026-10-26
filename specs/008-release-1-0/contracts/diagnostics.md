# Contract: Diagnostics after release

Implements spec FR-008 to FR-010 and SC-006 (research R9). Types are in
[data-model.md](../data-model.md).

## Receiving reports

- `CheckersApp` creates one `DiagnosticsSubscriber` with an `OSLogDiagnosticsLog`, keeps it for
  the app's lifetime, and calls `start()` (which adds it to `MXMetricManager.shared`) from a
  `.task` on the root view, after the first frame: the first use of MetricKit never delays launch
  (Constitution VII.1), and the system delivers diagnostics whenever the app is running with a
  subscriber. The launch test (R4) and the CI launch report confirm the budget.
- `DiagnosticsSubscriber` is a `nonisolated final class` (the app target's default isolation is the
  main actor; MetricKit calls on its own queue) whose only stored property is the `Sendable` log;
  `RecordingDiagnosticsLog` keeps its entries in a `Mutex`. No `@unchecked Sendable`
  (Constitution IV.4).
- The system calls `didReceive(_:)` on a background queue, at most about once a day, with the
  diagnostics of earlier sessions. Each payload is handled on its own: its
  `jsonRepresentation()` becomes a `DiagnosticReport`, which the log records; if the bytes cannot
  be read, the log records one failure and the next payload is handled as usual.
- Nothing else happens: no file, no `UserDefaults` key, no screen, no alert, no network request,
  no permission. The privacy manifest does not change (FR-009, US3 scenario 4).

## Accepted payload JSON

```json
{
  "timeStampBegin": "2026-10-26 01:45:41",
  "timeStampEnd": "2026-10-26 01:45:41",
  "crashDiagnostics": [{ "diagnosticMetaData": { "signal": 11 }, "callStackTree": {} }],
  "hangDiagnostics": [{ "diagnosticMetaData": { "hangDuration": "3 sec" } }],
  "cpuExceptionDiagnostics": [],
  "diskWriteExceptionDiagnostics": [],
  "appLaunchDiagnostics": []
}
```

- Required: a JSON object whose `timeStampBegin` and `timeStampEnd` are non-empty strings.
- Optional: each of the five arrays; a missing array means no diagnostics of that kind. A present
  array must hold objects. Each object is one diagnostic of its array's kind.
- An object's `diagnosticMetaData`, if present, is kept as its detail: re-encoded as JSON with
  sorted keys, so the same input always logs the same text. `callStackTree` and other keys are
  ignored.
- Anything else, including bytes that are not JSON, is `DiagnosticError.unreadable`.
- Apple's key names were confirmed on the phone with Xcode's Debug › Simulate MetricKit Payloads
  on 2026-10-26 (T028, iOS 27.0.1, quickstart §3): all five arrays, both time stamps and
  `diagnosticMetaData`. The time stamps came without a zone, as in the example above; the app
  keeps them as written, so the fixtures' `+0000` form reads the same way. If the names change
  in a later iOS, the fixtures and this section change together.

## Log entries (category `diagnostics`)

One entry per diagnostic, in kind order (crash, hang, CPU exception, disk-write exception,
launch):

```text
<Kind> reported for <begin> to <end>; details: <detail>
```

- `<Kind>` is the name from the data model with its first letter capitalized ("Crash", "Hang",
  "CPU exception", "Disk-write exception", "Launch"). It and the two time stamps are
  `privacy: .public`: they cannot identify the player.
- `<detail>` is the diagnostic's metadata text, or "none". It uses the default private redaction
  (FR-009, Constitution IX.3): it holds values such as the device type, OS version and region
  format.
- Level: `error` for crashes, `notice` for the other kinds.

For a payload that cannot be read, one entry at `error` level:

```text
A diagnostic report could not be read
```

## Tests (US3)

| Test | Proves |
|---|---|
| One fixture per kind | exactly one entry, with that kind and the payload's time stamps (SC-006) |
| A payload with two crashes and a hang | three entries, in kind order |
| A payload with no arrays | valid, no entries |
| Damaged bytes; a payload without time stamps; an array of strings | one failure entry each, no crash (FR-010) |
| Two payloads, the first damaged | one failure entry, then the second payload's entries |
| Detail text | sorted keys, the same text on every run; "none" without metadata |
| `LoggingTests` | the `diagnostics` category exists |
| `PrivacyManifestTests` (unchanged) | still no collected data, no tracking, no usage descriptions |

Tests use `RecordingDiagnosticsLog` and JSON fixtures in `checkersTests/Support/`; they call the
subscriber's payload handling through a function that takes the JSON bytes, since
`MXDiagnosticPayload` cannot be created in tests.
