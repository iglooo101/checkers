# CLAUDE.md

Guidance for working with the code in this repository.

## Project

An iPhone-only (portrait) SwiftUI checkers app, deployment target iOS 26.2, Swift 6 language mode
with complete strict concurrency. The game and visuals still live in bundled HTML/CSS/JS screens
shown in a `WKWebView`; epic E3 replaces them with native SwiftUI. The rules engine (E2) lives in
the local package `CheckersEngine`, where the computer opponent (E4) will join it. The git
repository root is the parent directory (remote:
`github.com/iglooo101/checkers`); product requirements are in `../FRD.md`, the constitution in
`../.specify/memory/constitution.md`, and progress in `../EXECUTION_PLAN.md`.

## Build, test and format

Run these from the repository root:

```sh
scripts/test.sh                         # blocking test plan: unit, UI and engine tests on iPhone 17
TEST_PLAN=Performance scripts/test.sh   # cold-launch timing only
scripts/report-launch.sh .build/TestResults/Performance.xcresult   # compare with launch-baselines.json
(cd checkers/CheckersEngine && swift test)   # engine tests on the Mac, without the app (no lint)
(cd checkers/CheckersEngine && swift test --filter US3)   # one story's suite (US1…US5)
scripts/format.sh                       # format all Swift sources in place
scripts/check-format.sh --strict        # what CI runs; without --strict it only warns
scripts/tests/run.sh                    # script tests (CI rules, lint rules, format, catalog check)
```

Command-line builds need `-skipPackagePluginValidation` (already in `scripts/lib.sh`); in Xcode,
trust the SwiftLint plugin once when asked. Derived data goes to `.build/DerivedData`.

## Architecture

- `checkers/ContentView.swift`: a segmented `Picker` over `Screen.all` (title as a
  `LocalizedStringResource`, file name of the bundled HTML) and a `WebView`
  (`UIViewRepresentable`) that loads `<file>.html` with read access to the bundle directory.
  `.id(selected)` forces a fresh `WKWebView` on every tab switch.
- `checkers/Support/Logging.swift`: `Log` with one `Logger` per feature category under the bundle
  identifier. Never use `print`.
- `checkers/Localizable.xcstrings`: every user-facing string. Building in Xcode updates it; CI fails
  if it drifts (`scripts/check-string-catalog.sh`).
- `checkers/PrivacyInfo.xcprivacy`: no tracking and no collected data. Add a required-reason API
  entry in the same change that starts using one (for example `UserDefaults`, reason `CA92.1`).
- `CheckersEngine/`: UI-free Swift package (Swift 6, iOS 26.2 and macOS 15 for host tests); lint
  fails on UI imports in it. It holds the American checkers rules as `Sendable` value types:
  `Square` (a–h / 1–8 names), `Piece`, `Position` (three 32-bit sets), `Step` (from, to; two
  squares long is a jump) and `GameState`, whose `apply(_:)` returns a `StepResult`, plus
  `resign(_:)`, `undo()` and the legal-step queries. Rejections throw `RuleError`. The public API
  and its rules are in `../specs/002-rules-engine/contracts/engine-api.md`.
- Engine tests (`CheckersEngine/Tests/CheckersEngineTests/`): one suite per story
  (`US1StartAndMoveTests`…`US5UndoTests`) whose test names list the FRD IDs they prove; unit
  suites for squares, positions and steps; `ReferenceCountTests` (published move counts, depths
  1–7) and `RandomGameTests` (1,000 seeded games with full undo). Helpers in `Support/` build
  positions from square names, for example `GameState(["c3": .lightMan], toMove: .light)`.
- Targets: app `checkers`, `checkersTests` (Swift Testing, MainActor default isolation),
  `checkersUITests` (XCUITest, nonisolated default; mark tests `@MainActor`). Acceptance tests
  name their story ID (`US1`…). Test plans: `checkers.xctestplan` (blocking) and
  `Performance.xctestplan` (launch timing).
- The project uses **file-system synchronized groups** (`objectVersion = 77`): files dropped into a
  target's folder join that target without `project.pbxproj` edits.
- HTML screens: `Classic.html`, `Modern.html`, `Playful.html` are static board mockups scaled by
  `fitBoard()`; `Play.html` is the two-player prototype (Light `'w'` moves first). To iterate on a
  screen, open the HTML file in a browser.

## Rules enforced on every build and in CI

- SwiftLint 0.65.1 through the `SwiftLintPlugins` package plugin, configured in `.swiftlint.yml`
  (errors: force unwrap family, `ObservableObject`/`@Published`, Combine, `DispatchQueue`/
  `OperationQueue`/`Thread`, `print`). Test folders relax the force-unwrap family and `print`.
  `identifier_name` also accepts `to` (`Step.to`). `swift test` does not run the plugin, so the
  engine is linted only by the Xcode build (`scripts/test.sh`, CI).
- swift-format (bundled with Xcode) with `../.swift-format`: warnings locally, errors in CI.
- CI (`../.github/workflows/ci.yml`): pushes to any branch except `main`; Markdown-only pushes
  skip build and tests; the `CI gate` job is the required check. Land work on `main` by
  fast-forward after the branch is green; no pull requests.
