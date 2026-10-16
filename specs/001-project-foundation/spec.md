# Feature Specification: Project Foundation

**Feature Branch**: `001-project-foundation`

**Created**: 2026-10-16

**Status**: Draft

**Input**: User description: "Project foundation (epic E1, GitHub issue #1): bring the existing checkers iOS project into compliance with constitution v1.1.0 before any feature work starts. The users of this slice are the solo developer and CI, so user stories are developer-facing. Scope: test and CI infrastructure (#8), Swift 6 and strict concurrency (#13), lint and format (#15), privacy, logging and localization baseline (#18), project structure and cleanup (#23). Out of scope: any game feature or visible UI change, the contents of the rules engine (E2), and App Store delivery (E8)."

## Clarifications

### Session 2026-10-16

- Q: Should the repository owner be able to push to `main` without a passing CI check? → A: No bypass; `main` rejects every commit without a passing check, including the owner's, and nothing lands while CI is down.
- Q: Should the launch-time test be able to fail CI and block `main`? → A: No; CI runs it on every code push and reports the result against the baseline without failing the check. The hard 400 ms check is on a real iPhone in #181 (E8).
- Q: What should a local build do when code is not formatted to the project style? → A: Report unformatted files as warnings and change nothing; CI fails on them; one command formats on demand.
- Q: Which changes count as documentation and skip the build and tests in CI? → A: Markdown files only: a push skips them only when every changed file ends in `.md`; anything else, including Spec Kit scripts and `.gitignore`, runs the full check.
- Q: Should lint warnings, and not only lint errors, fail CI? → A: Only lint errors fail CI; lint warnings are reported but can land.

## User Scenarios & Testing *(mandatory)*

The people served by this slice are the developer (the only contributor) and the automated
checks that guard `main`. Each story names the board tasks and constitution principles it
satisfies.

### User Story 1 - Run automated tests locally (Priority: P1)

