# Implementation Plan: Project Foundation

**Branch**: `001-project-foundation` | **Date**: 2026-10-16 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-project-foundation/spec.md`

## Summary

Bring the existing checkers app into compliance with constitution v1.1.0 before any feature work:
Swift Testing unit tests and XCUITest UI tests, a UI-free `CheckersEngine` package, Swift 6 with
complete strict concurrency, SwiftLint (via its official package plugin, since the Mac has no
Homebrew) and the swift-format bundled with Xcode, a privacy manifest, a shared logger, a string
catalog, iPhone-only portrait settings, a launch-time baseline, and a GitHub Actions workflow whose
always-reporting `CI gate` check protects `main` without pull requests. The existing web-view
screens keep working unchanged. Research: [research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.2 (Xcode 26.3), Swift 6 language mode, complete strict concurrency

**Primary Dependencies**: SwiftUI, WebKit (existing); OSLog; SwiftLintPlugins 0.65.1 (build-time
only); swift-format 6.2 (bundled with Xcode)

**Storage**: N/A (no persistence in this slice)

**Testing**: Swift Testing (unit and engine tests), XCUITest (UI and launch performance tests),
two Xcode test plans

**Target Platform**: iOS 26.2+, iPhone only, portrait; engine package also builds for macOS 15 for
host tests

**Project Type**: mobile app (Xcode project) plus one local Swift package

**Performance Goals**: cold launch to first frame under 400 ms on a recent iPhone (baseline only
here; hardware check in #181); full CI run under 20 minutes; docs-only check under 2 minutes

**Constraints**: no visible UI change; no network, accounts, analytics or permissions; no Homebrew
on the development Mac; Intel development Mac and arm64 CI runner; solo repo with no pull
requests

**Scale/Scope**: 3 app-side targets, 1 package with 2 targets, 1 workflow, about 20 configuration
and source files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|---|---|---|
| I. Native & Modern Apple Stack | Pass with justified exception | No new UI. The existing web-view screens are pre-existing non-SwiftUI UI, justified below and removed in #67 (E3). No `ObservableObject`, Combine or `DispatchQueue` added; lint now bans them. Swift Testing and OSLog are first-party. |
| II. Feature-Based Architecture | Pass | Game logic gets its own package (`CheckersEngine`). New `Logger` statics are stateless values, not stateful singletons. No shared abstraction layers added. |
| III. Test-First Quality | Pass | Test targets and plans are the first deliverable; every story has an acceptance check (`quickstart.md`); CI blocks on failing tests, compiler warnings and lint errors. Tasks will order tests first (tasks template override, #26). |
| IV. Safety & Correctness | Pass | Swift 6 mode with complete strict concurrency; force-unwrap family at error severity; CI treats compiler warnings as errors. No `@unchecked Sendable` or `nonisolated(unsafe)`. |
| V. UX & Accessibility | Pass | Existing user-facing strings move to a String Catalog and drift fails CI. No new screens, so Dynamic Type, Dark Mode and audit work belongs to E3 and E7. `ContentView` keeps its `#Preview`. |
| VI. Privacy & Security | Pass | Accurate privacy manifest (no tracking, no collected data, no required-reason APIs until one is used). No network code; the web view loads bundled files only; no ATS exceptions. |
| VII. Performance | Pass | Launch baseline recorded; nothing heavy on the main thread; the engine package is nonisolated by default. |
| VIII. Simplicity & Dependencies | Pass | One dependency, SwiftLintPlugins, justified below; SwiftLint is pre-approved. swift-format comes with Xcode. CI uses only first-party GitHub actions. Nothing beyond the spec is added. |
| IX. Observability | Pass, with a gap raised | Shared `Logger` with bundle-ID subsystem and per-feature categories; `print`, `debugPrint` and `NSLog` banned by lint. MetricKit diagnostics (IX.2) are outside this spec and have no backlog task; raised for #7 (R15). |
| Workflow gates | Pass | spec → plan → tasks → implement; `main` protected by a green `CI gate`. |

**Gate result (pre-research)**: PASS. The only violation is pre-existing (Complexity Tracking).

### Dependency justification (Principle VIII)

