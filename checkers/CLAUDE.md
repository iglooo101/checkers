# CLAUDE.md

Guidance for working with the code in this repository.

## Project

An iPhone-only (portrait) SwiftUI checkers app, deployment target iOS 26.2, Swift 6 language mode
with complete strict concurrency, entirely native SwiftUI (E3 removed the web prototype). The
rules engine (E2) and the computer opponent's search (E4) live in the local package
`CheckersEngine`. The git repository root is the parent directory (remote:
`github.com/iglooo101/checkers`); product requirements are in `../FRD.md`, the constitution in
`../.specify/memory/constitution.md`, and progress in `../EXECUTION_PLAN.md`.

## Build, test and format

Run these from the repository root:

```sh
scripts/test.sh                         # blocking test plan: unit, UI and engine tests on iPhone 17
TEST_PLAN=Performance scripts/test.sh   # cold-launch timing only
scripts/report-launch.sh .build/TestResults/Performance.xcresult   # compare with launch-baselines.json
(cd checkers/CheckersEngine && swift test)   # engine tests on the Mac, without the app (lints too)
(cd checkers/CheckersEngine && swift test --filter US3)   # one story's suite (US1…US5)
(cd checkers/CheckersEngine && swift test -c release --filter CheckersEngineStrengthTests)
                                        # strength matches, Release only (skipped in Debug)
scripts/format.sh                       # format all Swift sources in place
scripts/check-format.sh --strict        # what CI runs; without --strict it only warns
scripts/tests/run.sh                    # script tests (CI rules, lint rules, format, catalog check)
scripts/sync-string-catalog.sh          # after a command-line build: update the string catalog
python3 scripts/make-sounds.py          # rewrite the four game sounds from their recipes
python3 scripts/make-sounds.py --check  # the committed sounds still match their recipes
```

Command-line builds need `-skipPackagePluginValidation` (already in `scripts/lib.sh`); in Xcode,
trust the SwiftLint plugin once when asked. Derived data goes to `.build/DerivedData`.

## Architecture

- App layout by feature (`checkers/`): `App/` (`RootView`: one `NavigationStack` over Home;
  `AppRouter`: the path, the game in play, setup choices, the saved game and the record;
  `Route`), `Features/Home` (Continue and the restore alerts), `Features/Setup` (`GameSetup`,
  `SetupStore` with a `UserDefaults` store and an in-memory one for tests and previews,
  `SetupView` with the abandon alert), `Features/Game` (`GameSession`, the `@Observable` model
  that turns taps and drags into engine steps; `GameText` for every game sentence; `BoardLayout`
  for orientation; `GameView`, `BoardView`, `PieceView`, `ResultPanel`; `BoardPicture` for still
  boards), `Features/Saving` (`SavedGame`, `SavedGameStore`, `RestoreNotice`),
  `Features/Statistics` (`Record`, `GameResult`, `RecordStore`, `StatisticsText`,
  `StatisticsView`), `Features/Settings` (`SettingsValues` and `SettingsStore`, `AppSettings`,
  `BoardTheme`, `SettingsView`), `Features/Rules` (`RulesContent`, `RulesView`) and
  `Features/Sound` (`SoundEffect`, `SoundBank`, `SoundPlayer`, the files in `Sounds/`). E6
  removed the Rules and Settings placeholders. Behavior and texts follow
  `../specs/003-game-experience/contracts/` (`game-session.md`, `screens.md`) as changed by
  `../specs/006-saving-and-statistics/contracts/` and
  `../specs/007-settings-themes-sound-and-rules/contracts/`.
