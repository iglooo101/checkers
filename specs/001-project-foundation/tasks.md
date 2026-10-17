---

description: "Task list for the project foundation slice (epic E1)"
---

# Tasks: Project Foundation

**Input**: Design documents from `/specs/001-project-foundation/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ (ci-gate.md, lint-rules.md), quickstart.md

**Tests**: Tests are MANDATORY (Constitution III). Every user story has at least one automated acceptance test that names its story ID (`US1`…`US6`) in its display name or test name. Test tasks come before the implementation tasks they cover and must be observed failing (or failing to compile) before implementation begins. Unit and engine tests use Swift Testing; XCUITest is used only for UI flows and the launch metric. CI behavior is tested with shell scripts under `scripts/tests/`.

**Organization**: Tasks are grouped by user story so each story can be implemented and verified on its own. Every completed task leaves the app building and all tests passing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US6)
- Paths are relative to the repository root. The Xcode project is `checkers/checkers.xcodeproj`; the app target's files are in `checkers/checkers/` (file-system synchronized group, so new files there need no project edit).

## Conventions used by every task

- Simulator destination: `platform=iOS Simulator,name=iPhone 17` (iOS 26.3 locally, `OS=26.2` in CI).
- Every `xcodebuild` call passes `-skipPackagePluginValidation` (SwiftLint plugin) and uses the shared settings in `scripts/lib.sh`.
- Project file edits (`project.pbxproj`) are verified with `xcodebuild -list -project checkers/checkers.xcodeproj` and a build before the task is done.
- Commits go on branch `001-project-foundation`; no AI attribution anywhere.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Record the starting behavior and create the shared scheme and script settings.

- [X] T001 Smoke-check the current app before any change: run it on the iPhone 17 simulator, confirm the Classic, Modern, Playful and Play screens load and Play accepts a move, and note the result in the T061 checklist (FR-021 reference).
- [X] T002 Create the shared scheme `checkers/checkers.xcodeproj/xcshareddata/xcschemes/checkers.xcscheme` for the `checkers` app target (build, run, test, profile, analyze, archive actions), so CI and scripts can use it.
- [X] T003 [P] Create `scripts/lib.sh` with the shared settings sourced by every script: project path, scheme `checkers`, destination (overridable by `DESTINATION`), `-skipPackagePluginValidation`, derived data path `.build/DerivedData` (overridable by `DERIVED_DATA`), and `set -euo pipefail`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Test targets, the blocking test plan and the one-command test runner that every story's tests need.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 Add unit test target `checkersTests` to `checkers/checkers.xcodeproj/project.pbxproj`: Swift Testing, host application `checkers`, file-system synchronized group `checkers/checkersTests/`, `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, deployment target 26.2, `TARGETED_DEVICE_FAMILY = 1`. Add one placeholder test file `checkers/checkersTests/PlaceholderTests.swift` so the target compiles (removed in T010).
- [X] T005 Add UI test target `checkersUITests` to `checkers/checkers.xcodeproj/project.pbxproj`: XCUITest, target application `checkers`, synchronized group `checkers/checkersUITests/`, same Swift settings as T004 except default actor isolation, which stays nonisolated because `XCTestCase` initializers are nonisolated; UI test methods are marked `@MainActor`. Add a placeholder `checkers/checkersUITests/PlaceholderUITests.swift` (removed in T011).
- [X] T006 Create the blocking test plan `checkers/checkers.xctestplan` containing `checkersTests` and `checkersUITests`, with Main Thread Checker enabled, and make it the default test plan of `checkers.xcscheme`.
- [X] T007 Create `scripts/test.sh`: sources `scripts/lib.sh`, runs `xcodebuild test -testPlan checkers` on the destination, passes extra build settings from `$@` (CI adds warnings-as-errors), writes the result bundle to `.build/TestResults/checkers.xcresult`, and exits non-zero on any failure. Add `.build/` handling: confirm it is already in `.gitignore`.

**Checkpoint**: `scripts/test.sh` runs both placeholder tests and passes.

---

## Phase 3: User Story 1 - Run automated tests locally (Priority: P1) 🎯 MVP

