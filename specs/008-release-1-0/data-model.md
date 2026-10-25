# Data Model: Release 1.0

Phase 1 output for `specs/008-release-1-0/plan.md`. The slice adds one small feature to the app
(diagnostics) and two log lines; everything else is release records kept as files in the
repository. Contracts: [diagnostics.md](contracts/diagnostics.md),
[release-tooling.md](contracts/release-tooling.md), [store-listing.md](contracts/store-listing.md).

## Diagnostics (`Features/Diagnostics/`, new, R9)

### DiagnosticKind (new enum)

| Case | Payload array | Name in the log |
|---|---|---|
| `crash` | `crashDiagnostics` | crash |
| `hang` | `hangDiagnostics` | hang |
| `cpuException` | `cpuExceptionDiagnostics` | CPU exception |
| `diskWriteException` | `diskWriteExceptionDiagnostics` | disk-write exception |
| `launch` | `appLaunchDiagnostics` | launch |

`nonisolated`, `Sendable`, `CaseIterable`; the order above is the order a report logs them in.

### DiagnosticReport (new struct)

| Field | Type | Rule |
|---|---|---|
| `begin` | `String` | the payload's `timeStampBegin`, as written |
| `end` | `String` | the payload's `timeStampEnd`, as written |
| `diagnostics` | `[DiagnosticKind]` | one element per item of the five arrays, in kind order |

- `init(json: Data) throws(DiagnosticError)`: the bytes must be a JSON object with non-empty
  string time stamps; each of the five arrays may be missing (none of that kind) but, when
  present, must be an array of objects. Unknown keys are ignored. Anything else is
  `DiagnosticError.unreadable`.
- A report with no diagnostics is valid and logs nothing (FR-008 counts diagnostics, not payloads).
- `nonisolated`, `Sendable`, `Equatable`; built off the main actor.

### DiagnosticError (new enum)

| Case | When |
|---|---|
| `unreadable` | The payload's JSON is not an object with the time stamps and arrays above |

### DiagnosticsLog (new protocol) and its conformances

| Member | Meaning |
|---|---|
| `record(_ report: DiagnosticReport)` | one entry per diagnostic, in order |
| `recordUnreadable()` | one entry for a payload that could not be read |

- `OSLogDiagnosticsLog` (live): writes to `Log.diagnostics` in the format of
  [diagnostics.md](contracts/diagnostics.md).
- `RecordingDiagnosticsLog` (tests): keeps the entries it would write, in order.
- Both `nonisolated` and `Sendable`, since the system calls from a background queue.

### DiagnosticsSubscriber (new class)

- `final class DiagnosticsSubscriber: NSObject, MXMetricManagerSubscriber, Sendable`, holding a
  `DiagnosticsLog`. `didReceive(_ payloads: [MXDiagnosticPayload])` (nonisolated, background
  queue) reads each payload's `jsonRepresentation()` into a `DiagnosticReport` and records it, or
  records the failure; one payload's failure does not stop the others (FR-010).
- `start()` adds it to `MXMetricManager.shared`; the system singleton is used only here (II.3).
- Created and started once by `CheckersApp`, which keeps it for the app's lifetime.

### Log (changed, `Support/Logging.swift`)

- New category `diagnostics`; `LoggingTests` lists eight categories.

## Measurement lines (changed, R6)

| Where | Category | When | Values (public) |
|---|---|---|---|
| `GameSession`, the computer's turn | `computer` | its first step appears | difficulty, milliseconds since the turn started |
| `SoundBank` | `sound` | a sound starts playing | effect, milliseconds since the step asked for it |
| `SoundBank` | `sound` | its audio session becomes active | the session's output latency in milliseconds |

Exact texts are in [release-tooling.md](contracts/release-tooling.md) ("Device logs"), because
`scripts/device-timings.py` parses them. Notice level, so they appear in the console capture.

## App configuration (changed, R11)

| Setting | Value | Checked by |
|---|---|---|
| `INFOPLIST_KEY_CFBundleDisplayName` | Checkers | `PlatformSettingsTests` (built Info.plist) |
| `InfoPlist.xcstrings` | `CFBundleDisplayName` = Checkers (en) | `PlatformSettingsTests` (localized Info.plist) |
| `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` | NO | `PlatformSettingsTests` |
| Generated launch screen | unchanged: no image, no color | `PlatformSettingsTests` |
| `AppIcon.appiconset` | three 1024 px files written by `make-icon.py` | `make-icon.py --check` (script tests) |
| `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` | 1.0 / 1 (the build number is set at archive time) | `release.sh` |

## Release records (files)

### Build record (`release/builds.md`, R14)

| Field | Rule |
|---|---|
| Build | integer, higher than every earlier row (FR-023) |
| Commit | full SHA of the archived commit; `CI gate` passed for it |
| Uploaded | date (YYYY-MM-DD) |
| State | uploaded → processed → TestFlight internal → external (after Beta App Review) → submitted → approved, or rejected (FR-029) |
| Notes | what changed since the previous build; which checklist items it can affect |

States only move forward; a rejected build stays rejected and a new build gets a new row.

### Release checklist item (`checklists/release.md`, R16)

| Field | Rule |
|---|---|
| ID | `RC-01`… in table order |
| Source | E8 requirement or the earlier slice's `validation.md` section |
| Check | what to do, in one or two sentences |
| Build | the build number it was last run on |
| Result | passed, failed, or accepted |
| Reason | required when accepted: the owner's words (FR-026) |

An item passed on an earlier build counts for a later build only if that build's notes in
`release/builds.md` say the change cannot affect it (spec edge case).

### Traceability entry (`traceability.md`, generated, R15)

| Field | Rule |
|---|---|
| FRD ID | every ID in `FRD.md` v1.3, in the FRD's order |
| Tests | test file and name for each test that names the ID |
| Manual checks | release checklist IDs that name it, with their results |
| Status | covered, removed (FR-PLAT-02 only), or missing (fails `--check`) |

### Device measurement (`checklists/validation.md`, R4 to R6)

| Field | Rule |
|---|---|
| Metric | cold launch, hitch-time ratio, total hitch time, computer first-step time per difficulty, sound start delay, output latency |
| Values | every value, plus the median (launch) or the share within range (computer) |
| Build | configuration (Release), commit and build number when from an upload |
| Device | name, model, iOS version |
| Verdict | pass or miss against its target; a miss records its profile (VII.4) |

### Store listing (`release/store-listing.md`, R13)

Fields, limits and the owner's steps in App Store Connect are in
[store-listing.md](contracts/store-listing.md).
