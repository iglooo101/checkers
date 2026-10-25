# Implementation Plan: Release 1.0

**Branch**: `008-release-1-0` | **Date**: 2026-10-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/008-release-1-0/spec.md`

## Summary

Verify the feature-complete app on the owner's iPhone, give it what the App Store needs, and take
it through TestFlight to an approved 1.0. Research on the phone settled the open question: Xcode
26.3 builds, installs, debugs, runs UI tests and records Instruments traces on iOS 27.0.1
(*measured*), so every device check runs from the Mac, through a new `checkers-device` scheme
that builds Release without the engine's `@testable` tests. A Release build reached its first
frame in a median of 231 ms over five cold launches (budget 400 ms) and showed no hitches over
thirty fast Rules swipes (*measured*); the full checks run ten launches and one scripted session
measured with `XCTHitchMetric`, while the app's own log, mirrored to the Mac through `devicectl`,
gives the computer's first-step times and the sound delays. The app gains one small feature, a
MetricKit subscriber that logs each diagnostic's kind and time on the phone, plus two timing log
lines, the name "Checkers", the encryption declaration and a scripted icon in three variants.
Everything else is tooling and records: a screenshot run on the iPhone 17 simulator (the
required 1206 × 2622 size), a generated FRD traceability matrix (84 of 85 IDs already named in
tests, the 85th removed), an archive check, an upload script using the App Store Connect key
from `../secrets`, the release checklist that gathers every open hand check of E3 to E7 and gates
submission, the store texts, and two GitHub Pages. Research: [research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.2 (Xcode 26.3, iOS 26.2 SDK), Swift 6 language mode, complete
strict concurrency; app target default isolation is the main actor with approachable
concurrency; Python 3 (standard library only) and bash for scripts

**Primary Dependencies**: SwiftUI, MetricKit (`MXMetricManager`, `MXDiagnosticPayload`), OSLog,
AVFoundation (unchanged, one log line), XCTest (`XCTApplicationLaunchMetric`, `XCTHitchMetric`),
`CheckersEngine` (unchanged); tools: `xcodebuild`, `xcrun devicectl`, `xcrun simctl`, `gh`;
SwiftLintPlugins (build-time, existing)

**Storage**: none new in the app; release records as files in the repository (`release/`,
`specs/008-release-1-0/`); the upload key in `../secrets`, outside it

**Testing**: Swift Testing for the diagnostics parser and log (JSON fixtures) and the Info.plist
values; XCUITest on the phone for the launch metric and the session's hitch metric (Release,
`Device.xctestplan`), and on the simulator for the screenshots (`Screenshots.xctestplan`); script
tests (bash and Python) for the icon, traceability, timing report, no-network and no-secrets
guards, the listing limits and the release guards; the release checklist for what only hands
can check

**Target Platform**: iOS 26.2+, iPhone only, portrait; measured on an iPhone 16 with iOS 27.0.1;
the iPad compatibility window checked on an iPad simulator

**Project Type**: mobile app (Xcode project) with the local engine package; release tooling

**Performance Goals**: cold launch to first frame under 400 ms (median of ten, Release, iPhone 16);
hitch-time ratio under 5 ms/s and total hitch time under 0.25 s in the scripted session; the
computer's first step 0.5–1 s after its turn starts in at least 95% of turns, never over 1.5 s;
each sound within 0.1 s of its step

**Constraints**: no change to game behavior, screens or texts (FR-031); no data leaves the phone;
Xcode 26.3 on the Mac and CI (FR-032; submission before Apple requires the iOS 27 SDK); secrets
never in the repository or a log; Markdown-only changes run no CI; `GameSession.swift` stays under
400 lines (394 now)

**Scale/Scope**: about 4 new and 6 changed app files (one a string catalog), 3 icon images; 4 new
and 2 changed test files; 1 new scheme, 2 new test plans; 7 new scripts and 7 script tests; 2 public
pages; 4 release record files and 6 screenshots; 6 user stories, 32 functional requirements

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|---|---|---|
| I. Native & Modern Apple Stack | Pass | MetricKit is the Apple framework IX.2 names; its subscriber must be an `NSObject` conforming to `MXMetricManagerSubscriber`, called on a system background queue: that class is the adapter I.3 allows for a system callback API, and it holds no Dispatch code. No UI changes. |
| II. Feature-Based Architecture | Pass | New `Features/Diagnostics/` folder; `DiagnosticReport` and `DiagnosticKind` are value types; the log is an injected protocol with live and recording conformances (exempt from II.5); `MXMetricManager.shared` is used only inside `DiagnosticsSubscriber.start()` (II.3), which `CheckersApp` calls, as it builds the other live services. |
| III. Test-First Quality | Pass | Diagnostics tests (fixtures for every kind, damaged payloads) and the Info.plist tests come before their code; each script's test before the script; acceptance tests per story: US1 `test-no-network.sh`, `traceability.py --check`, `PrivacyManifestTests`; US2 `LaunchPerformanceTests` and `DeviceSessionUITests` on the phone, with `test-device-timings.sh`; US3 `US3DiagnosticsTests`; US4 `PlatformSettingsTests` (name), `test-make-icon.sh`, `test-store-listing.sh`; US5 and US6 `test-release-guards.sh` (build order, submission gate). Measurements that need hands are release checklist items. |
| IV. Safety & Correctness | Pass | Typed `DiagnosticError`; every unreadable payload is logged and the next handled (IV.2); nothing user-visible can fail, so IV.3 adds nothing; no force unwraps; the subscriber is `Sendable` without `@unchecked`. |
| V. UX & Accessibility | Pass | No screen changes. The one new user-facing text, the Home Screen name, is in `InfoPlist.xcstrings` (V.4). The icon keeps the board's Classic colors; the launch screen stays the system background, as Home's. |
| VI. Privacy & Security | Pass | Diagnostics stay in the phone's log; MetricKit needs no permission and no required-reason API, so `PrivacyInfo.xcprivacy` is unchanged; the privacy report of each signed archive is generated (Organizer) and its facts checked by `release.sh check` (VI verification). The upload key is a developer credential kept outside the repository with owner-only permissions (spec assumption; VI.2 governs what the app stores, and it stores none). |
| VII. Performance | Pass | Measured on the phone before designing: launch median 231 ms, no hitches in a Rules scroll (R4, R5). Every target is measured on the phone (`device.sh`); a miss is profiled in Instruments before any change (VII.4, FR-014). Registering the subscriber adds one call at launch; the launch measurements cover it. |
| VIII. Simplicity & Dependencies | Pass | No dependencies; Python standard library and bash; no fastlane, no crash-reporting SDK, no Icon Composer file. Each script maps to a requirement. |
| IX. Observability | Pass | New `diagnostics` category (IX.1); diagnostics through MetricKit and Organizer (IX.2); kinds, times and timings are public, diagnostic details keep the default private redaction (IX.3). |
| Platform constraints | Pass | Toolchain: Xcode 26.3, the latest this Mac runs, on the Mac and CI (v1.2.0); iPhone only, portrait, iOS 26.2; every App Store build through TestFlight first (US5, FR-025). |
| Workflow gates | Pass | spec → clarify → plan → tasks → implement; no new views, so no new previews; small commits, each leaving the app building and tests passing. |

**Gate result (pre-research)**: PASS. No violations.

### Dependency justification (Principle VIII)

| Dependency | Why Apple frameworks fall short | Maintenance | License | Added via |
|---|---|---|---|---|
| *(none added)* | | | | |

The scripts run on the Mac (and the script tests on CI); nothing from them ships but the icon
images.

### Lint allow-list

| File | Rule | Reason |
|---|---|---|
| *(none)* | | The allow-list stays empty. |

### Audit allow-list

No change: the slice adds no screen. The three entries of E4 to E6 stand
(`specs/007-settings-themes-sound-and-rules/plan.md`).

### Other recorded decisions

- **Spec alignment** (R2): App Store Connect requires the iOS 26 SDK since 2026-04-28 and has
  announced no iOS 27 SDK date; the spec's Clarification, FR-032 and edge case now say "until
  Apple requires the iOS 27 SDK (expected around April 2027)" instead of a fixed date.
- **Device runs use `xcodebuild test`, never `test-without-building`** (R1): the latter cannot
  launch the app on iOS 27.0.1 with Xcode 26.3.
- **Instruments traces from the phone are read in the Instruments app** (R1): `xctrace export`
  crashes on them; numbers come from XCTest metrics and the app's log.
- **Build numbers are set at archive time** (R14), so uploads need no code commit; the repository
  records each build's commit in `release/builds.md`.
- **No new automated iPad tests** (spec clarification): one recorded smoke check per release build
  on the iPad simulator (R17).
- **Earlier tests that change**: `LoggingTests` (eight categories), `PlatformSettingsTests`
  (display name, encryption key, launch screen), and the blocking plan's skip list
  (`DeviceSessionUITests`, `ScreenshotUITests`). `LaunchPerformanceTests` is unchanged.
- **`GameSession.swift` is at 394 of 400 lines**: the computer's timing is a local clock reading in
  its turn function; if the line limit is still reached, the computer's turn moves to
  `GameSession+Computer.swift` first, as a refactor with its tests green.

### Post-design re-check

Re-evaluated after Phase 1 ([data-model.md](data-model.md),
[contracts/diagnostics.md](contracts/diagnostics.md),
[contracts/release-tooling.md](contracts/release-tooling.md),
[contracts/store-listing.md](contracts/store-listing.md), [quickstart.md](quickstart.md)): no
violations. The app gains one value-type parser, one protocol with two conformances and one
system adapter, all off the main actor, and three log lines; the release tooling is scripts with
tests and records in Markdown. **Gate result (post-design)**: PASS.

## Project Structure

### Documentation (this feature)

```text
specs/008-release-1-0/
├── plan.md                  # This file
├── research.md              # Phase 0 decisions R1–R17, with measurements on the phone
├── data-model.md            # Diagnostics types, measurement lines, release records
├── quickstart.md            # Validation scenarios, story by story
├── contracts/
│   ├── diagnostics.md       # Receiving, parsing and logging diagnostic reports
│   ├── release-tooling.md   # Schemes, plans, scripts, device logs, builds record
│   └── store-listing.md     # Listing fields and limits, screenshots, public pages
├── traceability.md          # Generated by scripts/traceability.py
├── checklists/
│   ├── requirements.md      # Spec quality checklist
│   ├── release.md           # The release checklist (gates submission)
│   └── validation.md        # Measurements and results (written during implementation)
└── tasks.md                 # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
checkers/checkers/
├── Features/Diagnostics/
│   ├── DiagnosticReport.swift            # new: DiagnosticKind, DiagnosticReport, DiagnosticError
│   ├── DiagnosticsLog.swift              # new: protocol, OSLogDiagnosticsLog, RecordingDiagnosticsLog
│   └── DiagnosticsSubscriber.swift       # new: MXMetricManagerSubscriber adapter
├── Features/Game/GameSession.swift       # the computer's first-step timing line
├── Features/Sound/SoundBank.swift        # sound start and output latency lines
├── Support/Logging.swift                 # + diagnostics category
├── CheckersApp.swift                     # starts the diagnostics subscriber
├── InfoPlist.xcstrings                   # new: CFBundleDisplayName "Checkers"
└── Assets.xcassets/AppIcon.appiconset/   # three images and file names (generated)
checkers/checkers.xcodeproj/
├── project.pbxproj                       # display name and encryption build settings
└── xcshareddata/xcschemes/
    ├── checkers.xcscheme                 # + Screenshots plan
    └── checkers-device.xcscheme          # new: app and UI tests only; Device plan
