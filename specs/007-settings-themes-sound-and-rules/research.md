# Research: Settings, Themes, Sound and Rules

Phase 0 output for `specs/007-settings-themes-sound-and-rules/plan.md`. Each entry records the
decision, why, and what else was considered. Facts marked *measured* were checked on the
development Mac (Intel Core i9-9980HK, 2.4 GHz, Swift 6.2.4, Xcode 26.3) on 2026-10-23 with
throwaway programs outside the repository.

## Environment facts

| Item | Value |
|---|---|
| Settings and Rules today | `Route.rules` and `Route.settings` open `PlaceholderView` with a line from `PlaceholderText` (E3 FR-003); Home (`home.rules`, `home.settings`) and the game menu (`game.menu.rules`, `game.menu.settings`) already open them, and `ScreenCover` holds the computer's next step while either covers the game (E4) |
| Hints today | `GameSession.hintedPieces` (every movable piece, none during the computer's turn) and `GameSession.targets` (the selection's legal targets) are always on (E3 FR-028); only `BoardView` draws them. VoiceOver states come from `state(of:)`, which reads the engine directly, so they already ignore any hints setting (E7 Clarifications) |
| Board colors | 12 asset colors (`Palette`), the Classic board: identical light and dark variants except `Hint` (`#E8C46A`, dark `#F0D27A`); `AccentColor` and `OnAccent` are app colors, not board colors. `US4ContrastTests` checks 8 pairs in light and dark: light piece on dark piece, light piece on dark square, dark piece's edge on dark square, selection, target (85% alpha, blended) and hint on dark square, each crown on its piece |
| The prototype's boards | In git history at `e3c0c2b^:checkers/checkers/{Classic,Modern,Playful}.html`. Modern: white `#FFFFFF` and near-black `#1C1C1C` squares, pieces `#FFFFFF` and `#111111`, no frame. Playful: cream `#FFF3D6` and sky-blue `#4CC9F0` squares, yellow `#FFD60A` and pink `#FF4D6D` pieces, purple `#2D1B4E` frame |
| Their contrast | Modern's dark piece on its square 1.11:1; Playful's yellow and pink pieces on their squares 1.36:1 and 1.67:1, and against each other 2.28:1 (*measured*, WCAG) |
| Sound today | None; the prototype's `move.wav` (25 KB, origin unknown) was deleted with the web screens in E3 |
| Session construction | `GameSession(` appears 46 times in the app and its tests; new initializer parameters need defaults |
| String Catalog | `LocalizationTests.prototypeStringsRemoved` expects "Classic", "Modern", "Play", "Playful" and "Screen" to be absent (E3 T054); `screenStrings` lists the two placeholder lines |
| Placeholder tests | `placeholderMessages` (`US7NavigationTests`); `testUS7_…` in `US7NavigationUITests` that open Rules and Settings from the menu and Home and wait for `placeholder.message`; `testUS5_auditRules` and `testUS5_auditSettings` wait for it too |
| Logging | Categories `app`, `game`, `setup`, `computer`, `storage`; `LoggingTests` checks the list |
| Script tests | `scripts/tests/run.sh` runs in CI's `build-and-test` job before the build; Python 3 is on the runners and the Mac (3.14.3) |

## R1. Where the settings are stored

- **Decision**: Three `UserDefaults` keys with plain values: `boardTheme` (a string: `classic`,
  `modern`, `playful`), `soundEffects` and `moveHints` (booleans), behind a `SettingsStore`
  protocol with a `UserDefaults` conformance and an in-memory one, like E3's setup store. Each key
  is read on its own: a missing key gives its default silently; a value of the wrong type or an
  unknown theme name gives its default and is logged (FR-005). A change writes only its key.
- **Rationale**: Three independent values make FR-005's per-setting fallback the natural reading,
  with nothing to version. Reading all three takes 2.4 µs (*measured*), so they are read on the
  main actor when the router is built, before the first frame, and the board never shows a
  default theme first (FR-009). `UserDefaults` is already declared in the privacy manifest
  (CA92.1).
- **Alternatives considered**: one JSON value like the setup store (rejected: FR-005 would need a
  hand-written decoder that tolerates each field separately, for three scalars); `@AppStorage` in
  views (rejected: writes from views, Constitution II.2, and no seam for tests); SwiftData
  (rejected: Principle VIII.3).

## R2. How settings reach the game

- **Decision**: One `@Observable` `AppSettings` (theme, sound effects, move hints), built by the
  router from the store and saving each change through it. The router hands it to every
  `GameSession` it creates; `RootView` puts the theme into the environment
  (`\.boardTheme`) for every board drawing; `SettingsView` binds to it.
- **Rationale**: Observation updates the board the moment a value changes, also while the game
  is under Settings (FR-003). The session decides what hints and sounds do, so the rules stay
  testable without views (Constitution II.2); the theme only changes colors, so the environment
  is enough.
