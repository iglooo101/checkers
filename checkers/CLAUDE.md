# CLAUDE.md

Guidance for working with the code in this repository.

## Project

An iPhone-only (portrait) SwiftUI checkers app, deployment target iOS 26.2, Swift 6 language mode
with complete strict concurrency, entirely native SwiftUI (E3 removed the web prototype). The
rules engine (E2) lives in the local package `CheckersEngine`, where the computer opponent (E4)
will join it. The git
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
scripts/sync-string-catalog.sh          # after a command-line build: update the string catalog
```

Command-line builds need `-skipPackagePluginValidation` (already in `scripts/lib.sh`); in Xcode,
trust the SwiftLint plugin once when asked. Derived data goes to `.build/DerivedData`.

## Architecture

- App layout by feature (`checkers/`): `App/` (`RootView`: one `NavigationStack` over Home;
  `AppRouter`: the path, the game in play, setup choices and the leave confirmation; `Route`),
  `Features/Home`, `Features/Setup` (`GameSetup`, `SetupStore` with a `UserDefaults` store and an
  in-memory one for tests and previews, `SetupView`), `Features/Game` (`GameSession`, the
  `@Observable` model that turns taps and drags into engine steps; `GameText` for every game
  sentence; `BoardLayout` for orientation; `GameView`, `BoardView`, `PieceView`, `ResultPanel`)
  and `Features/Placeholders` (Statistics, Rules and Settings until E5 and E6). Behavior and
  texts follow `../specs/003-game-experience/contracts/` (`game-session.md`, `screens.md`).
- Views are thin: rules come from the engine, interaction rules from `GameSession`, navigation from
  `AppRouter`. Board colors come only from `Support/Palette.swift` (asset colors with light and
  dark variants). Nothing on the board animates.
- Confirmations are alerts: on iOS 26 a confirmation dialog opened from a toolbar item shows as a
  popover without Cancel.
- `checkers/Support/Logging.swift`: `Log` with one `Logger` per feature category under the bundle
  identifier. Never use `print`.
- `checkers/Localizable.xcstrings`: every user-facing string, as whole sentences. Building in Xcode
  updates it; after command-line builds run `scripts/sync-string-catalog.sh`. CI fails if it
  drifts (`scripts/check-string-catalog.sh`). Return optional strings from a `switch` with explicit
  `return`s: from a `switch` expression the compiler extracts only one literal.
- `checkers/PrivacyInfo.xcprivacy`: no tracking and no collected data; declares the user-defaults
  API (reason `CA92.1`) for the remembered setup choices. Add any new required-reason API in the
  same change that starts using it.
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
- Targets: app `checkers`, `checkersTests` (Swift Testing, MainActor default isolation; suites
  `US1TwoPlayerMoveTests`…`US7NavigationTests` plus layout, palette, privacy and localization;
  `Support/GamePositions.swift` builds positions through the engine's public API),
  `checkersUITests` (XCUITest, nonisolated default; mark tests `@MainActor`; one class per story;
  `Support/AppScreens.swift` finds elements by the identifiers in `screens.md`). Acceptance tests
  name their story ID (`US1`…). Test plans: `checkers.xctestplan` (blocking) and
  `Performance.xctestplan` (launch timing).
- The project uses **file-system synchronized groups** (`objectVersion = 77`): files dropped into a
  target's folder join that target without `project.pbxproj` edits.

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
