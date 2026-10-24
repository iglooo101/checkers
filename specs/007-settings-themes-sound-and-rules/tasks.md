---

description: "Task list for the settings, themes, sound and rules slice (epic E6)"
---

# Tasks: Settings, Themes, Sound and Rules

**Input**: Design documents from `/specs/007-settings-themes-sound-and-rules/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/settings-and-sound.md, contracts/screens.md, contracts/rules-content.md, quickstart.md

**Tests**: Tests are MANDATORY (Constitution III). App logic is tested with Swift Testing in `checkers/checkersTests/` against the in-memory settings store and the recording sound player (Constitution III.4), the `UserDefaults` store against a temporary suite; the running app with XCUITest in `checkers/checkersUITests/`, with settings set through typed `UserDefaults` launch arguments (research R10); the sound recipes with a script test. Suites are named `US<n>…Tests`, display names start with the story ID and list the FRD IDs they prove, and UI test methods are named `testUS<n>_…`. Test tasks come before the implementation tasks they cover and must be observed failing (or failing to compile) before implementation begins.

**Organization**: Tasks are grouped by user story. A test task is complete together with the implementation tasks it covers (red, then green): no commit or push is ever red, so every completed task leaves the app building and all tests passing (Constitution workflow gate 3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Shorthands: `App/` is `checkers/checkers/`, `Unit/` is `checkers/checkersTests/`, `UI/` is `checkers/checkersUITests/`.

## Conventions used by every task

- As in E3 to E5: `scripts/test.sh` runs everything with SwiftLint; one suite with `-only-testing`; sync the catalog with `scripts/sync-string-catalog.sh` after string changes and keep `Unit/LocalizationTests.swift`'s `screenStrings` in step with contracts/screens.md and contracts/rules-content.md; previews in light, dark and `accessibility5`, built with `InMemorySettingsStore` and `RecordingSoundPlayer` only (workflow gate 4: previews never touch storage or play sound); no force unwraps outside tests; no test-only behavior in the app; commit failing tests with their implementation; push once per story and wait for CI; move board tasks to In Progress before a story and Done after its CI (summaries with `gh issue comment`).
- Stored settings, hints, themes and sounds follow [contracts/settings-and-sound.md](contracts/settings-and-sound.md); texts and identifiers [contracts/screens.md](contracts/screens.md); the Rules content [contracts/rules-content.md](contracts/rules-content.md). Texts are checked as resolved English strings.
- `GameSession`'s class body stays within SwiftLint's 250 lines: new session behavior goes in extensions in `GameSession.swift` (E4 lessons). New initializer parameters get defaults, so the 46 existing constructions stay as they are.
- UI tests that change a setting through the screen put it back before they end, as settings outlive each test (research R10).

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Create `specs/007-settings-themes-sound-and-rules/checklists/validation.md` with one section per quickstart scenario (1–7), a "Baseline" section (`scripts/test.sh` passes before any slice code: record the count) and the measurements of research "Environment facts", R4 (contrast), R6 (sounds) and R7 (players), with the date and the Mac.
- [X] T002 [P] Add the `settings` and `sound` categories to `App/Support/Logging.swift` (`Log.settings`, `Log.sound`) and to `Unit/LoggingTests.swift` (categories `["app", "game", "setup", "computer", "storage", "settings", "sound"]`), test first. Add `@Test("US4 FR-PRIV-02: the app asks for no permission")` to `Unit/PrivacyManifestTests.swift`: the app bundle's `Info.plist` has no key ending in `UsageDescription` (sound playback needs none, FR-024), so every FRD ID of the slice is named by a test (SC-009).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The stored settings and the observed settings object, used by every story (#140).

- [X] T003 [P] Write `Unit/SettingsStoreTests.swift` (`struct SettingsStoreTests`), each `UserDefaults` test on its own `UserDefaults(suiteName:)`, removed afterwards:
  - `FR-SET-02 FR-SET-04 FR-AID-04` (FR-002): nothing stored → `SettingsValues.defaults`, which is `.classic`, sound effects on, move hints on.
  - `FR-SET-03` (FR-004): `UserDefaultsSettingsStore` save then load gives equal values for every combination of theme, sound and hints; the keys are exactly `boardTheme` (a string `"classic"`, `"modern"` or `"playful"`), `soundEffects` and `moveHints` (booleans).
  - FR-005: each key on its own: `boardTheme` set to `"wooden"`, to `42` or to a boolean, `soundEffects` set to `"NO"` or to `3.5`, `moveHints` set to a string, each give that setting's default while the other two keep their stored values; missing keys give their defaults.
  - `InMemorySettingsStore` gives the same answers, also when given raw stored objects.
  - `FR-SET-03` (FR-003, FR-004): `AppSettings(store:)` starts with the stored values; setting `boardTheme`, `soundEffects` or `moveHints` saves it through the store at once (a new `AppSettings` over the same store reads it).
  - `BoardTheme.allCases == [.classic, .modern, .playful]`, raw values `"classic"`, `"modern"`, `"playful"`.
  Fails to compile until T004.
- [X] T004 Create, per data-model.md, `App/Features/Settings/BoardTheme.swift` (`String`-backed, `CaseIterable`, `nonisolated`, `Sendable`; the three cases only: its `name` and their catalog strings come with US3 in T020, since E3's `prototypeStringsRemoved` forbids them until T017 changes it), `App/Features/Settings/SettingsStore.swift` (`SettingsValues`, `Equatable`, `nonisolated` and `Sendable`, with `static let defaults`; protocol `SettingsStore` with `load() -> SettingsValues` and `save(_:)`; `UserDefaultsSettingsStore(defaults:)` reading each key with `object(forKey:)`, logging an unreadable value with `Log.settings` without the value, writing only changed keys; `InMemorySettingsStore`, which can hold raw objects) and `App/Features/Settings/AppSettings.swift` (`@Observable final class`, saving each change). T003 passes.
- [X] T005 Add `settingsStore: any SettingsStore = InMemorySettingsStore()` to `AppRouter.init` in `App/App/AppRouter.swift`, which builds `settings: AppSettings` from it; pass `UserDefaultsSettingsStore(defaults: .standard)` in `App/CheckersApp.swift`; unused so far.

**Checkpoint**: `scripts/test.sh` passes; nothing user-visible has changed.

---

## Phase 3: User Story 1 - Turn move hints off and on (Priority: P1) 🎯 MVP

**Goal**: Settings replaces its placeholder with the move hints switch, which applies at once, also in the game in progress, and is kept (#140, #141; FR-001, FR-003 to FR-007).

**Independent Test**: `-only-testing:checkersTests/US1SettingsTests -only-testing:checkersTests/US7NavigationTests -only-testing:checkersUITests/US1SettingsUITests -only-testing:checkersUITests/US7NavigationUITests`.

### Tests for User Story 1 (MANDATORY - write first) ⚠️

- [X] T006 [P] [US1] Write `Unit/US1SettingsTests.swift` (`struct US1SettingsTests`), through `GameSession` and `AppRouter` with in-memory stores, a scripted opponent and a manual pacer:
  - `US1 FR-AID-01 FR-AID-02 FR-AID-04`: with hints on (the default), `hintedPieces` and `targets` are as in E3 (the start's four movable men; c3 selected → b4, d4).
  - `US1 FR-AID-01 FR-AID-02` (FR-006): with `moveHints` off, `hintedPieces` and `targets` are empty at the start, with a piece selected, when a capture is required and during a chain.
  - `US1 FR-AID-03` (FR-007): with hints off, selecting c3 still sets `selection`, tapping d4 moves it, a chain keeps its piece selected and locked, tapping a piece that cannot capture still sets the capture-required notice and the turn text still says "capture required", and `squareLabel` of every square is the same as with hints on.
  - `US1 FR-SET-03` (FR-003): turning hints off and on in the middle of a game changes `hintedPieces` at once and leaves the state, selection, undo history and `canUndo` unchanged; the same while the computer's turn waits under Settings.
  - `US1 FR-SET-03` (FR-004): the router hands its `AppSettings` to the sessions of `open(gameWith:)`, `playAgain()` and `continueGame()`; changing a setting changes neither the saved game, the record nor the setup choices.
  Fails to compile until T009.
- [X] T007 [P] [US1] Add `launch(replacing values: KeyValuePairs<String, String> = [:], settings: KeyValuePairs<String, String>)` to `UI/Support/AppScreens.swift`: E5's `-key <hex>` arguments plus each setting as `-key value` with the property-list forms of contracts/settings-and-sound.md (`modern`, `<false/>`, `<true/>`). Write `UI/US1SettingsUITests.swift`:
  - `testUS1_launchArgumentSetsHints` (confirms research R10 in the simulator first): launch with `-moveHints <false/>`; Home → Settings: `settings.moveHints` reads off. If it reads on, revise R10 and the tasks that use settings arguments (T018, T024, T029) before going on.
  - `testUS1_settingsFromHome`: Home → Settings shows `settings.moveHints` and returns to Home. (The game menu's path is `testUS7_rulesAndSettingsReturnToTheGame`, rewritten in T008.)
  - `testUS1_hintsKeptAfterRelaunch`: launch with no arguments; Settings: turn Move hints off; `terminate()` and `launch()`; Settings: off; turn it back on.
  Fails until T010.
- [X] T008 [US1] Rewrite the Settings placeholder tests: in `UI/US7NavigationUITests.swift`, `testUS7_rulesAndSettingsReturnToTheGame` waits for `settings.moveHints` after Settings (Rules keeps `placeholder.message` until US2); `testUS5_auditSettings` in `UI/US5AccessibilityAuditUITests.swift` waits for `settings.moveHints`; `placeholderMessages` in `Unit/US7NavigationTests.swift` expects no message for `.settings`; in `Unit/LocalizationTests.swift` drop "Board theme, sound effects and move hints will be set here." and add "Move hints" and its footer. Fails until T010.

### Implementation for User Story 1

- [X] T009 [US1] Add `settings: AppSettings = AppSettings(store: InMemorySettingsStore())` to `init(setup:…)` in `App/Features/Game/GameSession.swift` and to `init(saved:…)` in `App/Features/Game/GameSession+Saving.swift`; in `App/Features/Game/GameSession+Display.swift` return empty `hintedPieces` and `targets` while `settings.moveHints` is off (contracts/settings-and-sound.md, "Move hints"; update their comments: hints are no longer always on); in `App/App/AppRouter.swift` pass `settings` to the sessions of `open(gameWith:)` and `continueGame()`.
- [X] T010 [US1] Create `App/Features/Settings/SettingsView.swift`: a form titled Settings with the Game section's Move hints toggle (`settings.moveHints`) and its footer, per contracts/screens.md, bound to `AppSettings`; previews in light, dark and `accessibility5`, with hints on and off. Open it for `.settings` in `App/App/RootView.swift`; remove the Settings line from `App/Features/Placeholders/PlaceholderText.swift`; sync the catalog. T006–T008 pass; all tests pass.

**Checkpoint**: US1 complete: hints can be turned off, at once and for good.

---

## Phase 4: User Story 2 - Learn the rules in the app (Priority: P2)

**Goal**: Rules replaces its placeholder with one scrolling page of seven sections and their pictures, from Home and the game menu (#150, #151; FR-020 to FR-023, FR-025).

**Independent Test**: `-only-testing:checkersTests/US2RulesTests -only-testing:checkersTests/US7NavigationTests -only-testing:checkersUITests/US2RulesUITests -only-testing:checkersUITests/US7NavigationUITests -only-testing:checkersUITests/US5AccessibilityAuditUITests/testUS5_auditRules`.

### Tests for User Story 2 (MANDATORY - write first) ⚠️

- [X] T011 [P] [US2] Write `Unit/US2RulesTests.swift` (`struct US2RulesTests`):
  - `US2 FR-HELP-01` (FR-020): `RulesContent.sections` has the ids `board`, `moving`, `capturing`, `chains`, `kings`, `ending`, `undoResign` in that order, with the titles "The board", "Moving", "Capturing", "Jumping again", "Kings", "Winning and drawing", "Undo and resign", and each text equal to contracts/rules-content.md.
  - `US2 FR-HELP-01` (FR-021, FR-022): every board picture is rebuilt with the engine's public API and its "Checked" claim holds: c3's targets in the starting position are b4 and d4; the capture position requires a capture, only c3 can move, to e5; the chain's first step continues the turn, its second picture is the state after c3–e5 with e5 the chain square and g7 its only target; the king on d4 has the four targets; Dark has no legal step in the ending position. In each picture with a selected piece, the drawn targets equal the engine's `targets(from:)` of that piece and the hinted pieces its `movablePieces` (the Moving picture: a3, c3, e3 and g3, c3 showing its selection ring); pictures without a selected piece (the board, the ending) have no marks.
  - `US2` (FR-021): the six rules sections each have at least one board picture, the chain section two; `undoResign` has the menu illustration and no board; every picture has its description from the contract.
  - `US2` (SC-006): the section texts total at most 600 words (364 in the contract).
  Fails to compile until T014–T015.
- [X] T012 [P] [US2] Write `UI/US2RulesUITests.swift`: `testUS2_rulesFromHome`: Home → Rules: `rules.board.title` reads "The board", `rules.board.picture` exists, and scrolling reaches `rules.undoResign.picture`; back returns to Home. `testUS2_rulesFromGameMenu`: a computer game (Easy, Light), move c3–d4, game menu → Rules while the computer thinks, back: the computer's move follows and d4 reads "d4, Light man". Rewrite the Rules placeholder tests: `testUS7_rulesAndSettingsReturnToTheGame` waits for `rules.board.title` after Rules; `testUS7_placeholdersFromHome` becomes `testUS7_rulesAndSettingsFromHome` (each opens its screen, `rules.board.title` and `settings.moveHints`, and returns); `testUS5_auditRules` waits for `rules.board.title`. Fails until T015.
- [X] T013 [US2] In `Unit/US7NavigationTests.swift` delete `placeholderMessages` (no placeholder is left); in `Unit/LocalizationTests.swift` drop "How to play American checkers will be explained here." and add the seven titles, seven texts, eight picture descriptions and "Undo"/"Resign" of contracts/rules-content.md. Fails until T015.

### Implementation for User Story 2

- [X] T014 [US2] Create `App/Features/Game/BoardPicture.swift` per data-model.md and research R5: a static board, or the part given by `rows` and `columns` (from Light's side), drawing squares with `Palette` and pieces with `PieceView`, the selected piece's ring, hint rings and target dots as `BoardView` does; no gestures; one accessibility element with the image trait and the given description. Previews: a whole board with every mark and a 4 × 4 corner, in light and dark.
- [X] T015 [US2] Create `App/Features/Rules/RulesContent.swift` (`RulesSection`, `RulesPicture` with `.board(state:selected:description:)` and `.menu`; the seven sections of contracts/rules-content.md, positions built through `GameState(position:sideToMove:)` and `apply(_:)`; for a picture with a selected piece, targets from `targets(from:)` and hint rings from `movablePieces`, as the game draws them with hints on) and `App/Features/Rules/RulesView.swift` (one scroll view titled Rules: per section a heading with the header trait, its text and its pictures at the text column's width up to 320 points; the menu illustration with `arrow.uturn.backward` "Undo" and `flag` "Resign" in primary text; identifiers per contracts/screens.md; previews in light, dark and `accessibility5`). Open it for `.rules` in `App/App/RootView.swift`; delete `App/Features/Placeholders/` (both files) and the `placeholder(…)` helper; sync the catalog. T011–T013 pass; all tests pass.

**Checkpoint**: US2 complete: the rules are in the app.

---

## Phase 5: User Story 3 - Choose a board theme (Priority: P2)

**Goal**: Classic, Modern and Playful, chosen in Settings with previews, draw the board everywhere, in light and dark, with every mark at 3:1 or more (#144, #145; FR-008 to FR-013).

**Independent Test**: `-only-testing:checkersTests/US3ThemeTests -only-testing:checkersTests/US4ContrastTests -only-testing:checkersTests/PaletteTests -only-testing:checkersUITests/US3ThemeUITests`.

### Tests for User Story 3 (MANDATORY - write first) ⚠️

- [X] T016 [P] [US3] Rewrite `Unit/US4ContrastTests.swift` to run its 8 pairs for every `BoardTheme` in light and dark (`arguments: pairs, BoardTheme.allCases` and both styles, or a combined argument list), reading `Palette.assetName(in:)`; the display name gains `FR-SET-02`. Rewrite `Unit/PaletteTests.swift`: every color of every theme resolves in light and dark (`US3 FR-GAME-07`). Fail to compile until T019.
- [X] T017 [P] [US3] Write `Unit/US3ThemeTests.swift` (`struct US3ThemeTests`):
  - `US3 FR-SET-02` (FR-008): the names "Classic", "Modern", "Playful"; `Palette.boardDarkSquare.assetName(in: .modern) == "Modern/BoardDarkSquare"`.
  - `US3 FR-GAME-07`: Classic's 12 colors resolve to E7's values in light and dark (research environment facts), so moving them changed nothing; Modern's and Playful's resolve to research R4's table in light and dark.
  - `US3 FR-GAME-07` (FR-009): the environment's `boardTheme` defaults to `.classic`.
  In `Unit/LocalizationTests.swift`, `prototypeStringsRemoved` checks only "Play" and "Screen", and `screenStrings` gains "Board theme", "Classic", "Modern", "Playful". Fails until T019–T020.
- [X] T018 [P] [US3] Write `UI/US3ThemeUITests.swift`: `testUS3_themeChoices`: launch with `-boardTheme classic`; Settings shows `settings.theme.classic` selected and `settings.theme.modern` and `settings.theme.playful` not. `testUS3_themeKeptAfterRelaunch`: launch with no arguments; Settings: choose Modern; `terminate()` and `launch()`; Settings: Modern is selected; choose Classic again. `testUS3_themedGame` (a smoke test: UI tests cannot see colors, which T016 and T017 check): launch with `-boardTheme playful`, start a two-player game and select c3: the board and `square.c3` ("c3, Light man, selected") are there. Fails until T020.

### Implementation for User Story 3

- [X] T019 [US3] In `App/Assets.xcassets`, move the 12 board colorsets into a `Classic` folder whose `Contents.json` has `"provides-namespace": true`, values unchanged; add `Modern` and `Playful` folders the same way with research R4's colors and dark variants. In `App/Support/Palette.swift` add `assetName(in:)` and `color(in:)` (replacing `color`), and the environment value `boardTheme` (default `.classic`); `App/Features/Game/BoardView.swift`, `PieceView.swift` and `BoardPicture.swift` read the theme from the environment, and `ResultPanel.swift`'s previews use `Palette.boardDarkSquare.color(in: .classic)`; `App/App/RootView.swift` sets it from `router.settings.boardTheme`. Add "Every mark" previews of `BoardView` in Modern and Playful, light and dark. T016 passes; T017's color cases pass.
- [X] T020 [US3] Add `BoardTheme.name` ("Classic", "Modern", "Playful" as `LocalizedStringResource`) in `App/Features/Settings/BoardTheme.swift`. In `App/Features/Settings/SettingsView.swift` add the Board theme section first: an inline picker of the three themes, each row a `BoardPicture` preview per contracts/screens.md (the 4 × 4 corner with Dark men on b8 and d8, a Dark king on a7, a Light man on c5 and a Light king on b6; hidden from VoiceOver) and the theme's name, identifiers `settings.theme.<raw value>`; previews per theme and at `accessibility5`; sync the catalog. T017 and T018 pass; all tests pass. Built as one button per theme with the selected trait instead of an inline picker, whose merged rows failed the contrast audit (research R11, "Found in US3"; contracts/screens.md).
- [ ] T021 [US3] Visual review (FR-012, quickstart §4): show the user the board previews and simulator screenshots of a game in Modern and Playful, light and dark, beside the prototype's designs (`git show e3c0c2b^:checkers/checkers/Modern.html`); record the approval, or the requested colors, in `validation.md`. A requested change updates research R4's table, `Assets.xcassets` and T017's pinned values, and `US4ContrastTests` must still pass.

**Checkpoint**: US3 complete: three themes, everywhere the board is drawn.

---

## Phase 6: User Story 4 - Hear the game (Priority: P3)

**Goal**: Four original sounds, one per step of either side and at every ending, following silent mode and volume, switchable in Settings (#147, #148; FR-014 to FR-019, FR-024).

**Independent Test**: `scripts/tests/run.sh`, then `-only-testing:checkersTests/US4SoundTests -only-testing:checkersTests/US4SoundPlaybackTests -only-testing:checkersUITests/US4SoundUITests`.

### Tests for User Story 4 (MANDATORY - write first) ⚠️

- [X] T022 [P] [US4] Write `scripts/tests/test-make-sounds.sh` and add it to `scripts/tests/run.sh`: `python3 scripts/make-sounds.py --check` passes on the committed files; copies of them in a temporary directory with one sample changed by two steps, with a file missing, or with a different length make `--check <dir>` fail with the file's name. Fails until T025.
- [X] T023 [P] [US4] Write `Unit/US4SoundTests.swift` (`struct US4SoundTests`), through `GameSession` with a `RecordingSoundPlayer`, in-memory settings, a scripted opponent and a manual pacer:
  - `US4 FR-SND-01` (FR-014): `SoundEffect.of` gives `.move` for a plain step, `.capture` for a capture, `.crowning` for a move or capture that crowns, and `.gameEnd` for a last step that ends the game by no moves left (plain, capturing or crowning) and for one that ends it by a draw rule.
  - `US4 FR-SND-01`: a two-player game replayed from `Support/ScriptedGames.swift` plays exactly one effect per step, equal to `SoundEffect.of` of its result, in order; a double jump plays `.capture` twice.
  - `US4 FR-SND-01`: in a computer game, each of the computer's steps plays its effect when it appears: after each release of the manual pacer, exactly one more effect.
  - `US4` (FR-015): a resignation plays `.gameEnd` once; resigning a finished game plays nothing.
  - `US4 FR-SND-03` (FR-018): undo, selecting, a refused tap or drop, the capture-required notice, the computer's thinking and continuing a saved game play nothing; when a continued game resumes the computer's turn, only its steps play, each its own effect.
  - `US4 FR-SET-04` (FR-017): with `soundEffects` off, none of the above plays anything; turning it on in the middle of a game makes the next step play.
  - `US4 FR-SND-02` (FR-016): `SoundBank.category` is `.ambient`.
  - `US4` (FR-019): the four files are in the app bundle under `SoundEffect`'s file names and load as audio; `move`, `capture` and `crowning` last at most 0.5 s, `gameEnd` at most 2 s.
  - `US4 FR-SND-05` (FR-017): a `SoundBank` over a temporary directory without `capture.wav` throws `.missingFile(.capture)` from `prepare()` and stays unprepared; with text in `move.wav`, `.unreadableFile(.move)`; once the four bundled files are copied in, the next `prepare()` succeeds; `mediaServicesWereReset()` leaves it unprepared. An `AudioSoundPlayer` over the directory without `capture.wav` turns `isAvailable` false once its preparation fails (`waitUntil`). Run these on CI early: if preparing the bundled files fails on its simulator, the success case checks loading only.
  - `US4 FR-SND-05` (FR-017): with a `RecordingSoundPlayer`, `AppRouter.showsSoundNotice` is true only while sound effects are on and `isAvailable` is false, and goes when `isAvailable` is true again or sound effects are turned off.
  In `Unit/LocalizationTests.swift` add "Sound effects" and "Sound effects aren't available right now." to `screenStrings`.
  Fails to compile until T026–T027.
  Done with three changes: the bank, player, notice and bundled-file tests are their own suite, `Unit/US4SoundPlaybackTests.swift` (SwiftLint's 250-line limit for a type body); `screenStrings` also gains the section header "Sound"; and E3's `Unit/NoWebContentTests.swift`, which allowed no `.wav` in the bundle (the prototype's `move.wav`), now requires exactly the four `SoundEffect` files, found by the full run.
- [X] T024 [P] [US4] Write `UI/US4SoundUITests.swift`: `testUS4_soundSwitch`: launch with `-soundEffects <true/>`; Settings: `settings.soundEffects` reads on; turn it off: it reads off; turn it on again. `testUS4_soundKeptAfterRelaunch`: launch with no arguments; turn Sound effects off; `terminate()` and `launch()`: off; turn it back on. Fails until T027.

### Implementation for User Story 4

- [X] T025 [US4] Create `scripts/make-sounds.py` from contracts/settings-and-sound.md ("Files" and "Recipe details", which describe research R6's prototype): standard library only, seed `20261023`, writing `move.wav`, `capture.wav`, `crowning.wav` and `gameEnd.wav` (16-bit mono, 44.1 kHz) into `App/Features/Sound/Sounds/`; `--check [dir]` regenerates in memory and fails, naming the file, when a sample differs by more than one step, a file is missing or a length differs. Run it and commit the four files; record their lengths, sizes and peaks in `validation.md`. T022 passes.
- [X] T026 [US4] Create, per data-model.md and contracts/settings-and-sound.md ("Playback"), `App/Features/Sound/SoundEffect.swift` (`nonisolated`, `Sendable`; the four cases, file names, `of(_:)`), `App/Features/Sound/SoundPlayer.swift` (protocol with `play(_:)` and `isAvailable`; `AudioSoundPlayer`, an `@Observable` class over a `SoundBank`, which starts its bank's preparation when created, hands each effect to it in a task, sets `isAvailable` from each outcome, logs each `SoundError` with `Log.sound`, and calls `mediaServicesWereReset()` on `AVAudioSession.mediaServicesWereResetNotification`; `RecordingSoundPlayer`, which keeps the effects and has a settable `isAvailable`, `true` by default) and `App/Features/Sound/SoundBank.swift` (actor; `init(directory:)`; `static let category = AVAudioSession.Category.ambient`; `prepare() throws(SoundError)` sets the category and loads one prepared `AVAudioPlayer` per effect; `play(_:) throws(SoundError)` waits for a running preparation, prepares again while unprepared, rewinds and plays, and discards the players when one does not start; `mediaServicesWereReset()`; `SoundError` `missingFile`, `unreadableFile`, `audioSession`, `playback`, `Equatable`, `nonisolated` and `Sendable`), per contracts/settings-and-sound.md, "When sounds cannot play".
- [X] T027 [US4] Add `sounds: any SoundPlayer = RecordingSoundPlayer()` to `init(setup:…)` in `App/Features/Game/GameSession.swift` and to `init(saved:…)` in `App/Features/Game/GameSession+Saving.swift`; in `applyStep` play `SoundEffect.of(result)` right after the announcement, and in `resign()` play `.gameEnd` when it ends the game, both only while `settings.soundEffects` is on. In `App/App/AppRouter.swift` add `sounds: any SoundPlayer = RecordingSoundPlayer()`, pass it to every session, and add `showsSoundNotice`; in `App/CheckersApp.swift` pass an `AudioSoundPlayer()` over the app bundle's sounds. In `App/Features/Settings/SettingsView.swift` add the Sound section between Board theme and Game: the toggle "Sound effects" (`settings.soundEffects`) and, while `showsSoundNotice`, the footer "Sound effects aren't available right now." (`settings.soundUnavailable`), with a preview that shows it (a `RecordingSoundPlayer` with `isAvailable` false); sync the catalog. T023–T024 pass; all tests pass. Done; the Sound section moved the Game section's header and footer to the screen's bottom edge, where the audit's Dynamic Type check reports the text the form cuts, as on setup: both scale at the largest size (checked on screen), so plan.md's "Audit allow-list" and the audit's `isAllowed` gained a Settings row.
- [ ] T028 [US4] Listening review (FR-019, quickstart §5, first bullet): play the four files to the user with `afplay`; record the approval, or the requested changes, in `validation.md`. A change edits the recipe in `scripts/make-sounds.py`, regenerates the files (T022 and T023's lengths must still pass) and is played again.

**Checkpoint**: US4 complete: the game can be heard.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T029 [P] Update `UI/US5AccessibilityAuditUITests.swift` for FR-026: audit Settings (all three sections), Settings at the largest accessibility size (`-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`), Rules at its top and scrolled to `rules.undoResign.picture`, and a two-player game with c3 selected in Modern and in Playful (`-boardTheme modern`, `-boardTheme playful`). Run them and record every reported problem in `validation.md`.
- [ ] T030 Fix every problem T029 reports in `App/Features/`; add a plan "Audit allow-list" entry only for a system component (the form's toggles or picker). Run the audits on the iPhone SE (3rd generation) at `accessibility-extra-extra-extra-large` in Dark Mode; reset the simulator, and record the results.
- [ ] T031 Run `scripts/format.sh`, then confirm `scripts/check-format.sh --strict`, `scripts/tests/run.sh`, `scripts/check-string-catalog.sh checkers/checkers/Localizable.xcstrings .build/DerivedData` and `scripts/test.sh` pass with zero warnings and zero SwiftLint errors.
- [ ] T032 [P] Update `checkers/CLAUDE.md`: the Settings, Sound and Rules features; the three settings keys and their launch arguments for UI tests; `AppSettings` through the router to sessions; themes as namespaced asset folders and `Palette.color(in:)`; `BoardPicture`; the sound script and `--check`; the removed placeholders.
- [ ] T033 Run the quickstart (1 to 7) and record the results in `validation.md`, including the search for the slice's FRD IDs (SC-009) and the launch time against its baseline (SC-008); mark what is left for the user: the iPhone checks of §5 (delay, SC-004; silent mode and other apps' music, SC-005 and FR-016; the volume buttons, FR-016; a second sound over the first, FR-019) and the VoiceOver pass of §3 (headings, FR-025's header trait).
- [ ] T034 [P] Update `HANDOFF.md` (current state, lessons learned) and `EXECUTION_PLAN.md` (close-out checklist).
- [ ] T035 Final verification: push the branch, confirm `CI gate` is green with both jobs on the last commit, fast-forward `main`, and record the CI run in `validation.md`.
- [X] T036 Raise `build-and-test`'s `timeout-minutes` in `.github/workflows/ci.yml` from 30 to 45 (#204, added 2026-10-24 after CI run 40071432056 for US2 failed `CI gate` with every test passing: the job reached its limit during "Launch timing"; "Build and test" took 25 minutes against US1's 19, about 50 s of it US2's UI tests and the rest a slower runner). Done before US3's push; that push re-runs CI for US2's code.

---

## Dependencies & Execution Order

- **Setup (Phase 1)** and **Foundational (Phase 2)** first; Phase 2 blocks all stories (the store and `AppSettings`).
- **US1** next (P1, the MVP): the Settings screen and the hints switch. **US2** can follow US1 or run beside it (different files except `RootView.swift`, `LocalizationTests.swift` and the navigation UI tests, which both change). **US3** after US1 and US2: it adds the theme row to US1's Settings and themes US2's `BoardPicture`. **US4** after US1: it adds the sound row to Settings and the sound to `GameSession`; it does not need US2 or US3.
- **Polish** last; T029 sees every story's screens. T036 (the CI time limit) came first, before US3's push.
- Within a story: tests first and seen failing; implementation tasks in order. T021 and T028 wait for the user and do not block the next story.

### Parallel Opportunities

- T001 and T002; T003 alone (T004, T005 follow).
- US1: T006 and T007 (T008 edits existing test files beside them).
- US2: T011 and T012 (T013 beside them). US3: T016, T017 and T018. US4: T022, T023 and T024.
- T029, T032 and T034.

## Implementation Strategy

1. Phases 1–2, then US1: Settings with the move hints switch.
2. US2: the Rules screen; no placeholder is left.
3. US3: three themes, with previews; the user reviews them.
4. US4: the four sounds; the user listens to them.
5. Polish: audits, docs, quickstart, CI and the fast-forward of `main`.
6. After each story: `scripts/test.sh` green, push, CI green, update the board and `EXECUTION_PLAN.md`.

## Requirement Coverage

| FRD / spec IDs | Test tasks | Implementation tasks |
|---|---|---|
| FR-SET-01 · FR-001 (Settings with three settings) | T007, T018, T024 | T010, T020, T027 |
| FR-SET-02, FR-SET-04, FR-AID-04 · FR-002 (defaults) | T003 | T004 |
| FR-SET-03, FR-NAV-04 · FR-003 (at once, also mid-game) | T003, T006, T007 | T004, T009 |
| FR-SET-03 · FR-004 (kept; not in the saved game) | T003, T006, T007, T018, T024 | T004, T005, T009 |
| FR-005 (unreadable setting) | T003 | T004 |
| FR-AID-01, FR-AID-02 · FR-006 | T006 | T009 |
| FR-AID-03, FR-MOVE-05 · FR-007 | T006 | T009 |
| FR-SET-02 · FR-008 | T017, T018 | T019, T020 |
| FR-GAME-07 · FR-009, FR-010 | T016, T017, T018 | T019 |
| FR-A11Y-05 · FR-011 | T016 | T019 |
| FR-012 (the prototype's look; review) | T017 (pinned colors) | T019, T021 |
| FR-SET-02 · FR-013 (previews) | T018 | T020 |
| FR-SND-01 · FR-014, FR-015 | T023 | T026, T027 |
| FR-SND-02 · FR-016 | T023 (category); by hand: quickstart §5 (silent mode, volume, other apps' music) | T026 |
| FR-SET-04 · FR-017 (sound off) | T023 | T027 |
| FR-SND-05 · FR-017 (sounds unavailable: notice, retry) | T023 | T026, T027 |
| FR-SND-03, FR-SND-04 · FR-018 | T023 (E3's `FR-SND-04` test unchanged) | T027 |
| FR-019 (lengths, the app's own sounds) | T022, T023; by hand: quickstart §5 (a sound over the previous one) | T025, T028 |
| FR-HELP-01 · FR-020 to FR-022 | T011 | T014, T015 |
| FR-HELP-02, FR-NAV-04 · FR-023 | T012 | T015 |
| FR-PRIV-01, FR-PRIV-02 · FR-024 | T002, `PrivacyManifestTests` (manifest unchanged) | — |
| FR-A11Y-04 · FR-025, FR-026 | T011, T029; by hand: quickstart §3 (headings) | T010, T015, T020, T030 |
| FR-PLAT-03 · FR-027 | T008, T013, T017 (`LocalizationTests`) | T010, T015, T020, T027 |
| SC-001 | T006, T007, T018, T024 | T009, T010, T020, T027 |
| SC-002 | T016 | T019 |
| SC-003 | T023 | T027 |
| SC-004, SC-005 | By hand: quickstart §5 on an iPhone, for the user | T033 (records them) |
| SC-006 | T011 | T015 |
| SC-007 | T029 | T030 |
| SC-008 | T033 | — |
| SC-009 | T002, T033 | — |

## Board Mapping

Each board issue lists its task IDs and the FRD IDs of the spec's traceability table; #138 Reconcile added #203 for the slice's setup and validation (T001, T002, T029–T035), as #201 did for E5, blocked by the accessibility passes #142 and #152:

| Board task | Tasks |
|---|---|
| #140 Settings store with defaults, persisted behind a protocol | T003, T004, T005 |
| #141 Settings screen; changes apply immediately, including in a game in progress | T006–T010, T020 (theme row), T027 (sound row) |
| #142 Accessibility pass: Settings | T007, T008, T029, T030 |
| #144 Classic, Modern and Playful themes as asset-catalog colors with dark variants | T016, T017, T019, T021 |
| #145 Theme picker with board previews | T018, T020 |
| #147 Sound assets: move, capture, crowning, game end | T022, T025, T028 |
| #148 Sound service behind a protocol that respects silent mode and volume | T023, T024, T026, T027 |
| #150 Illustrated rules content | T011, T014, T015 |
| #151 Rules reachable from Home and the game menu | T012, T013, T015 |
| #152 Accessibility pass: Rules | T012, T029, T030 |
| #203 Validate the E6 slice and update project docs | T001, T002, T029–T035 |
| #204 Give CI's build-and-test job a 45-minute time limit (added 2026-10-24) | T036 |

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Verify tests fail before implementing
- Each acceptance test names its story ID (for example `US1`) in its display name or tag
- A test task completes together with the implementation tasks it covers; every commit leaves the app building and all tests passing