- **Alternatives considered**: copying the values into each session (rejected: a change in
  Settings would have to be pushed to the session by hand); the theme in `AppSettings` read by
  every view (rejected: `PieceView` and the pictures would all need the settings object).

## R3. Move hints off

- **Decision**: With `moveHints` off, `GameSession.hintedPieces` and `GameSession.targets` are
  empty; everything else stays as it is: the selection and its mark (FR-AID-03), the chain lock,
  the capture-required notice and turn text, drags and drops (which check the engine's targets,
  not `targets`), and VoiceOver's square states (`state(of:)`).
- **Rationale**: The two properties are exactly what the board highlights (FR-AID-01, FR-AID-02),
  and only `BoardView` draws them, so nothing else changes.
- **Alternatives considered**: filtering in `BoardView` (rejected: a display rule in a view, and
  untestable without UI).

## R4. Theme colors

- **Decision**: Each theme has the same 12 board colors as Classic, as asset colors with light and
  dark variants in a namespaced folder of the asset catalog per theme (`Classic/`, `Modern/`,
  `Playful/`); Classic's current colors move into `Classic/` unchanged. Modern and Playful take
  their look from the prototype (FR-012) with these colors (light; dark only where it differs):

  | Color | Modern | Playful |
  |---|---|---|
  | Light square | `#FFFFFF` (dark `#D6D6D6`) | `#FFF3D6` (dark `#F2E3C2`) |
  | Dark square | `#1C1C1C` | `#1A639C` (dark `#17598C`) |
  | Frame | `#111111` | `#2D1B4E` |
  | Light piece · edge | `#FFFFFF` (dark `#F2F2F2`) · `#8E8E8E` | `#FFD60A` · `#B38600` |
  | Dark piece · edge | `#0A0A0A` · `#9A9A9A` | `#C2185B` · `#FFC2D1` |
  | Crown on Light · on Dark | `#111111` · `#FFFFFF` | `#2D1B4E` · `#FFF3A1` |
  | Selection · target (90%) | `#3FA9F5` · `#3FA9F5` | `#FFFFFF` · `#FFFFFF` |
  | Hint | `#BDBDBD` | `#B8F03C` |

  Every `US4ContrastTests` pair passes in both appearances (*measured*): Modern's weakest is the
  target at 5.64:1, Playful's the light piece on the dark piece at 4.16:1 (Classic's weakest stays
  the target at 3.64:1). Modern keeps a near-black dark piece and separates it from its square by
  a light edge, as Classic does; Playful's squares are a deeper blue than the prototype's, its
  dark side crimson instead of pink. The user approves both in a visual review (FR-012,
  quickstart §4).
- **Rationale**: The contrast test already measures asset colors by name, so a theme is the same
  set of names in another folder, and the test runs over themes × pairs × appearances. Dark
  variants differ only where white would glare in Dark Mode; a board is an object, so it keeps
  its colors otherwise, as E7 decided for Classic.
- **Alternatives considered**: colors in Swift code (rejected: Constitution V.1); a recolored
  copy of Classic's set (rejected: the prototype's looks are the requirement); the prototype's
  colors as they are (rejected: they fail FR-011, measured above).

## R5. Drawing a theme, and the small boards

- **Decision**: `Palette` keeps its cases and gains the theme: `Palette.boardDarkSquare.color(in:
  theme)` reads the asset `"<Theme>/<Name>"`. `BoardView` and `PieceView` read the theme from
  the environment. A new static `BoardPicture` view draws a position or part of it (a range of
  rows and columns) with given marks (a selected piece, hinted pieces, target squares) in the
  theme, with `PieceView`; it takes no input and is one VoiceOver image with a description. The
  Settings previews (a 4 × 4 corner with men and a king of both sides) and the Rules pictures
  (whole boards) are `BoardPicture`s.
- **Rationale**: One drawing of squares and pieces for the game, the previews and the pictures,
  so a theme looks the same everywhere (FR-013, FR-021). The pictures are not game sessions, so
  they cannot be played (FRD §19).
- **Alternatives considered**: images of the boards in the asset catalog (rejected: 3 themes × 2
  appearances × every picture, and they would drift from the real board); a `GameSession` per
  picture (rejected: it accepts taps and announces).

## R6. Generating the sounds

- **Decision**: `scripts/make-sounds.py` (Python 3, standard library only) writes the four sounds
  as 16-bit mono WAV at 44.1 kHz into the app (`Features/Sound/Sounds/`), from fixed recipes and a
  fixed random seed: *move*, a wooden click (a noise burst through resonators at 620 and 1,700 Hz
  plus a low thump); *capture*, two sharper clicks 70 ms apart; *crowning*, a two-note chime
  (C6, G6); *game end*, a rising three-note phrase (G5, C6, E6). Clicks peak at −3 dBFS, the
  tones at −6 dBFS, and every sound fades out over its last 8 ms. `make-sounds.py --check`
  regenerates them in memory and fails if any sample differs from the committed file by more than
  one step; `scripts/tests/run.sh` runs it, so CI catches a sound that no longer matches its
  recipe.