checkers/Device.xctestplan                # new: LaunchPerformanceTests, DeviceSessionUITests
checkers/Screenshots.xctestplan           # new: ScreenshotUITests
checkers/checkers.xctestplan              # skips the two new UI test classes
checkers/checkersTests/
├── US3DiagnosticsTests.swift             # new: every kind, order, damaged payloads, details
├── Support/DiagnosticFixtures.swift      # new: payload JSON per kind
├── PlatformSettingsTests.swift           # changed: name, encryption, launch screen
└── LoggingTests.swift                    # changed: eight categories
checkers/checkersUITests/
├── DeviceSessionUITests.swift            # new: the scripted session, XCTHitchMetric (phone only)
└── ScreenshotUITests.swift               # new: the six store screens (simulator)
scripts/
├── make-icon.py                          # new: the three icon images; --check
├── screenshots.sh                        # new: status bar, Screenshots plan, export
├── device.sh                             # new: status, launch, session on the phone
├── device-timings.py                     # new: SC-005 report from the console capture
├── traceability.py                       # new: the FRD matrix; --check
├── release.sh                            # new: archive, check, upload, record, submit-check
└── tests/
    ├── test-make-icon.sh                 # new
    ├── test-traceability.sh              # new
    ├── test-device-timings.sh            # new (+ fixture captures)
    ├── test-no-network.sh                # new
    ├── test-no-secrets.sh                # new
    ├── test-store-listing.sh             # new
    └── test-release-guards.sh            # new (+ fixture records)
release/
├── ExportOptions.plist                   # new: App Store Connect upload options
├── builds.md                             # new: build number → commit, date, state
├── store-listing.md                      # new: the listing's texts
└── screenshots/                          # new: 01-home.png … 06-statistics.png
docs/
├── index.md                              # new: support page
└── privacy.md                            # new: privacy policy
.gitignore                                # + *.p8
```

**Structure Decision**: Diagnostics get their own feature folder (Constitution II.1); the two
timing lines stay where the timed events happen. Release tooling lives in `scripts/` beside the
existing project scripts, its records in a new `release/` folder, and the public pages in
`docs/`, the folder GitHub Pages serves. Device-only and screenshot UI tests sit in the UI test
target but run only from their own plans.

## Complexity Tracking

No violations to justify.

## Follow-ups for other slices

- **Any update after Apple requires the iOS 27 SDK** needs an Apple silicon Mac and Xcode 27, a
  constitution check of the toolchain line, and a full retest (spec edge case).
- **If the phone's sound check misses 0.1 s**: move `SoundBank` to `AVAudioEngine` player nodes
  (E6 research R7), measured first.
- **After release**: read Organizer's crash and hang reports and TestFlight feedback; there is no
  other channel by design (FR-009).