**Goal**: One command runs real unit and UI tests and reports pass or fail by test name (#9; FR-001 to FR-003).

**Independent Test**: `scripts/test.sh` passes on a clean checkout; a deliberately failing expectation makes it fail and names the test (quickstart §1).

### Tests for User Story 1 (MANDATORY - write first) ⚠️

- [X] T008 [P] [US1] Write `checkers/checkersTests/ScreenCatalogTests.swift` with `@Test("US1: every screen has a bundled HTML file")` iterating `Screen.all` and expecting `Bundle.main.url(forResource: screen.file, withExtension: "html") != nil`, and `@Test("US1: the four screens are listed in order")` expecting files `["Classic", "Modern", "Playful", "Play"]`. It fails to compile until T010.
- [X] T009 [P] [US1] Write `checkers/checkersUITests/AppSmokeUITests.swift` with `testUS1_launchShowsFourScreens`: launch the app and assert the segmented control exposes buttons Classic, Modern, Playful and Play (also guards FR-021).

### Implementation for User Story 1

- [X] T010 [US1] In `checkers/checkers/ContentView.swift`, replace the private tuple list with an internal `struct Screen: Identifiable` (`title`, `file`) and `static let all` holding the four screens in order; `ContentView` iterates `Screen.all`. No visible change. Delete `checkers/checkersTests/PlaceholderTests.swift`. T008 passes.
- [X] T011 [US1] Delete `checkers/checkersUITests/PlaceholderUITests.swift`; run `scripts/test.sh` and confirm T008 and T009 pass.
- [X] T012 [US1] Verify failure reporting (quickstart §1): add `#expect(Bool(false))` to `ScreenCatalogTests`, confirm `scripts/test.sh` fails and names the test, then revert. Confirm Main Thread Checker is enabled in `checkers/checkers.xctestplan`.

**Checkpoint**: US1 complete; local tests are trustworthy.

---

## Phase 4: User Story 2 - CI guards `main` (Priority: P1)

**Goal**: Every code push is built and tested; docs-only pushes pass without building; `main` accepts only checked commits, with no pull requests and no owner bypass (#10, #11, #12; FR-005 to FR-009; `contracts/ci-gate.md`).

**Independent Test**: probe pushes from quickstart §5 behave as the contract table says.

### Tests for User Story 2 (MANDATORY - write first) ⚠️

- [X] T013 [P] [US2] Write `scripts/tests/test-classify-changes.sh` named "US2: classify pushes": feeds file lists to `scripts/ci/classify-changes.sh` on stdin and expects `docs` for `FRD.md`, `specs/001-project-foundation/plan.md` and an empty list; `code` for any `.swift` file, `checkers/checkers.xcodeproj/project.pbxproj`, `.gitignore`, `.github/workflows/ci.yml`, `scripts/test.sh`, and a mix of `.md` and `.swift`.
- [X] T014 [P] [US2] Write `scripts/tests/test-ci-gate.sh` named "US2: CI gate decisions": calls `scripts/ci/gate.sh <changes-result> <code-flag> <build-result>` for every row of the outcomes table in `contracts/ci-gate.md` (`success docs skipped` → pass; `success code success` → pass; `success code failure` → fail; `success code cancelled` → fail; `failure * *` → fail) and checks the exit status.
- [X] T015 [P] [US2] Write `scripts/tests/run.sh`: runs every `scripts/tests/test-*.sh`, prints each name with PASS/FAIL, and exits non-zero if any fail. Run it and observe T013 and T014 fail.

### Implementation for User Story 2

- [X] T016 [US2] Implement `scripts/ci/classify-changes.sh`: reads changed paths from stdin, prints `docs` when every non-empty line ends in `.md` (or there are none), else `code`. T013 passes.
- [X] T017 [US2] Implement `scripts/ci/gate.sh` per the outcomes table: exit 0 only for `success docs skipped` or `success code success`; print the reason otherwise. T014 passes.
- [X] T018 [US2] Create `.github/workflows/ci.yml` per `contracts/ci-gate.md`: trigger `push` on all branches except `main` (`branches-ignore: [main]`) and `workflow_dispatch`; job `changes` on `ubuntu-latest` (checkout with `fetch-depth: 0`; range `github.event.before..github.sha`, or `$(git merge-base origin/main HEAD)..HEAD` when `before` is all zeros; output `code=true|false` from `classify-changes.sh`); job `build-and-test` on `macos-26`, `needs: changes`, `if: needs.changes.outputs.code == 'true'`, `DEVELOPER_DIR=/Applications/Xcode_26.3.app/Contents/Developer`, `DESTINATION='platform=iOS Simulator,name=iPhone 17,OS=26.2'`, steps: checkout, `scripts/tests/run.sh`, `scripts/test.sh SWIFT_TREAT_WARNINGS_AS_ERRORS=YES GCC_TREAT_WARNINGS_AS_ERRORS=YES`, upload `.build/TestResults` with `actions/upload-artifact` (`if: always()`); job named `CI gate` on `ubuntu-latest`, `needs: [changes, build-and-test]`, `if: always()`, running `scripts/ci/gate.sh` with the two jobs' results. Use only first-party actions.
- [ ] T019 [US2] Push the branch and confirm `CI gate` is green with build and tests run. Then push a commit that changes only a `.md` file and confirm `CI gate` passes within 2 minutes with `build-and-test` skipped (SC-002).
- [X] T020 [US2] Probe: push a commit with a failing unit test, confirm `CI gate` fails and the log names the test, then revert and confirm green (SC-001, part 1).
- [ ] T021 [US2] Create `scripts/protect-main.sh` that applies branch protection with `gh api -X PUT repos/iglooo101/checkers/branches/main/protection`: required status checks `strict: false`, `contexts: ["CI gate"]`; `enforce_admins: true`; `required_pull_request_reviews: null`; `restrictions: null`; `allow_force_pushes: false`; `allow_deletions: false`. Run it once `main` holds a green `CI gate` commit.
- [ ] T022 [US2] Verify protection (quickstart §5, SC-003, SC-004): a push to `main` of a commit without a passing check is rejected for the owner; fast-forwarding `main` to a branch commit with a green `CI gate` and pushing is accepted with no pull request.

**Checkpoint**: US2 complete; `main` is gated.

---

## Phase 5: User Story 3 - The compiler and linter enforce safety rules (Priority: P2)

**Goal**: Swift 6 with complete strict concurrency and zero warnings; SwiftLint errors for the constitution's banned constructs; shared formatting that warns locally and fails CI (#14, #16, #17; FR-010 to FR-013; `contracts/lint-rules.md`).

**Independent Test**: the lint and format script tests pass, and the probe table in quickstart §3 and §4 behaves as expected.

### Tests for User Story 3 (MANDATORY - write first) ⚠️

- [X] T023 [P] [US3] Create lint fixtures in `scripts/tests/lint-fixtures/app/`, one file per error rule in `contracts/lint-rules.md`: `ForceUnwrap.swift`, `ForceCast.swift`, `ForceTry.swift`, `ImplicitlyUnwrapped.swift`, `ObservableObject.swift`, `Published.swift`, `CombineImport.swift`, `DispatchQueue.swift`, `OperationQueue.swift`, `Thread.swift`, `Print.swift`, plus `Clean.swift` with none of them; and `scripts/tests/lint-fixtures/test-code/PrintAndForceUnwrap.swift` using `print(` and `!`. Fixtures sit outside every target and every default format path, so they are only linted by the script test.
- [X] T024 [P] [US3] Write `scripts/tests/test-lint-rules.sh` named "US3: lint rules": locates the SwiftLint binary with `swiftlint_bin` from `scripts/lib.sh`, lints each `app/` fixture with `--config checkers/.swiftlint.yml --reporter json`, and expects the matching rule id (`force_unwrapping`, `force_cast`, `force_try`, `implicitly_unwrapped_optional`, `no_observable_object`, `no_combine`, `no_legacy_concurrency`, `no_print`) at `error` severity; expects zero errors for `Clean.swift`; lints `test-code/` with the app config plus `checkers/checkersTests/.swiftlint.yml` and expects no errors.
- [X] T025 [P] [US3] Write `scripts/tests/test-format-check.sh` named "US3: format check": copies a badly indented fixture and a well-formatted fixture into a temp dir, expects `scripts/check-format.sh --strict <dir>` to fail on the first and pass on the second, and expects the non-strict run to exit 0 while printing a warning for the first.

### Implementation for User Story 3

- [X] T026 [US3] Switch the app target to Swift 6 in `checkers/checkers.xcodeproj/project.pbxproj`: `SWIFT_VERSION = 6.0` and `SWIFT_STRICT_CONCURRENCY = complete` in both configurations; keep `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`. Build: zero compiler warnings (FR-010).
- [X] T027 [US3] Add the remote package `https://github.com/SimplyDanny/SwiftLintPlugins` pinned to exact version 0.65.1 to `checkers/checkers.xcodeproj/project.pbxproj`, and add the `SwiftLintBuildToolPlugin` to the `checkers`, `checkersTests` and `checkersUITests` targets. Commit `checkers/checkers.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
- [X] T028 [US3] Create `checkers/.swiftlint.yml` exactly per `contracts/lint-rules.md`: disable the listed layout rules; opt in `force_unwrapping` and `implicitly_unwrapped_optional`; set `force_unwrapping`, `force_cast`, `force_try`, `implicitly_unwrapped_optional` to `error`; define custom rules `no_observable_object` (`\bObservableObject\b|@Published\b`), `no_combine` (`^\s*import\s+Combine\b`), `no_legacy_concurrency` (`\b(DispatchQueue|OperationQueue|Thread)\b`), `no_print` (`\b(print|debugPrint|NSLog)\s*\(`), `engine_no_ui_imports` (`^\s*import\s+(SwiftUI|UIKit|WebKit|Combine)\b`, `included: ".*CheckersEngine/Sources/.*"`), all `severity: error`. Create `checkers/checkersTests/.swiftlint.yml` and `checkers/checkersUITests/.swiftlint.yml` that disable the force-unwrap family and `no_print`.
- [X] T029 [US3] Implement `swiftlint_bin` in `scripts/lib.sh`: resolve packages with `xcodebuild -resolvePackageDependencies -clonedSourcePackagesDirPath .build/spm` if needed and print the path of the `swiftlint` executable inside the SwiftLintBinary artifact bundle. T024 passes.
- [X] T030 [P] [US3] Create `.swift-format` at the repository root: version 1, 4-space indentation, `lineLength` 100, `respectsExistingLineBreaks` true, default rules.
- [X] T031 [US3] Implement `scripts/check-format.sh` (`swift-format lint`, `--strict` passed through, default paths `checkers/checkers checkers/checkersTests checkers/checkersUITests checkers/CheckersEngine/Sources checkers/CheckersEngine/Tests` skipping missing ones, or paths given as arguments) and `scripts/format.sh` (`swift-format format --in-place --recursive` over the same paths). T025 passes.
- [X] T032 [US3] Run `scripts/format.sh` on the existing sources, then `scripts/test.sh`: all tests pass and the app behaves as before.
- [X] T033 [US3] Add a Run Script build phase "Check formatting" to the `checkers` target in `checkers/checkers.xcodeproj/project.pbxproj` running `"$SRCROOT/../scripts/check-format.sh"` (non-strict) with "Based on dependency analysis" turned off (`alwaysOutOfDate = 1`, so Xcode does not warn that it runs on every build), and set `ENABLE_USER_SCRIPT_SANDBOXING = NO` on that target (plan: Other recorded decisions). An unformatted line now shows as a build warning and no file changes (quickstart §4).
- [X] T034 [US3] Add `scripts/check-format.sh --strict` as a step before the build in `.github/workflows/ci.yml`.
- [X] T035 [US3] CI probes (SC-001, parts 2–4): push a commit with a compiler warning, one with a force unwrap, and one with an unformatted line; confirm each fails `CI gate` with the cause named; revert each and confirm green. Confirm a lint warning (non-error rule) is reported but does not fail.

**Checkpoint**: US3 complete; safety rules are enforced everywhere.

---

## Phase 6: User Story 4 - An engine module is ready for the rules engine (Priority: P2)

**Goal**: A UI-free `CheckersEngine` package with its own tests, linked by the app (#25; FR-004).

**Independent Test**: `swift test` in `checkers/CheckersEngine` passes; the app links the module; a UI import under `CheckersEngine/Sources/` fails lint (quickstart §2).

### Tests for User Story 4 (MANDATORY - write first) ⚠️

- [X] T036 [P] [US4] Create `checkers/CheckersEngine/Package.swift` (`swift-tools-version: 6.2`; platforms `.iOS("26.2")`, `.macOS(.v15)`; library product `CheckersEngine`; targets `CheckersEngine` and test target `CheckersEngineTests`; dependency SwiftLintPlugins exact 0.65.1 with `SwiftLintBuildToolPlugin` on both targets) and `checkers/CheckersEngine/Tests/CheckersEngineTests/SideTests.swift` with `@Test("US4: each side's opponent is the other side")` (`Side.light.opponent == .dark`, `Side.dark.opponent == .light`). `swift test` fails until T039.
- [X] T037 [P] [US4] Write `checkers/checkersTests/EngineLinkTests.swift` with `@Test("US4: the app links CheckersEngine")` that imports `CheckersEngine` and expects `Side.allCases.count == 2`. It fails to compile until T040.
- [X] T038 [P] [US4] Add fixture `scripts/tests/lint-fixtures/CheckersEngine/Sources/UIImport.swift` (`import SwiftUI`) and a case in `scripts/tests/test-lint-rules.sh` expecting `engine_no_ui_imports` at error; observe it fail until T041.

### Implementation for User Story 4

- [X] T039 [US4] Implement `checkers/CheckersEngine/Sources/CheckersEngine/Side.swift`: `public enum Side: Sendable, CaseIterable { case light, dark }` with `public var opponent: Side`. `swift test` passes (T036). Commit `checkers/CheckersEngine/Package.resolved` (Constitution VIII.1).
- [X] T040 [US4] Add the local package `CheckersEngine` to `checkers/checkers.xcodeproj/project.pbxproj` (local package reference, product dependency on the `checkers` target) and add `CheckersEngineTests` to `checkers/checkers.xctestplan`. T037 passes and `scripts/test.sh` runs the engine tests.
- [X] T041 [US4] Create `checkers/CheckersEngine/.swiftlint.yml` with `parent_config: ../.swiftlint.yml` so the package's plugin uses the shared rules; confirm the T038 case and a real build both report `engine_no_ui_imports` for a temporary `import SwiftUI` in `Side.swift`, then revert.

**Checkpoint**: US4 complete; E2 can start test-first in `CheckersEngine`.

---

## Phase 7: User Story 5 - Privacy, logging and localization baseline (Priority: P3)

**Goal**: Accurate privacy manifest, shared logger, string catalog with a drift check, iPhone-only portrait (#19, #20, #21, #22; FR-014 to FR-018; FR-PRIV-01, FR-PRIV-02, FR-PLAT-01, FR-PLAT-03).

**Independent Test**: the US5 tests pass; the catalog check fails on a removed key (quickstart §6).

### Tests for User Story 5 (MANDATORY - write first) ⚠️

- [X] T042 [P] [US5] Write `checkers/checkersTests/PrivacyManifestTests.swift` with `@Test("US5: privacy manifest declares no tracking and no collected data")`: loads `PrivacyInfo.xcprivacy` from `Bundle.main`, decodes the property list, and expects `NSPrivacyTracking == false` and empty `NSPrivacyTrackingDomains`, `NSPrivacyCollectedDataTypes` and `NSPrivacyAccessedAPITypes`.
- [X] T043 [P] [US5] Write `checkers/checkersTests/PlatformSettingsTests.swift` with `@Test("US5: the app targets iPhone only, in portrait")`: expects `UIDeviceFamily == [1]` and `UISupportedInterfaceOrientations == ["UIInterfaceOrientationPortrait"]` in `Bundle.main.infoDictionary`, and no `UISupportedInterfaceOrientations~ipad` or `~iphone` keys.
- [X] T044 [P] [US5] Write `checkers/checkersTests/LoggingTests.swift` with `@Test("US5: logs use the bundle identifier as subsystem")`: expects `Log.subsystem == Bundle.main.bundleIdentifier` and `Log.Category.app.rawValue == "app"`.
- [X] T045 [P] [US5] Write `checkers/checkersTests/LocalizationTests.swift` with `@Test("US5: user-facing strings come from the string catalog")`: reads `checkers/checkers/Localizable.xcstrings` through a path built from `#filePath`, decodes its `strings` keys, and expects every `Screen.all` title key plus `Screen` (the picker label) to be present. It does not rely on the compiled string table, which may omit untranslated source-language keys; completeness is covered by T051.
- [X] T046 [P] [US5] Write `scripts/tests/test-string-catalog-check.sh` named "US5: string catalog drift": builds a temp fixture with a catalog lacking a key that a fixture `.stringsdata` file uses, expects `scripts/check-string-catalog.sh` to fail and name the key, then expects success with a matching catalog.

### Implementation for User Story 5

- [X] T047 [US5] Add `checkers/checkers/PrivacyInfo.xcprivacy` per research R13: `NSPrivacyTracking` false, empty `NSPrivacyTrackingDomains`, `NSPrivacyCollectedDataTypes` and `NSPrivacyAccessedAPITypes`. Check with `plutil -lint`. T042 passes.
- [X] T048 [US5] In `checkers/checkers.xcodeproj/project.pbxproj`, set `TARGETED_DEVICE_FAMILY = 1` and the device-independent `INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait`, and remove both `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` and `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad` (they generate device-specific `~iphone`/`~ipad` keys), in both configurations. T043 passes.
- [X] T049 [US5] Add `checkers/checkers/Support/Logging.swift`: `enum Log` with `static let subsystem = Bundle.main.bundleIdentifier ?? "Hussein-Helmy.checkers"`, `enum Category: String { case app }`, and `static let app = Logger(subsystem: subsystem, category: Category.app.rawValue)`. In `WebView.updateUIView` (`checkers/checkers/ContentView.swift`), log a missing screen resource with `Log.app.error` before returning (the blank screen it leaves is pre-existing and replaced in E3; see plan, Other recorded decisions). T044 passes.
- [X] T050 [US5] Add `checkers/checkers/Localizable.xcstrings`; make `Screen.title` a `LocalizedStringResource` and use it with `Text(_:)` in `ContentView`; build in Xcode so the catalog lists `Screen`, `Classic`, `Modern`, `Playful` and `Play`; commit the catalog. T045 passes.
- [X] T051 [US5] Implement `scripts/check-string-catalog.sh <catalog> <derived-data>`: copy the catalog to a temp dir under the same file name, run `xcrun xcstringstool sync` with the app target's `.stringsdata` files from the derived data, diff against the committed file, and on a difference fail with the added or stale keys. T046 passes.
- [X] T052 [US5] Add a CI step after the tests in `.github/workflows/ci.yml` running `scripts/check-string-catalog.sh checkers/checkers/Localizable.xcstrings .build/DerivedData`.

**Checkpoint**: US5 complete.

---

## Phase 8: User Story 6 - Clean project and launch-time baseline (Priority: P3)

**Goal**: Remove the template leftovers and record a launch-time baseline that CI reports without failing (#24, #28; FR-019, FR-020; clarification Q2).

**Independent Test**: the leftovers are gone and the app builds; the launch test reports a duration locally and in the CI job summary (quickstart §7).

### Tests for User Story 6 (MANDATORY - write first) ⚠️

- [X] T053 [P] [US6] Write `checkers/checkersUITests/LaunchPerformanceTests.swift` with `testUS6_coldLaunchDuration`, measuring `XCUIApplication().launch()` with `XCTApplicationLaunchMetric()`.

### Implementation for User Story 6

- [X] T054 [US6] Delete `checkers/checkers/Item.swift` and `checkers/checkers/Assets.xcassets/CheckersApp.swift`; confirm nothing references them (`git grep -n "Item\b\|SwiftData"` finds nothing) and the app builds.
- [X] T055 [US6] Create `checkers/Performance.xctestplan` containing only `LaunchPerformanceTests`, add it to `checkers.xcscheme`, and skip `LaunchPerformanceTests` in `checkers/checkers.xctestplan`.
- [X] T056 [US6] Run the Performance plan locally on the iPhone 17 simulator (`TEST_PLAN=Performance scripts/test.sh`) and record the baseline with `scripts/report-launch.sh <xcresult> --record` in `checkers/launch-baselines.json`, one entry per machine. (Changed during implementation: Xcode's own baselines are keyed to one exact machine and cannot be created reliably from the command line; see research R12.)
- [X] T057 [US6] Create `scripts/report-launch.sh <xcresult>`: extracts the launch duration with `xcrun xcresulttool` and prints a Markdown line with the measured value and the recorded baseline. Add a CI step running the Performance plan as a normal (blocking) step, without `continue-on-error`: CI runners have no recorded baseline, so timing only reports and cannot fail, while a launch test that errors fails `CI gate` (Constitution III.5). A following step with `if: always()` appends the report to `$GITHUB_STEP_SUMMARY`.

**Checkpoint**: All six stories complete.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [ ] T058 Run every scenario in `specs/001-project-foundation/quickstart.md` and record each result in `specs/001-project-foundation/checklists/validation.md`.
- [X] T059 [P] Update `checkers/CLAUDE.md` (project guide) for the new layout: test command, scripts, engine package, test plans, removed leftovers, Swift 6 settings.
- [X] T060 [P] Update `HANDOFF.md` lessons learned: plugin trust and `-skipPackagePluginValidation`, the protected-`main` workflow, the catalog drift check, Xcode 26.3 pin.
- [ ] T061 Final verification: `main` builds with 0 compiler warnings and 0 lint errors (SC-005); the last code CI run took under 20 minutes (SC-006); the T001 smoke check gives the same result (SC-007); and the slice added no network, account, analytics or permission code (FR-015): `git diff main~N -- checkers/ | grep -E 'URLSession|import Network|NSURLConnection|UsageDescription'` over the slice's commits finds nothing.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: depends on Setup; blocks all stories.
- **US1 (Phase 3)**: depends on Phase 2.
- **US2 (Phase 4)**: depends on US1 (CI runs the tests). T021–T022 (protection) run after the first green `CI gate` on `main`.
- **US3 (Phase 5)**: depends on Phase 2; its CI steps (T034, T035) depend on T018.
- **US4 (Phase 6)**: depends on Phase 2 and on US3's SwiftLint setup (T027–T029) for its lint parts.
- **US5 (Phase 7)**: depends on Phase 2 and T010 (`Screen`); its CI step (T052) depends on T018.
- **US6 (Phase 8)**: depends on Phase 2; its CI step (T057) depends on T018.
- **Polish (Phase 9)**: depends on all stories.

### Within Each User Story

- Test tasks first; observe them fail (or fail to compile) before implementing.
- Project-file edits before code that needs them.
- Story complete, with `scripts/test.sh` green, before the next priority.

### Parallel Opportunities

- T003 alongside T002.
- Within a story, all `[P]` test tasks can be written together (different files).
- US3, US5 and US6 local work can proceed in parallel after Phase 2; their CI steps wait for T018.

## Parallel Example: User Story 5

```bash
Task: "T042 PrivacyManifestTests.swift"
Task: "T043 PlatformSettingsTests.swift"
Task: "T044 LoggingTests.swift"
Task: "T045 LocalizationTests.swift"
Task: "T046 test-string-catalog-check.sh"
```

## Implementation Strategy

### MVP First (User Story 1)

1. Phases 1–2, then US1: local tests run and fail correctly.
2. **Stop and validate** with quickstart §1.

### Incremental Delivery

1. US1 → US2 (CI gate and protection) → US3 (safety rules) → US4 (engine) → US5 → US6.
2. After each story: `scripts/test.sh` green, push the branch, CI green, update the board and `EXECUTION_PLAN.md`.

## Board Mapping

Reconciled with the board in #7 (2026-10-16). Each board task maps to these tasks, and each board issue lists its task IDs:

| Board task | Tasks |
|---|---|
| #9 Test targets | T002, T004–T012 |
| #10 CI build and test | T013–T019 |
| #11 Fail on warnings and lint | T018 (warnings as errors), T020, T034, T035 |
| #12 Protect `main` | T021, T022 |
| #14 Swift 6 | T026 |
| #16 SwiftLint rules | T023, T024, T027–T029 |
| #17 swift-format | T025, T030–T034 |
| #19 Privacy manifest | T042, T047 |
| #20 Logger | T044, T049 |
| #21 String catalog | T045, T046, T050–T052 |
| #22 iPhone only, portrait | T043, T048 |
| #24 Template leftovers | T054 |
| #25 Engine module | T036–T041 |
| #28 Launch baseline | T053, T055–T057 |
| #191 Validate the slice and update docs | T001, T003, T058–T061 (T061 also checks FR-015) |

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Each acceptance test names its story ID (for example `US1`) in its display name or tag
- Each completed task leaves the app building and all tests passing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