- **Measured** (prototype): durations 0.12 s, 0.22 s, 0.45 s and 1.2 s (FR-019: at most 0.5 s and
  2 s); sizes 10.6, 19.4, 39.7 and 105.9 KB (176 KB in all); RMS −21.2, −21.8, −19.1 and
  −18.2 dBFS, so no sound is much louder than another; two runs give byte-identical files;
  generation takes 0.4 s.
- **Rationale**: The sounds are the app's own, can be made again and adjusted, and carry no
  license (Clarifications). WAV plays with no conversion. The check allows one step of difference
  because another platform's maths library may round a sample the other way.
- **Alternatives considered**: a Swift script with AVFoundation (rejected: slower to run and no
  simpler); compressed formats (rejected: the files are small, and decoding adds latency); a
  sound pack or the prototype's file (rejected in Clarifications).

## R7. Playing the sounds

- **Decision**: The live `SoundPlayer` hands each sound to an actor, `SoundBank`, which on first
  use sets the audio session's category to `.ambient`, loads the four files into prepared
  `AVAudioPlayer`s, and then plays a sound by rewinding and starting its player. The app starts
  that preparation right after launch, off the main actor. Failures (a missing or unreadable
  file, a session error, a player that does not start) are a typed `SoundError`, logged under a
  new `sound` category; the game goes on without that sound, the bank prepares again before its
  next sound, and while sounds cannot play Settings says "Sound effects aren't available right
  now." (FR-017, FR-SND-05; added after `/speckit-analyze`). A media services reset discards the
  players the same way.
- **Measured** (on the Mac, the closest proxy): loading and preparing the four players takes
  107 ms the first time, so it must not run on the main actor (Constitution VII.3); each
  `play()` call takes 11–69 ms on macOS, so it runs in the actor too; the step itself never waits
  for it. The actor version compiles in Swift 6 with complete strict concurrency and no warnings.
  The time from a step to the sound on an iPhone is checked by hand (SC-004, quickstart §5).
- **Rationale**: `.ambient` is the category for sound effects: it follows the silent switch and
  the volume buttons and mixes with other apps' audio instead of stopping it (FR-016), and it
  needs no permission (FR-024). A player per sound lets a new step's sound start while the
  previous one still plays (FR-019). Retrying with the next sound costs nothing while sounds work
  and recovers from a passing failure without the player doing anything; the Settings notice
  gives the failure a clear state, as Constitution IV.3 requires for an error the player can
  notice (the switch says on, the game is silent).
- **Alternatives considered**: `AudioServicesPlaySystemSound` (rejected: follows the ringer
  volume instead of the media volume and is meant for alerts); `AVAudioEngine` with player nodes
  (kept in reserve: lower latency, more code; only if the iPhone check misses 0.1 s); playing on
  the main actor (rejected: the measured call times would cause hitches); logging failures only
  (rejected by `/speckit-analyze`: sound effects would read on and stay silent with nothing shown,
  against Constitution IV.3); an alert on failure (rejected: it would interrupt a game that goes on
  without sound, and could repeat with every step).

## R8. Which sound a step plays

- **Decision**: `SoundEffect.of(_ result: StepResult)`: *game end* when the step ends the game,
  else *crowning* when it crowns, else *capture* when it captures, else *move*. `GameSession`
  plays it in `applyStep`, right after the announcement, for the player's and the computer's steps
  alike, and plays *game end* when a resignation ends the game; only while `soundEffects` is on.
  Undo, selecting, refused taps, notices, Continue and navigation play nothing (FR-018).
- **Rationale**: `applyStep` is already the one place every step passes, once, in order, as it
  appears (the computer's chain is paced there, so each jump's sound comes with its jump,
  FR-014). The order is the spec's (FR-014, Edge Cases).