The developer runs the app's unit tests and UI tests from the project's single scheme with one
command and gets a clear pass or fail. A failing test fails the run, and main-thread violations
are caught during test runs. (#9; Constitution III, VII)

**Why this priority**: Constitution III makes test-first development non-negotiable, and every
later slice starts by writing a failing test. Nothing else in the backlog can follow the
constitution until tests can run.

**Independent Test**: Run the test command on a clean checkout: it reports passing unit and UI
tests. Add a deliberately failing assertion: the same command reports failure and names the test.

**Acceptance Scenarios**:

1. **Given** a clean checkout, **When** the developer runs the test command, **Then** at least one
   unit test and one UI test run and the run passes.
2. **Given** a unit test that fails, **When** the developer runs the test command, **Then** the run
   fails and reports the failing test by name.
3. **Given** code that touches UI from a background thread under test, **When** the tests run,
   **Then** the main-thread violation is reported.

---

### User Story 2 - CI guards `main` (Priority: P1)

Every push that changes code or project files is built and tested automatically on an iPhone
simulator. The run fails on any failing test, compiler warning, lint error or formatting
violation. Commits reach `main` only after their check has passed, and work still lands by a
local fast-forward merge with no pull request. Documentation-only changes skip the build and
tests but still pass the required check. (#10, #11, #12, #17; Constitution III, IV)

**Why this priority**: Constitution III.5 and the workflow gates require that a merge never
lands on a red build. Without this gate, every later slice can regress silently.

**Independent Test**: Push three probe commits to a branch (one failing test, one compiler
warning, one lint error) and confirm each check fails; push a docs-only commit and confirm the
check passes without building; try to land an unchecked commit on `main` and confirm it is
rejected.

**Acceptance Scenarios**:

1. **Given** a push to any branch that changes code or project files, **When** CI runs, **Then**
   it builds the app and runs every test suite, and reports pass or fail on that commit.
2. **Given** a commit with a failing test, a compiler warning, a lint error or unformatted code,
   **When** CI runs, **Then** the check fails and the log names the cause.
3. **Given** a push that changes only Markdown files, **When** CI runs, **Then** no build or test
   runs and the required check still reports success.
4. **Given** a commit whose required check has not passed, **When** the developer pushes it to
   `main`, **Then** the push is rejected.
5. **Given** a feature branch whose head commit passed CI, **When** the developer fast-forwards
   `main` to it and pushes, **Then** the push is accepted without a pull request.

---

### User Story 3 - The compiler and linter enforce safety rules (Priority: P2)

The app builds in Swift 6 language mode with complete strict concurrency checking and zero
warnings. Lint runs on every local build and in CI, and treats the constitution's banned
constructs as errors. Formatting follows one shared configuration. (#14, #16, #17;
Constitution I, IV, IX)

**Why this priority**: These rules turn data races, crashes from force unwraps, legacy
concurrency and stray `print` calls into build failures before any feature code exists, which
is far cheaper than retrofitting them.

**Independent Test**: Add a force unwrap, an `ObservableObject`, a `DispatchQueue` call and a
`print(` to a non-allow-listed app file: each one fails the build or lint. Remove them: the build
is clean with zero warnings.

**Acceptance Scenarios**:

1. **Given** the existing app, **When** it is built, **Then** it compiles in Swift 6 language mode
   with complete strict concurrency checking and zero warnings.
2. **Given** a force unwrap, force cast, `try!` or implicitly unwrapped optional outside test
   code, **When** the project is built or linted, **Then** an error is reported.
3. **Given** `ObservableObject`, `import Combine`, `DispatchQueue` or `print(` in a file that is
   not on the allow-list, **When** lint runs, **Then** an error is reported; the same construct in
   an allow-listed file (or `print(` in test code) is accepted.
4. **Given** code that does not match the shared format, **When** the format check runs locally or
   in CI, **Then** it reports the file: locally as a warning with no file changed, and in CI as a
   failed check.

---

### User Story 4 - An engine module is ready for the rules engine (Priority: P2)

A separate, UI-free engine module exists with its own unit test suite, and the app depends on
it. Epic E2 can then write rules-engine tests first, without touching UI code. (#25;
Constitution II, III)

**Why this priority**: E2 starts right after this slice. Having the module, its test suite and
the dependency in place lets E2 begin test-first on day one.

**Independent Test**: Run the engine module's tests on their own: a sample test passes. Build the
app: it links the module and calls one public symbol from it.

**Acceptance Scenarios**:

1. **Given** the engine module, **When** its tests run on their own, **Then** a sample test passes
   without building or launching the app.
2. **Given** the app target, **When** it is built, **Then** it depends on the engine module.
3. **Given** a UI framework import inside the engine module, **When** it is built or linted,
   **Then** the build or lint fails.
4. **Given** CI runs for a code change, **When** it runs the test suites, **Then** the engine
   module's tests are included.

---

### User Story 5 - Privacy, logging and localization baseline (Priority: P3)

The app ships an accurate privacy manifest, one shared way to log, a string catalog for every
user-facing string, and runs on iPhone in portrait only. Later features add to these instead of
inventing their own. (#19, #20, #21, #22; FR-PRIV-01, FR-PRIV-02, FR-PLAT-01, FR-PLAT-03;
Constitution V, VI, IX)

**Why this priority**: Each item is small, but retrofitting localization and privacy declarations
later is costly (Constitution V and VI). It ranks below the gates because it does not block E2.

**Independent Test**: Generate the privacy report from an archive: it shows no tracking and no
collected data. Launch on an iPad simulator: the app is unavailable or runs as an iPhone app.
Rotate an iPhone simulator: the app stays in portrait. Remove a used key from the string
catalog: the build fails.

**Acceptance Scenarios**:

1. **Given** a release archive, **When** the privacy report is generated, **Then** it shows no
   tracking, no tracking domains and no collected data, and declares the user-defaults
   required-reason API with an approved reason.
2. **Given** any feature, **When** it needs to log, **Then** it uses the shared logger with the
   app's bundle identifier as subsystem and its own category, and dynamic values are redacted by
   default.
3. **Given** a user-facing string in the app's Swift code, **When** the project is built, **Then**
   the string comes from the string catalog, and a missing or stale catalog entry fails the build.
4. **Given** the app on an iPhone, **When** the device rotates to landscape, **Then** the app stays
   in portrait.
5. **Given** the project settings, **When** they are inspected, **Then** the app targets iPhone
   only.

---

### User Story 6 - Clean project and launch-time baseline (Priority: P3)

The unused template files are gone, and an automated launch test records how long a cold launch
takes to reach the first frame, so later slices can see regressions against the 400 ms budget.
(#24, #28; Constitution II, VII)

**Why this priority**: Leftover files confuse later work, and a baseline is only useful if it
exists before features add launch cost. Neither blocks E2.

**Independent Test**: Search the project for the removed files and for the unused data-model
import: nothing is found and the app builds. Run the launch test: it reports a launch duration.

**Acceptance Scenarios**:

1. **Given** the project, **When** it is searched, **Then** `checkers/checkers/Item.swift` and
   `checkers/checkers/Assets.xcassets/CheckersApp.swift` no longer exist and nothing references
   them.
2. **Given** the launch performance test, **When** it runs, **Then** it measures cold launch to
   first frame and records the result as the baseline.
3. **Given** a later change that slows launch beyond the recorded baseline's allowed deviation,
   **When** the launch test runs, **Then** it reports the regression.

---

### Edge Cases

- **Mixed push**: a push that changes Markdown and code runs the full build and tests.
- **Non-Markdown support files**: a push that changes only Spec Kit scripts, templates,
  `.gitignore` or other non-Markdown files runs the full build and tests.
- **Docs-only push to `main`**: the required check reports success without building, so the
  push is accepted.
- **First push of the CI setup itself**: the commit that adds CI must pass its own check before
  `main` protection is switched on, so protection never blocks its own introduction.
- **Existing web-view screens under Swift 6**: the four current screens must keep loading and
  behaving as before; fixes needed for strict concurrency must not change visible behavior.
- **Owner bypass**: the protection on `main` applies to the repository owner too; an
  emergency push still needs a passing check.
- **CI unavailable**: when the hosted CI service cannot run, nothing lands on `main` until it can.
- **Allow-listed constructs**: an allow-list entry must name specific files, and every entry is
  recorded with its reason in the plan, so the ban cannot be bypassed project-wide.
- **Simulator timing noise**: launch timings on CI simulators vary; the baseline must tolerate
  normal variance and must not be read as proof of the 400 ms device budget.

## Requirements *(mandatory)*

### Functional Requirements

**Tests (#9, #25)**

- **FR-001**: The project MUST have a unit test suite using Swift Testing and a UI test suite
  using XCUITest, both runnable from the `checkers` scheme with one command.
- **FR-002**: Test runs MUST detect main-thread violations (Main Thread Checker enabled).
- **FR-003**: A failing test MUST fail the run and be reported by name.
- **FR-004**: A UI-free engine module (`CheckersEngine`) MUST exist with its own Swift Testing
  suite that runs without the app; the app target MUST depend on it, and the module MUST NOT
  depend on any UI framework.

**Continuous integration and `main` protection (#10, #11, #12, #17)**

- **FR-005**: Every push to any branch that changes anything other than Markdown files MUST
  trigger a build of the app and a run of every test suite (unit, UI, engine) on an iPhone
  simulator.
- **FR-006**: A push that changes only Markdown (`.md`) files MUST NOT build or run tests, and
  MUST still report the required check as passed.
- **FR-007**: The CI check MUST fail on any failing test (other than the report-only launch test
  in FR-020), any compiler warning, any lint error, or any formatting violation, and its log MUST
  name the cause.
- **FR-008**: `main` MUST reject any pushed commit whose required check has not passed. The rule
  MUST NOT require pull requests and MUST apply to the repository owner.
- **FR-009**: Fast-forwarding `main` to a branch commit that already passed its check MUST be
  accepted without re-running CI.

**Language mode and static checks (#14, #16, #17)**

- **FR-010**: The app and the engine module MUST build in Swift 6 language mode with complete
  strict concurrency checking and zero compiler warnings, both locally and in CI.
- **FR-011**: Lint MUST run on every local build and in CI. Force unwraps, force casts, `try!` and
  implicitly unwrapped optionals outside test code MUST be errors. Lint errors MUST fail CI; lint
  warnings MUST be reported in the CI log but MUST NOT fail the check.
- **FR-012**: Lint MUST report an error for `ObservableObject`, `import Combine`, `DispatchQueue`
  or `print(` outside an allow-list that names specific files; `print(` is allowed in test code.
- **FR-013**: One shared formatting configuration MUST be checked on every local build and in CI.
  A local build MUST report unformatted files as warnings without changing any file; CI MUST
  fail on them. One command MUST format the code on demand.

**Privacy, logging, localization and platform (#19, #20, #21, #22)**

- **FR-014**: The app MUST include a privacy manifest declaring no tracking, no tracking domains
  and no collected data, and declaring the user-defaults required-reason API with an approved
  reason (FR-PRIV-01, Constitution VI).
- **FR-015**: This slice MUST NOT add network requests, accounts, analytics or system permission
  requests (FR-PRIV-01, FR-PRIV-02).
- **FR-016**: A shared logger MUST use the app's bundle identifier as subsystem and one category
  per feature, with default private redaction of dynamic values; shipped code MUST NOT use
  `print`, `debugPrint` or `NSLog` (Constitution IX).
- **FR-017**: All user-facing strings in Swift code MUST come from a string catalog, and catalog
  warnings MUST fail the build (FR-PLAT-03, Constitution V).
- **FR-018**: The app MUST target iPhone only and support portrait orientation only (FR-PLAT-01).

**Cleanup and launch baseline (#24, #28)**

- **FR-019**: `checkers/checkers/Item.swift` and `checkers/checkers/Assets.xcassets/CheckersApp.swift`
  MUST be removed, with no remaining references or unused imports they required.
- **FR-020**: An automated launch performance test MUST measure cold launch to first frame and
  record a baseline that later runs compare against (Constitution VII). CI MUST run it on every
  code push and report the result against the baseline, but a slow result MUST NOT fail the
  check.

**Preservation**

- **FR-021**: The four existing screens (Classic, Modern, Playful, Play) MUST keep loading and
  behaving as before; this slice makes no visible UI change.

### Traceability

| Board task | Requirements |
|---|---|
| #9 Test targets | FR-001, FR-002, FR-003 |
| #10 CI build and test | FR-005, FR-006 |
| #11 Fail on warnings and lint | FR-007 |
| #12 Protect `main` | FR-008, FR-009 |
| #14 Swift 6 | FR-010 |
| #16 SwiftLint rules | FR-011, FR-012 |
| #17 swift-format | FR-007, FR-013 |
| #19 Privacy manifest | FR-014, FR-015 |
| #20 Logger | FR-016 |
| #21 String catalog | FR-017 |
| #22 iPhone only, portrait | FR-018 |
| #24 Template leftovers | FR-019 |
| #25 Engine module | FR-004 |
| #28 Launch baseline | FR-020 |

FRD requirements covered as a baseline: FR-PRIV-01, FR-PRIV-02, FR-PLAT-01, FR-PLAT-03. Later
slices must keep them true.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Each of four probe commits (failing test, compiler warning, lint error, formatting
  violation) turns the check red, 4 out of 4.
- **SC-002**: A documentation-only push gets a passing check within 2 minutes, with no build or
  test step run.
- **SC-003**: An attempt to push a commit to `main` without a passing check is rejected, including
  when made by the repository owner.
- **SC-004**: Landing a branch on `main` takes no pull request: a fast-forward push of a
  checked commit is accepted on the first try.
- **SC-005**: `main` builds with 0 compiler warnings and 0 lint errors.
- **SC-006**: A full CI run (build plus all test suites) for a code change finishes in under
  20 minutes.
- **SC-007**: The four existing screens load and the Play screen accepts a move, exactly as before
  the slice (manual smoke check on an iPhone simulator).
- **SC-008**: The privacy report of a release archive lists 0 collected data types and no
  tracking.
- **SC-009**: A launch-time baseline is recorded, and a later run reports its duration against it.

## Assumptions

- The repository is public on GitHub, so hosted macOS CI runners and branch protection rules are
  available at no cost, and the hosted runners provide an Xcode that supports the iOS 26.2 SDK.
- CI runs on pushes to every branch, because work is pushed on feature branches before `main`
  is fast-forwarded; no pull request triggers are needed.
- "Documentation-only" means every changed file ends in `.md` (including files under `specs/`);
  any other change runs the full check (confirmed in Clarifications).
- `main` protection applies to the owner with no bypass and no emergency exception, as the
  constitution's merge gate requires (confirmed in Clarifications).
- SwiftLint and swift-format are pre-approved by the constitution (VIII.2). The development Mac has
  no Homebrew, so the plan must obtain them in a way that works without it.
- The 400 ms budget applies to a release build on a recent iPhone; proving it on hardware is task
  #181 in epic E8. This slice records a simulator baseline only.
- The current web-view UI stays until epic E3 replaces it. Only the Swift changes needed for
  Swift 6, lint and localization are made to it, and existing user-facing strings in Swift (the
  screen titles) move into the string catalog.
- The engine module contains only a placeholder public symbol and a sample test; the rules
  themselves are epic E2.