| Dependency | Why Apple frameworks fall short | Maintenance | License | Added via |
|---|---|---|---|---|
| SwiftLintPlugins 0.65.1 (`SimplyDanny/SwiftLintPlugins`) | Xcode has no lint tool for the constitution's rules. This package is the official binary distribution of SwiftLint's build tool plugin, so the pre-approved SwiftLint runs on every build without Homebrew. | Released 2026-08-21 with SwiftLint 0.65.1; maintained by a SwiftLint maintainer | MIT | Swift Package Manager, `Package.resolved` committed |

### Lint allow-list

| File | Rule | Reason |
|---|---|---|
| *(none)* | | The allow-list starts empty. |

### Other recorded decisions

- `ENABLE_USER_SCRIPT_SANDBOXING = NO` on the app target, so the format-check Run Script phase can
  read source files (R3). The script only reads sources and writes nothing.
- CI pins Xcode 26.3 to match the development Mac; both are upgraded together (R10).

### Post-design re-check

Re-evaluated after Phase 1 (contracts, data model, quickstart): no new violations. Two points
changed the spec to fit the constitution: FR-014 now declares only the required-reason APIs in
use (VI.3; R13), and FR-012 also bans `@Published`, `OperationQueue` and `Thread` (I.2, I.3).
**Gate result (post-design)**: PASS.

## Project Structure

### Documentation (this feature)

```text
specs/001-project-foundation/
├── plan.md              # This file
├── research.md          # Phase 0 decisions R1–R15
├── data-model.md        # Configuration artifacts and their checks
├── quickstart.md        # Validation scenarios per user story
├── contracts/
│   ├── ci-gate.md       # CI triggers, required check, outcomes, budgets
│   └── lint-rules.md    # Lint and format rules, severities, allow-list policy
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
.github/
└── workflows/
    └── ci.yml                         # jobs: changes, build-and-test, CI gate
.swift-format                          # shared layout rules
scripts/
├── test.sh                            # one-command local test run (same steps as CI)
├── format.sh                          # format on demand
├── check-format.sh                    # swift-format lint; --strict in CI
└── check-string-catalog.sh            # catalog drift check
checkers/
├── .swiftlint.yml                     # rules for the Xcode targets
├── checkers.xcodeproj/
│   ├── project.pbxproj                # + test targets, package reference, Swift 6, iPhone only
│   └── xcshareddata/
│       └── xcschemes/checkers.xcscheme
├── checkers.xctestplan                # blocking: unit, UI, engine tests
├── Performance.xctestplan             # report-only: launch test
├── checkers/                          # app target (synchronized group)
│   ├── CheckersApp.swift
│   ├── ContentView.swift              # titles become localized resources
│   ├── Support/Logging.swift          # Logger categories
│   ├── PrivacyInfo.xcprivacy
│   ├── Localizable.xcstrings
│   └── Assets.xcassets/               # stray CheckersApp.swift removed
├── checkersTests/                     # Swift Testing unit tests (+ nested .swiftlint.yml)
├── checkersUITests/                   # XCUITest smoke + LaunchPerformanceTests (+ nested .swiftlint.yml)
└── CheckersEngine/
    ├── Package.swift
    ├── .swiftlint.yml                 # inherits checkers/.swiftlint.yml, adds engine_no_ui_imports
    ├── Sources/CheckersEngine/Side.swift
    └── Tests/CheckersEngineTests/SideTests.swift
```

`checkers/checkers/Item.swift` is deleted.

**Structure Decision**: Keep the single Xcode project in `checkers/` and add the engine as a local
package beside it, so the app and package share one workspace and test plan. Existing app files
stay where they are; epic E3 reorganizes the app by feature when it replaces the web-view UI.
Scripts live at the repository root so local runs and CI call the same commands.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Existing UI is bundled HTML in a `WKWebView` (Principle I.1) | Pre-existing prototype; this slice must not change visible UI (FR-021), and E3 replaces it with SwiftUI (#67) | Rewriting the UI now would mix epic E3 into the foundation slice and leave nothing playable meanwhile |

## Follow-ups for other slices

- **#71 or #140**: whichever first uses `UserDefaults` or `@AppStorage` adds the user-defaults
  required-reason API (`CA92.1`) to `PrivacyInfo.xcprivacy` in the same change (R13).
- **#7 (reconcile)**: add a backlog task for MetricKit diagnostics (Constitution IX.2), proposed
  for E8 (R15).