- **Alternatives considered**: playing from the view (rejected: the view does not know what a
  step did; Constitution II.2); deciding the on/off in the live player (rejected: the "sound off
  plays nothing" rule would need the audio code to test).

## R9. The Rules screen

- **Decision**: One scrolling page (Clarifications) of seven sections, each a heading, a short text
  and its pictures, in the order of FR-020; the content is in
  [contracts/rules-content.md](contracts/rules-content.md). The six rules sections show
  `BoardPicture`s of positions built through the engine (seven pictures: the chain has two);
  their marks come from the engine (the selection's targets, the movable pieces), so a picture
  cannot contradict the rules. The undo and resign section shows the game menu's two items with
  their symbols instead of a board (**spec alignment**: FR-021 said "a picture of a board
  position" for every section; a board says nothing about undo or resign). The texts are 364 words
  (*measured* on the contract), plus 156 words of picture descriptions for VoiceOver; every
  picture's claim was checked against the engine with a throwaway program (*measured*). Pictures
  with a selected piece draw the marks as the game does with hints on, so the Moving picture also
  rings the other movable men (a3, e3, g3) that its text describes (added after
  `/speckit-analyze`).
- **Rationale**: Short enough to scroll through in a minute or two, and one screen to audit. Tests
  rebuild each picture's position and check its claim with the engine (for example that the Dark
  man on h8 has no legal step), and count the words (SC-006).
- **Alternatives considered**: a list of topics with a page each, or an index (rejected in
  Clarifications); pictures as fixed marks typed by hand (rejected: they could drift from the
  rules unnoticed).

## R10. Test data for settings in UI tests

- **Decision**: UI tests set settings for one launch with typed launch arguments in Foundation's
  argument domain: `-boardTheme modern`, `-moveHints <false/>`, `-soundEffects <false/>`. A
  plain `NO` reads as the text "NO", which the store would treat as unreadable; the property-list
  forms `<false/>` and `<true/>` read as booleans (*measured* with a command-line program, which
  also confirmed that writes during the launch do not replace an argument's value). The
  `AppScreens` launch helper combines these with E5's `-savedGame`/`-record` arguments. Settings
  outlive each UI test like E5's data, so a test that changes a setting through the screen puts it
  back before it ends; no other UI test depends on hints, theme or sound (checked: none reads them).
- **Rationale**: The same mechanism as E5 (research R10 there), no test-only code in the app.
- **Alternatives considered**: a reset switch in the app for tests (rejected: test-only behavior);
  deleting the app between tests (rejected: slow, and not available within a test run).

## R11. Accessibility

- **Decision**: Settings is a form: the theme is an inline picker whose three rows each show the
  theme's name and its preview (the preview hidden from VoiceOver), so VoiceOver reads "Modern,
  selected"; sound effects and move hints are toggles ("Move hints, on"). Rules' headings carry the
  header trait, so the rotor moves between sections; each picture is one image element labelled
  with its description (FR-025). The audit gains Settings, Settings at the largest text size,
  Rules at its top and at its end, and the game screen in Modern and in Playful (FR-026).
  Previews of every new view at accessibility5 and in Dark Mode, per theme for the board.
- **Rationale**: System controls bring their own labels, values and Dynamic Type; the board's
  colors are not text, so the audit's contrast check does not reach them, and `US4ContrastTests`
  covers them per theme.
- **Found in US3 (2026-10-24)**: inside an inline picker row the check does reach them. The row
  merges its label into one text element whose frame covers the preview and the name, and the
  audit measured Classic's and Playful's squares as the name's colors ("Contrast failed" on the
  Classic and Playful rows, whichever theme was chosen; Modern's squares passed). Containing the
  row's children exposed the preview and its crowns as elements instead. The rows are now one
  button per theme, with the selected trait and a checkmark hidden from VoiceOver, so the name is
  a text element of its own; the row's element still has the theme's name as its label and the
  selected trait (checked with XCUITest; hearing it with VoiceOver is in quickstart §4).
- **Alternatives considered**: a custom grid of theme tiles (rejected: more code and its own
  selection semantics for VoiceOver).

## R12. Logging and privacy

- **Decision**: New logging categories `settings` (unreadable values) and `sound` (`SoundError`s).
  The privacy manifest does not change: `UserDefaults` is already declared (CA92.1), and playing
  sounds is no required-reason API and asks no permission.
- **Rationale**: One category per feature (Constitution IX.1); the settings and the sounds hold no
  personal data.
- **Alternatives considered**: logging settings failures under `storage` (rejected: that category
  is the saved game's and the record's).

## R13. Earlier tests that change

- **Decision**: Rewritten first, with the story that changes them: `placeholderMessages`, the
  placeholder UI tests in `US7NavigationUITests` and `testUS5_auditRules`/`testUS5_auditSettings`
  (US1 for Settings, US2 for Rules; `PlaceholderView` and `PlaceholderText` are deleted when both
  are gone); `LocalizationTests.prototypeStringsRemoved` keeps only "Play" and "Screen" (US3, as
  the theme names return); `screenStrings` loses the placeholder lines and gains the new texts;
  `PaletteTests` and `US4ContrastTests` run over every theme (US3); the hint tests in
  `US3HintsDragTests` keep passing unchanged with hints on, the default, and the hints-off cases
  are in the new `US1SettingsTests` (US1); `LoggingTests` lists the two new categories;
  `PrivacyManifestTests` gains the no-permission check (Setup).
- **Rationale**: Each change lands with the behavior that causes it, so the suite stays green
  after every task (workflow gate 3).