- Saving and statistics (E5, `../specs/006-saving-and-statistics/contracts/saved-game.md`): one
  saved game and the record are versioned JSON (version 1) in `UserDefaults.standard` under
  `savedGame` and `record`, behind `SavedGameStore` and `RecordStore` (in-memory stores, which
  hold encoded bytes and accept damaged ones, for tests and previews; the router defaults to
  them). The engine encodes `GameState` and rejects states the rules could not reach.
  `GameSession` sends `saved` after every turn and undo and `ended` once when a game ends
  (`onEvent`), and offers `snapshot` (the start of the computer's turn while that turn is under
  way) and `result` (`GameSession+Saving.swift`); the router saves on `saved`, on Home and when
  `CheckersApp` sees the scene go to the background, clears the save and records the result on
  `ended`. Leaving a game returns Home at once and keeps it saved (E3's leave alert is gone);
  Start asks "Abandon current game?" while a game is saved. At launch an unreadable save is
  cleared and an unreadable record restarts from zero, each reported once on Home
  (`restoreNotice`, shown one at a time from a `.task(id:)`). A new format needs a new version:
  `StorageTests` keeps version 1 fixtures.
- Settings, themes, sound and rules (E6, `../specs/007-settings-themes-sound-and-rules/contracts/`):
  three settings in `UserDefaults.standard` under `boardTheme`, `soundEffects` and `moveHints`,
  read per key (an unreadable one takes its default, logged under `Log.settings`, no alert) by
  `UserDefaultsSettingsStore`; `AppSettings` (`@Observable`) is created by the router and handed
  to every session, so a change applies at once, also mid-game; with hints off `hintedPieces` and
  `targets` are empty. Themes are namespaced asset folders (`Classic/`, `Modern/`, `Playful/`,
  12 colors each) read through `Palette.color(in:)` and the `boardTheme` environment value that
  `RootView` sets; `BoardPicture` draws still boards in the current theme (the Rules pictures,
  built through the engine, and the Settings previews). Settings' theme rows are buttons with the
  selected trait, not an inline picker (whose merged rows fail the contrast audit). Rules is one
  scroll view of seven sections from `RulesContent`, whose texts `US2RulesTests` checks word for
  word against `rules-content.md`. Sounds: four WAV files
  generated by `scripts/make-sounds.py` (seeded, standard library; `--check` holds the committed
  files to their recipes and runs in the script tests); a `SoundBank` actor plays them in the
  `.ambient` session behind `AudioSoundPlayer` (`RecordingSoundPlayer` in tests and previews);
  `GameSession` plays one per step and resignation while sound effects are on
  (`GameSession+Sound.swift`), and Settings says "Sound effects aren't available right now."
  while `AppRouter.showsSoundNotice`. UI tests pass settings as typed launch arguments,
  `launch(settings:)` (property-list forms such as `<false/>`; a plain `NO` reads as text), and
  turn switches with `setSwitch(_:isOn:)`; a test that changes a setting puts it back.
- VoiceOver (E7, `../specs/004-accessibility/contracts/announcements.md`): each dark square is one
  element labelled by `GameSession.squareLabel(_:)` with its `SquareState` ("c3, Light man, can
  move"); double-tap uses the tap path. `GameSession` speaks through the `Announcer` seam
  (`AccessibilityAnnouncer` in the app, `RecordingAnnouncer` in tests): exactly one announcement
  per step, undo or resignation, built from `GameText`, plus the capture-required notice; selecting
  is silent. `focusSquare` moves VoiceOver focus to each step's landing square.
- Views are thin: rules come from the engine, interaction rules from `GameSession`, navigation from
  `AppRouter`. Board colors come only from `Support/Palette.swift` (asset colors with light and
  dark variants, one folder per theme); every piece and mark keeps at least 3:1 contrast with
  what it is drawn on in every theme (`US4ContrastTests`), and kings differ by a side-specific
  crown. Nothing on the board animates.
- Every screen passes `US5AccessibilityAuditUITests` (all audit types). The audit fails secondary
  text, system blue and text over translucent backgrounds: use primary text, the app's
  `AccentColor` and `OnAccent` (label of prominent buttons), and opaque panels. Exceptions only for
  system components, in the audit's `isAllowed` and the allow-lists in
  `../specs/004-accessibility/plan.md`, `../specs/006-saving-and-statistics/plan.md` and
  `../specs/007-settings-themes-sound-and-rules/plan.md` (the setup and Settings forms' edge
  rows; the texts of system alerts). Audit screens at rest, not at an arbitrary scroll
  position: text left under the navigation bar fails the contrast check.
- Confirmations are alerts: on iOS 26 a confirmation dialog opened from a toolbar item shows as a
  popover without Cancel.
- `checkers/Support/Logging.swift`: `Log` with one `Logger` per feature category under the bundle
  identifier. Never use `print`.
- `checkers/Localizable.xcstrings`: every user-facing string, as whole sentences. Building in Xcode
  updates it; after command-line builds run `scripts/sync-string-catalog.sh`. CI fails if it
  drifts (`scripts/check-string-catalog.sh`). Return optional strings from a `switch` with explicit
  `return`s: from a `switch` expression the compiler extracts only one literal.
- `checkers/PrivacyInfo.xcprivacy`: no tracking and no collected data; declares the user-defaults
  API (reason `CA92.1`) for the remembered setup choices, the saved game, the record and the
  settings. Add any
  new required-reason API in the same change that starts using it.
- `CheckersEngine/`: UI-free Swift package (Swift 6, iOS 26.2 and macOS 15 for host tests); lint
  fails on UI imports in it. It holds the American checkers rules as `Sendable` value types:
  `Square` (a–h / 1–8 names), `Piece`, `Position` (three 32-bit sets), `Step` (from, to; two
  squares long is a jump) and `GameState`, whose `apply(_:)` returns a `StepResult`, plus
  `resign(_:)`, `undo()` and the legal-step queries. Rejections throw `RuleError`. `GameState` is
  `Codable` (`GameState+Coding.swift`: explicit keys; damaged data throws
  `DecodingError.dataCorrupted`). The public API and its rules are in
  `../specs/002-rules-engine/contracts/engine-api.md`.
- The computer player (E4, `../specs/005-computer-opponent/contracts/computer-player.md`):
  `ComputerPlayer.chooseTurn(in:level:seed:shouldStop:)` searches complete turns with alpha-beta
  and iterative deepening (`Search`, `Evaluation`) over its own allocation-free `TurnGenerator`,
  held to `GameState` by the published counts and a 1,000-position cross-check; the root turns
  and every step played go through `GameState`. `ComputerLevel` sets depth, node limit and random
  margin (research R4); `SeededGenerator` (SplitMix64) makes choices repeat by seed. The engine
  has no clocks: the app's `shouldStop` adds the time limit.
- The computer's turn in the app (`../specs/005-computer-opponent/contracts/computer-turn.md`):
  `GameSession` plays it as a task through two injected seams, `ComputerOpponent`
  (`EngineComputerOpponent` searches in a `@concurrent` function with a 0.8 s limit;
  `ScriptedComputerOpponent` for tests and previews) and `TurnPacer` (`SleepingPacer`;
  `ManualPacer` in tests). `computerPhase` locks the board; the next step waits while
  `ScreenCover` says Rules or Settings covers the game (the router sets it from its path); undo
  goes back to the player's turn and resign cancels the turn first. Display queries live in
  `GameSession+Display.swift`.
- Engine tests (`CheckersEngine/Tests/CheckersEngineTests/`): one suite per story
  (`US1StartAndMoveTests`…`US5UndoTests`) whose test names list the FRD IDs they prove; unit
  suites for squares, positions and steps; `ReferenceCountTests` (published move counts, depths
  1–7; the 6-turn count's speed check times the counting thread's CPU time, so tests running in
  parallel cannot fail it) and `RandomGameTests` (1,000 seeded games with full undo). Helpers in
  `Support/` build positions from square names, for example
  `GameState(["c3": .lightMan], toMove: .light)`. E4 adds
  `TurnGeneratorTests`, `US1ComputerPlayerTests` and `US2ComputerLevelTests` (shallow searches:
  these run in Debug in the blocking plan). `CheckersEngineStrengthTests` (Release only, not in
  the Xcode test plan) plays 100-game matches between the levels and the counts to 9 turns. E5
  adds `GameStateCodingTests` (round trips, every validity rule, a version 1 fixture).
- Targets: app `checkers`, `checkersTests` (Swift Testing, MainActor default isolation; suites
  `US1TwoPlayerMoveTests`…`US7NavigationTests` (E3), `US1SquareDescriptionTests`…
  `US4ContrastTests` (E7), `US1ContinueTests`…`US4RestoreFailureTests` and `StorageTests` (E5),
  `SettingsStoreTests`, `US1SettingsTests`, `US2RulesTests`, `US3ThemeTests`, `US4SoundTests` and
  `US4SoundPlaybackTests` (E6), plus layout, palette, privacy and localization;
  `Support/GamePositions.swift` builds positions through the engine's public API and
  `Support/ScriptedGames.swift` holds the scripted games the announcement tests replay; mark
  parameterized-test arguments `nonisolated`),
  `checkersUITests` (XCUITest, nonisolated default; mark tests `@MainActor`; one class per story;
  `Support/AppScreens.swift` finds elements by the identifiers in `screens.md`; alert buttons by
  label, as XCUITest does not see their identifiers). Saved games and the record outlive each UI
  test and cannot be reset: the start helpers and `tapStart()` answer "Abandon current game?",
  tests compare counts before and after, and known data comes from `UserDefaults` launch
  arguments: `launch(replacing:with:)` passes `-savedGame <hex>` or `-record <hex>` (JSON text as
  bytes, for this launch only; `StoredValues` holds the records), and the plain argument
  `-savedGame none` reads as no saved game. Acceptance tests
  name their story ID (`US1`…). Test plans: `checkers.xctestplan` (blocking) and
  `Performance.xctestplan` (launch timing).
- The project uses **file-system synchronized groups** (`objectVersion = 77`): files dropped into a
  target's folder join that target without `project.pbxproj` edits.

## Rules enforced on every build and in CI

- SwiftLint 0.65.1 through the `SwiftLintPlugins` package plugin, configured in `.swiftlint.yml`
  (errors: force unwrap family, `ObservableObject`/`@Published`, Combine, `DispatchQueue`/
  `OperationQueue`/`Thread`, `print`). Test folders relax the force-unwrap family and `print`.
  `identifier_name` also accepts `to` (`Step.to`). Both the Xcode build and `swift test` run the
  plugin.
- swift-format (bundled with Xcode) with `../.swift-format`: warnings locally, errors in CI.
- CI (`../.github/workflows/ci.yml`): pushes to any branch except `main`; Markdown-only pushes
  skip build and tests. Code pushes run `build-and-test` and, in parallel, `engine-strength`
  (the strength matches in Release); the `CI gate` job is the required check and needs both.
  Land work on `main` by fast-forward after the branch is green; no pull requests.
