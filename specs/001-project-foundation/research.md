# Research: Project Foundation

Phase 0 output for `specs/001-project-foundation/plan.md`. Each entry records the decision, why,
and what else was considered. Facts marked *measured* were checked on the development Mac on
2026-10-16.

## Environment facts

| Item | Value |
|---|---|
| Development Mac | Intel x86_64, macOS 15.8.1, no Homebrew, no Mint (*measured*) |
| Xcode | 26.3 (17C529), Swift 6.2.4 (*measured*) |
| swift-format | 6.2.3, bundled with Xcode at `xcrun swift-format` (*measured*) |
| Local simulators | iOS 26.3.1 runtime; iPhone 17, 17 Pro, 17 Pro Max, Air, 16e (*measured*) |
| CI runner image | GitHub `macos-26` (arm64): Xcode 26.0.1–26.6 (default 26.6), iOS simulator runtimes 26.2, 26.4, 26.5, iPhone 17 on each; SwiftLint not installed |
| Current project | objectVersion 77 with file-system synchronized groups; `SWIFT_VERSION = 5.0`; `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; `SWIFT_APPROACHABLE_CONCURRENCY = YES`; `ENABLE_USER_SCRIPT_SANDBOXING = YES`; string catalogs preferred; no shared scheme (*measured*) |

## R1. Swift 6 migration effort

- **Decision**: Set `SWIFT_VERSION = 6.0` and `SWIFT_STRICT_CONCURRENCY = complete` on every
  target and keep the existing MainActor default isolation and approachable-concurrency settings.
- **Rationale**: A scratch build of the current code with `SWIFT_VERSION=6` and complete strict
  concurrency succeeded with zero compiler warnings (*measured*), so no code changes are needed
  for the language mode itself.
- **Alternatives considered**: Staying in Swift 5 mode with strict concurrency as warnings
  (rejected: Constitution IV requires Swift 6 mode).

## R2. Getting SwiftLint without Homebrew

- **Decision**: Add SwiftLint through the Swift Package Manager build tool plugin
  `SwiftLintBuildToolPlugin` from `SimplyDanny/SwiftLintPlugins`, pinned to 0.65.1, applied to
  the app target, both test targets and the `CheckersEngine` package targets. `Package.resolved`
  is committed. CI and command-line builds pass `-skipPackagePluginValidation`; Xcode asks once to
  trust the plugin.
- **Rationale**: SwiftLint is pre-approved (Constitution VIII.2). This package is the official
  binary distribution of SwiftLint's plugins, maintained by a SwiftLint maintainer, MIT licensed,
  last released 2026-08-21 alongside SwiftLint 0.65.1, and it downloads a checksum-verified
  universal binary, so it works on the Intel development Mac and the arm64 runner with no
  install step. The plugin runs on every build, which meets "lint on every local build" (FR-011)
  and makes lint errors build errors everywhere. The version is pinned by `Package.resolved`, so
  local and CI lint identically.
- **Alternatives considered**: Downloading `portable_swiftlint.zip` into `~/.local/bin` and on CI
  (rejected: two install paths to keep in sync, no version pin in the repo); building SwiftLint
  from source as a package dependency (rejected: slow builds); Mint or Homebrew (not available).

## R3. swift-format on every build

- **Decision**: Use the swift-format bundled with Xcode (`xcrun swift-format`). A Run Script build
  phase on the app target runs `swift-format lint` (non-strict) over the app, test and engine
  sources, so unformatted code shows as build warnings and no file changes. CI runs
  `swift-format lint --strict`, which fails on any finding. `scripts/format.sh` runs
  `swift-format format --in-place` on demand. One `.swift-format` file at the repository root
  configures both.
- **Rationale**: Matches clarification Q3 (warn locally, fail in CI, format on demand). No extra
  dependency, and the formatter version always matches the Xcode in use.
- **Consequence**: The Run Script phase must read source files, so the app target sets
  `ENABLE_USER_SCRIPT_SANDBOXING = NO`. The script only reads sources and writes nothing; this is
  recorded in the plan. Declaring every source file as a script input was rejected because the
  synchronized groups add files automatically and an input list would drift.
- **Alternatives considered**: swift-format's package plugins (rejected: they are command plugins,
  not build tool plugins, so they cannot run on every build); auto-formatting on build (rejected
  in clarification Q3).

## R4. SwiftLint and swift-format division of labour

- **Decision**: swift-format owns layout (indentation 4 spaces, line length 100, spacing,
  trailing commas). SwiftLint owns safety and stack rules. SwiftLint layout rules that overlap
  swift-format are disabled so the two tools never disagree.
- **Rationale**: Two tools enforcing the same style differently would make code impossible to
  satisfy. Keeping SwiftLint's default safety rules plus the constitution's opt-in rules keeps
  lint signal meaningful.
- **Details**: see `contracts/lint-rules.md` for the exact rule set, severities, custom rules and
  the allow-list policy.

## R5. Lint severities in CI

- **Decision**: The constitution's banned constructs are configured at `error` severity, so they
  fail the build locally and in CI. Other SwiftLint findings stay at `warning` and are reported in
  the CI log without failing it (clarification Q5). `SWIFT_TREAT_WARNINGS_AS_ERRORS` is a
  compiler setting and does not turn SwiftLint warnings into errors.
- **Alternatives considered**: `swiftlint --strict` in CI (rejected by Q5).

## R6. Zero compiler warnings

- **Decision**: CI passes `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES GCC_TREAT_WARNINGS_AS_ERRORS=YES` on
  the `xcodebuild` command line, which applies to the app, test and package targets. Local builds
  keep warnings as warnings so experiments are not blocked, while CI keeps `main` at zero.
- **Alternatives considered**: Setting the flags in the project for every configuration (rejected:
  a stray warning would block local experiments and previews, while CI already guarantees zero
  warnings on `main`). These flags affect compiler warnings only, not the format warnings of R3.

## R7. String catalog warnings and drift

- **Decision**: Add `checkers/checkers/Localizable.xcstrings` and move the existing user-facing
  strings (the four screen titles and the picker label) into it. CI detects a stale or incomplete
  catalog by copying it, running `xcrun xcstringstool sync` with the build's `.stringsdata` files,
  and failing if the copy differs from the committed file (`scripts/check-string-catalog.sh`).
- **Rationale**: A command-line `xcodebuild` does not write extracted strings back to the catalog
  (*measured*: a build left an empty catalog unchanged), so a missing key never shows up as a CI
  failure on its own. `xcstringstool sync` is the tool Xcode uses to update catalogs; on a copy
  named `Localizable.xcstrings` it added the missing `Screen` key (*measured*). Any difference
  means a key is missing or stale. The Xcode IDE keeps the catalog in sync during normal
  development, so the check only fails when someone forgets to commit the update.
- **Alternatives considered**: Grepping build logs for catalog warnings (rejected: xcodebuild
  emits none for missing keys); hand-written key extraction (rejected: duplicates Apple's tool).

## R8. Test targets, test plans and Main Thread Checker

- **Decision**: Add `checkersTests` (Swift Testing unit tests) and `checkersUITests` (XCUITest)
  as file-system synchronized targets in the existing project, and a shared `checkers` scheme
  with two test plans: `checkers.xctestplan` (unit, UI and `CheckersEngineTests`; used by CI as
  the blocking run) and `Performance.xctestplan` (the launch test only). Main Thread Checker
  stays enabled, which is the test plan default.
- **Rationale**: Test plans let one scheme run the blocking suites and the report-only launch test
  separately (clarification Q2) without duplicate schemes. Synchronized groups mean new test files
  need no project edits, matching how the app target already works.
- **Alternatives considered**: XcodeGen or Tuist to generate the project (rejected: new
  third-party tooling for three targets); separate schemes per suite (rejected: more files and
  more CI invocations).

## R9. Engine module layout

- **Decision**: A local Swift package at `checkers/CheckersEngine/` (next to the Xcode project)
  with `swift-tools-version: 6.2`, library product `CheckersEngine`, target `CheckersEngine` and
  test target `CheckersEngineTests`. Platforms: iOS 26.2 (the app's minimum) and macOS 15 so the
  package tests run on the development Mac with `swift test`. The app target links the product.
  The first public symbol is `Side` (`light`, `dark`, with `opponent`), a type epic E2 needs.
- **Rationale**: Tools version 6.2 gives Swift 6 language mode by default. Package code is
  nonisolated by default, which suits game logic that must run off the main actor (Constitution
  VII.3). `Side` comes straight from the FRD glossary, so it is not speculative (VIII.3).
- **Alternatives considered**: A framework target inside the Xcode project (rejected:
  Constitution II prefers local packages for logic tested independently of the app); a
  placeholder symbol such as a version string (rejected: dead code E2 would delete).
- **Guard**: A SwiftLint custom rule fails on `import SwiftUI`, `UIKit`, `WebKit` or `Combine`
  under `CheckersEngine/Sources/` (US4 scenario 3).

## R10. CI workflow and the docs-only rule

- **Decision**: One GitHub Actions workflow, `.github/workflows/ci.yml`, triggered on `push` to any
  branch and on manual dispatch, with three jobs:
  1. `changes` (Ubuntu): diffs the pushed range (`github.event.before`..`github.sha`, or the merge
     base with `origin/main` for a new branch) and sets `code=true` unless every changed file ends
     in `.md`.
  2. `build-and-test` (`macos-26`, Xcode 26.3 pinned through `DEVELOPER_DIR`, iPhone 17 on iOS
     26.2): runs only when `code=true`; checks formatting, builds and runs the blocking test plan
     with warnings as errors, checks the string catalog, then runs the launch test as a
     non-blocking step and publishes its duration in the job summary.
  3. `CI gate` (Ubuntu, `if: always()`): the only required check. It passes when `changes`
     succeeded and `build-and-test` either succeeded or was skipped because the push was
     docs-only; otherwise it fails.
- **Rationale**: A workflow-level path filter would leave the required check pending on docs-only
  pushes and block them; a gate job that always reports avoids that (FR-006). GitHub treats
  success, skipped and neutral as passing for required checks, but an explicit gate makes the
  rule visible and avoids depending on skip semantics. Only first-party actions are used
  (`actions/checkout`, `actions/upload-artifact`). Pinning Xcode 26.3 matches the development Mac
  so CI does not surface warnings the developer cannot reproduce; both are upgraded together.
- **Alternatives considered**: `paths-ignore` at workflow level (rejected: blocks docs-only pushes
  on `main`); third-party path-filter actions (rejected: unnecessary dependency); running on pull
  requests (not used in this repo).

## R11. Protecting `main` without pull requests

- **Decision**: Classic branch protection on `main` with required status check `CI gate`
  (non-strict), "include administrators" (no bypass), no required pull request reviews, no push
  restrictions, force pushes and deletion disabled. It is applied with
  `gh api -X PUT repos/iglooo101/checkers/branches/main/protection` after the first green CI run.
- **Rationale**: GitHub documents that once required checks pass, commits may be pushed directly
  to the protected branch, and that pull requests are only required when reviews are enabled.
  Enabling the rule for administrators removes the owner bypass (clarification Q1). A
  fast-forward keeps commit SHAs, so a commit that passed on its branch is accepted on `main`
  (FR-009).
- **Bootstrap order**: the CI workflow lands and goes green first; protection is switched on last,
  so it never blocks its own introduction (spec edge case).
- **Alternatives considered**: Repository rulesets (equivalent here; classic protection is simpler
  to script and inspect).

## R12. Launch-time baseline

- **Decision**: `LaunchPerformanceTests` in `checkersUITests` measures cold launch with
  `XCTApplicationLaunchMetric`. The baseline for the development Mac's iPhone 17 simulator is
  stored in the shared project data so later local runs compare against it. CI runs the
  Performance test plan with `continue-on-error`, extracts the measured duration from the result
  bundle, and writes it with the recorded baseline to the job summary (clarification Q2).
- **Rationale**: Xcode baselines are per machine and device, so a CI runner has no baseline of its
  own; reporting the number beside the recorded one gives the regression signal without random
  failures. The hard 400 ms check on hardware is #181 in epic E8.
- **Alternatives considered**: A blocking launch test (rejected in Q2).

## R13. Privacy manifest contents

- **Decision**: `checkers/checkers/PrivacyInfo.xcprivacy` declares `NSPrivacyTracking = false`,
  empty `NSPrivacyTrackingDomains`, empty `NSPrivacyCollectedDataTypes`, and empty
  `NSPrivacyAccessedAPITypes`. The user-defaults required-reason API (reason `CA92.1`) is declared
  in the change that first uses `UserDefaults` or `@AppStorage`, which is #71 (remembering setup
  choices) or #140 (settings store), whichever lands first.
- **Rationale**: Constitution VI.3 requires the manifest to be accurate and to be updated in the
  same change that starts using a required-reason API. The app does not use `UserDefaults` today,
  so declaring it now would be inaccurate. This corrects the original FR-014 wording, which asked
  for the declaration up front; the spec was amended accordingly.
- **Alternatives considered**: Declaring `CA92.1` now as the spec first said (rejected: conflicts
  with the constitution, which prevails).

## R14. Logging

- **Decision**: `checkers/checkers/Support/Logging.swift` extends `Logger` with one static logger
  per feature category, starting with `app`, using `Bundle.main.bundleIdentifier` as the
  subsystem. The existing silent `return` in `WebView` when a screen resource is missing becomes
  a logged error.
- **Rationale**: `Logger` is a stateless value, so static instances are not the stateful
  singletons Constitution II.3 forbids. Logging the missing resource gives the logger a real first
  use.

## R15. Observability gap found during planning

- **Finding**: Constitution IX.2 requires crashes and key errors to be reportable through MetricKit
  diagnostics and Xcode Organizer. No backlog task covers a MetricKit subscriber.
- **Decision**: Out of scope for this slice (the spec does not include it). Raise it in #7
  (reconcile the board) as a new task, proposed for E8 Release.
