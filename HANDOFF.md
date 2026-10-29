# Handoff

Last updated: 2026-10-28

## Working rules (set by the user, 2026-10-16)

- **Keep the board up to date.** Before starting work on any item, move it to **In Progress** on
  the [project board](https://github.com/users/iglooo101/projects/1/views/1); once it is
  complete, move it to **Done** and close the issue. Use
  `scripts/project/board_move.py <Todo|"In Progress"|Done> <issue>...`.
- **Spec Kit for every slice.** Each epic is one Spec Kit slice: specify → clarify → plan →
  tasks (+ analyze) → implement. No implementation outside that flow.
- **Keep `EXECUTION_PLAN.md` current.** Update it with every board change, and review and revise
  the whole file at every close-out (task, feature, epic, slice, session).
  `scripts/project/update_plan.py` regenerates its progress table, in-progress list and backlog
  from the board (`--check` reports drift); next up, risks and the change log are hand-written.
- **No unnecessary pull requests.** This is a solo repo: work on a feature branch, push it, wait
  for `CI gate` to pass, then fast-forward `main` (`git push origin <sha>:refs/heads/main`).
- **No CI for documentation.** Markdown-only changes must not run build or tests (#10, #12).
- **GitHub access uses the token in `../secrets/github.txt`**, passed only as `GH_TOKEN`; never
  print or commit it.
- **iglooo101 is the only identity** for commits and GitHub; never add Claude/AI attribution.

## Current state

- **Repo**: `github.com/iglooo101/checkers`. The repo root is this folder; the Xcode project lives
  in `checkers/` (see `checkers/CLAUDE.md` for commands and layout).
- **Branches**: `main` is protected: a commit lands only if the `CI gate` check passed for that
  exact commit (admins included, no pull requests). Work on a feature branch, push it, wait for
  CI, then fast-forward `main` (`git push origin <sha>:refs/heads/main` works without switching
  branches). Because `main` moves on GitHub, the local `main` lags: run
  `git fetch origin main:main` before comparing branches. `001-project-foundation` to
  `007-settings-themes-sound-and-rules` were merged and deleted (the auto-mode safety check blocks branch
  deletion, so the user runs it once the next slice's branch exists). **E6 is done** (last code
  CI run 40130998987 on `d85df26`); its branch `007-settings-themes-sound-and-rules` was merged
  and deleted. **E8 is in progress on `008-release-1-0`**: F8.0 (spec, clarify, constitution
  v1.2.0, plan, tasks, board) is done, the first implementation batch (T001–T011) is done, and
  US3's code (T023–T027, diagnostics) landed on 2026-10-26 (`f328c30`, CI run 40272374316).
  #206's fix (T058) landed on `main` (`eb4b680`, CI run 40345930966) and #206 is closed.
  US4's first batch (T029, T030, T032, T033, T035: icon and name) landed on `main` on
  2026-10-28 (`325b4b3`, CI run 40432329029). US4's second batch (T031, T036, T038, T039:
  listing, screenshots, public pages; `614fdca`) failed CI run 40766132938 on a slow runner in
  three tests it did not touch; the pages themselves are on `main` (`74541c2`) and live. US2's
  code (T015–T020) and a wider wait in a sound test followed; all of it landed on `main`
  (`4e095e3`, CI run 40772536644). The release tooling (T041–T043, T049, T050) and checklist
  (T042) landed on `main` too (`ba1b928`, CI run 40777068059, 16 script tests), with the
  session's close-out on top (`main` at `654a00f`, then `54fecab`). The App Store Connect key
  is in `../secrets` (T044, 2026-10-29: a Team Key with the App Manager role; a read-only API
  call returned 200). On 2026-10-29 build 1 (`363f98e`) went to TestFlight: bundle ID
  registered through the API, the owner's record (app 6828523739, "Checkers – Classic Board
  Game"), `release.sh archive 1` and `upload` (T045, processed); the listing is entered and
  #185 is done (T037, T039, T040); build 1 is in the owner's internal TestFlight group.
  `main` follows
  the branch head by fast-forward after each green `CI gate`.
  E6 in short: Settings with board themes (Classic, Modern, Playful; the user approved the
  colors), sound effects (four original sounds; approved) and move hints; Rules in seven
  illustrated sections; 313 blocking tests. Along the way #204 raised `build-and-test`'s limit
  from 30 to 45 minutes, the theme rows became buttons instead of an inline picker (research
  R11, "Found in US3"), and the largest-size Settings audit runs at rest (validation §6).
- **Constitution**: `.specify/memory/constitution.md`, v1.2.0 (ratified 2026-10-15; amended
  2026-10-16: iPhone only, portrait; amended 2026-10-25, spec FR-032: the toolchain is "the
  latest Xcode the development Mac runs, never below the App Store's minimum SDK", and CI uses
  the same Xcode). Nine principles plus workflow and governance gates. That Xcode is 26.3 for
  good: 26.4.1 to 26.6 need macOS Tahoe 26.2, Xcode 27 Tahoe 26.6 on Apple silicon, and Tahoe
  does not support the MacBook Pro (15-inch, 2019).
- **E8 implementation so far** (2026-10-25): `scripts/device.sh` (`status`, `launch`),
  `scripts/traceability.py` (writes `specs/008-release-1-0/traceability.md`: 84 FRD IDs covered,
  FR-PLAT-02 removed, none missing), `scripts/release.sh` (`archive`, `check`), the
  `checkers-device` scheme and `checkers/Device.xctestplan`, the pre-push hook
  `scripts/hooks/pre-push` (this clone has `git config core.hooksPath scripts/hooks`; a new clone
  must set it), `*.p8` in `.gitignore`, and five script tests (`test-no-secrets`, `test-device`,
  `test-no-network`, `test-traceability`, `test-release-check`); all 12 script tests pass. Done in
  `tasks.md`: T001–T011 (baseline 313 tests; the Release `checkers-device` test build compiles no
  engine tests; `release.sh archive 0` passes its check, archive in
  `.build/Release/Checkers-1.0-0.xcarchive` for T013 and T014; the board fits on the iPhone SE
  with 44.9-point squares and on the 17 Pro Max with 53; all in `checklists/validation.md`).
  **US3** (2026-10-26, T023–T027): `Features/Diagnostics/` holds `DiagnosticReport` (reads a
  MetricKit payload's JSON: five kinds, both time stamps, metadata re-encoded with sorted keys;
  anything else throws `DiagnosticError.unreadable`), `DiagnosticsLog` (`OSLogDiagnosticsLog`
  writes one line per diagnostic under the new `diagnostics` category, kind and times public,
  details private; `RecordingDiagnosticsLog` keeps them in a `Mutex` for tests) and
  `DiagnosticsSubscriber` (`nonisolated`, `handle(_:log:)` takes the payloads' JSON so tests
  need no `MXDiagnosticPayload`), started from a `.task` in `CheckersApp`;
  `US3DiagnosticsTests` with `Support/DiagnosticFixtures.swift`. 321 blocking tests. The owner's
  T028 passed on the phone (simulated payloads: one line per kind, Apple's key names as in the
  contract, time stamps without a zone), so #192 is done. The full plan's only local failure was
  the engine's SC-004 speed check (10.2 s with the engine unchanged), tracked as #206 (T058).
  **#206's fix** (2026-10-26, T058; done, CI run 40345930966 green with the engine's 86 tests
  in 26.8 s and the count at 2.0 s): `checkers.xctestplan` runs `CheckersEngineTests` one at a
  time (`"parallelizable" : false`, that target only); the test and the engine are unchanged, only `sixTurnSpeed`'s
  comment says why. Measured causes (`validation.md` §1): code coverage changes nothing; the
  first session's 9.2 s came from the simulator booting during each timed run; in the blocking
  plan the engine bundle runs last, beside its own suites on a Mac heated by the UI tests. With
  the fix the full blocking plan passes 321 of 321 locally (the count 3.86 s of CPU time; the
  engine bundle 50 s instead of about 28 s).
  **US4, first batch** (2026-10-26; #184 and #185 In Progress): `scripts/make-icon.py
  [--check]` (standard library, 1.4 s) draws `AppIcon.png` (RGB), `AppIcon-Dark.png` (RGBA, the
  piece only) and `AppIcon-Tinted.png` (grayscale) into `AppIcon.appiconset` and names them in
  its `Contents.json`: a cream king with a drawn crown (not the app's SF Symbol, which Apple does
  not allow in icons) on a two-by-two Classic corner, in the Classic colors; `--check` reads any
  PNG row filter and allows one step per channel. The app target sets
  `INFOPLIST_KEY_CFBundleDisplayName = Checkers` and `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption
  = NO`, with `App/InfoPlist.xcstrings` holding the name; `PlatformSettingsTests` checks the
  name, the encryption key and the plain launch screen (324 blocking tests); `release.sh check`
  also requires "Checkers", the encryption key false and version 1.0; `test-make-icon.sh` is
  the 13th script test. T034 (the owner approves the icon and, on the phone, the name and a
  plain launch in light and dark; moved there from T035) is open. T031 (the listing's test)
  moved to the second batch with T039, since it fails until the listing exists.
  **US4, second batch** (2026-10-28): `release/store-listing.md` holds the 15 fields of the
  store-listing contract, each paragraph and list item on one line (App Store Connect keeps
  line breaks), the description's paragraphs each followed by an HTML comment of FRD IDs;
  `test-store-listing.sh` (14th script test) checks Apple's limits on it and on six fixtures in
  `scripts/tests/listing-fixtures/`. Proposed name "Checkers – Classic Board Game"; the
  copyright holder ("2026 Hussein Helmy") is a guess from the bundle ID, to be confirmed.
  `docs/index.md` (support through GitHub Issues) and `docs/privacy.md` (`permalink:
  /privacy/`) are live at `https://iglooo101.github.io/checkers/` and `…/privacy/` (Pages from
  `main`, `/docs`, enabled by the owner). `ScreenshotUITests` (skipped by the blocking plan) runs
  through `checkers/Screenshots.xctestplan` from `scripts/screenshots.sh`, which boots the
  iPhone 17 simulator (iOS 26.3), sets light appearance, the default text size and the 9:41
  status bar, and writes `release/screenshots/01-home.png` … `06-statistics.png` (1206 × 2622
  RGB, no alpha, sRGB); a second run printed "No screenshot changed.". T037, T039's review and
  T040 wait for the owner.
  **US2's code** (2026-10-28; #181 and #182 In Progress): `GameSession+Timing.swift` logs
  "Computer turn at <level>: first step after <n> ms" (`computer`), `SoundBank` logs "Sound <name>
  started <x> ms after its step" (the request time read on the main actor by `AudioSoundPlayer`)
  and "Output latency <x> ms" on each preparation (`sound`), all public, notice level;
  `scripts/device-timings.py` judges a console capture (SC-005); `scripts/device-session-game.json`
  (a two-player position: e1–f2 by tap, e5–f4, c3–d4 by drag, f4–g3, f2–h4, b6–c5, then d4–b6–d8
  crowning) with a `StorageTests` test; `DeviceSessionUITests` (in `Device.xctestplan`, skipped by
  the blocking plan) attaches to the running app, or launches it when `SESSION_GAME` holds the
  game's hex bytes, and measures `XCTHitchMetric` over one session; `scripts/device.sh session`
  installs the Release build, launches it with `devicectl --console`, runs the test, and if the
  bundle has no hitch metrics runs it again with `TEST_RUNNER_SESSION_GAME`. Rehearsed on the
  simulator both ways (it reports no hitch metrics at all). 325 blocking tests, 15 script tests.
  T021 (the measurements on the phone) and T022 wait for the phone. Records in
  `validation.md` §4.
- **Device**: the owner's iPhone "HKH16" (iPhone 16, iOS 27.0.1, Developer Mode on) is connected
  to this Mac. On 2026-10-25 Xcode 26.3 built a Debug build, signed it automatically for team
  5RH237UKVE (iOS Team Provisioning Profile, valid until 2027-10-15), installed and launched it.
  The debugger, UI tests (through `xcodebuild test`) and Instruments recording work there too;
  `xctrace export` does not (E8 research R1).
- **Functional requirements**: `FRD.md` v1.3 (1.1: iPhone only, portrait; 1.2: FR-STAT-06, an
  unreadable record is reported once; 1.3: FR-SND-05, sounds that cannot play are reported in
  Settings and retried with the next sound). Requirement IDs such as
  `FR-MOVE-03`; section 19 lists what is out of scope.
- **App**: **fully native SwiftUI** (E3): Home, Game setup, a two-player game screen (tap and
  drag, hints, chains, crowning, undo, resign, result panel, Play again), Statistics (E5), and
  since E6 Settings (board theme, sound effects and move hints) and Rules (seven sections with
  engine-built pictures); the placeholders and the web prototype are gone. **E6**:
  `SettingsValues` and `AppSettings` (`Features/Settings/`) in `UserDefaults` under
  `boardTheme`, `soundEffects` and
  `moveHints`, read per key (an unreadable one takes its default, logged); the router hands
  `settings` to every session, and with hints off `hintedPieces` and `targets` are empty;
  `RulesContent` and `RulesView` (`Features/Rules/`), whose texts a test checks against
  `specs/007-…/contracts/rules-content.md`; `BoardPicture` (`Features/Game/`) draws still
  boards; board themes (US3) are namespaced asset folders (`Classic/`, `Modern/`, `Playful/`)
  read through `Palette.color(in:)` and the `boardTheme` environment value set by `RootView`;
  sounds (US4, `Features/Sound/`) are four WAV files generated by `scripts/make-sounds.py`,
  played by a `SoundBank` actor behind `AudioSoundPlayer` (`RecordingSoundPlayer` in tests and
  previews), one per step and resignation from `GameSession`, with Settings' notice while they
  cannot play (`AppRouter.showsSoundNotice`); UI tests pass settings as typed launch arguments (`launch(settings:)`, `setSwitch(_:isOn:)` in
  `AppScreens`). `GameSession` and
  `AppRouter` hold the interaction and navigation rules; setup choices are remembered in
  `UserDefaults` (declared in the privacy manifest). The **`CheckersEngine` package holds the
  rules engine** (E2); public API in `specs/002-rules-engine/contracts/engine-api.md`, whose
  custom-position initializers E3 made public. **Computer games are playable** (E4 US1): the
  engine's `ComputerPlayer` searches complete turns with alpha-beta and iterative deepening over
  an allocation-free `TurnGenerator` (held to `GameState` by the published counts and a
  1,000-position cross-check), and `GameSession` plays the computer's turn through two injected
  seams, `ComputerOpponent` (`EngineComputerOpponent` searches in a `@concurrent` function with
  a 0.8 s limit) and `TurnPacer` (0.5 s minimum thinking, 0.5 s between jumps), with the board
  locked meanwhile. **The three levels differ** (E4 US2, research R4): Easy looks 2 turns ahead
  and plays any turn within 40 points of its best, Medium 4 turns with an 8-point margin, Hard up
  to 16 turns within 1,500,000 nodes, playing only exact ties; the root draws among them with a
  seed (`SeededGenerator`, now in the engine). Medium scores 90 of 100 against Easy and Hard 99
  of 100 against Medium. While it thinks the menu works (E4 US3): resign and leave cancel its
  turn, and its next step waits while Rules or Settings covers the game (`ScreenCover`, set by
  the router from its path). Undo returns to the player's turn, cancelling the computer's (US4,
  research R9). VoiceOver announces each computer step once, without "Jump again." in its chain,
  and focus stays put (US5). With Reduce Motion on, the thinking spinner becomes a still
  hourglass. Setup defaults to Computer, Easy, Light and remembers choices when a game starts.
  **Accessibility** (E7): every dark square is a VoiceOver element with its state ("c3, Light
  man, can move"), double-tap plays square by square, each step, undo and resignation is
  announced once through the `Announcer` seam, and focus follows each step. Pieces and marks
  keep 3:1 contrast with side-specific crowns, and an audit test checks every screen (allow-list
  in `specs/004-accessibility/plan.md`). **Saving** (E5 Setup to US1): `GameState` is `Codable`
  with explicit keys and validation (`GameState+Coding.swift`; damaged data throws
  `DecodingError.dataCorrupted`); the app keeps one saved game and the record as versioned JSON
  in `UserDefaults` (`SavedGameStore` and `RecordStore`, keys `savedGame` and `record`, with
  in-memory stores that hold encoded bytes); `GameSession` sends `saved` through `onEvent` after
  every turn and undo and offers a `snapshot` (the start of the computer's turn while that turn is
  unfinished; `GameSession+Saving.swift`); the router saves on those events, on Home and when the
  scene moves to the background (`CheckersApp`); Home offers Continue while a game is saved;
  leaving a game no longer asks. **US2**: `GameSession` sends `ended` once (the last step of
  either side, or a resignation) and the router clears the saved game then; while a game is
  saved, Start in setup asks "Abandon current game?" (`isConfirmingAbandon`, `confirmAbandon()`,
  `cancelAbandon()`; the alert in `SetupView`), and the UI tests' `tapStart()` answers it.
  **US3** (CI run 39954174275): `GameResult` (from the outcome, the player's side and the
  difficulty; `nil` for two-player or unfinished games), `Record.adding(_:)`, `isEmpty` and
  `tally(at:)` in `Record.swift`; `GameSession.result` in `GameSession+Saving.swift`; the router's
  `record`, loaded at creation and updated and saved in `finish(_:)` on `ended`; `StatisticsView`
  and `StatisticsText` (plural counts in the catalog, one VoiceOver sentence per difficulty,
  `statistics.empty` and `statistics.easy`/`medium`/`hard`) replace the Statistics placeholder.
  **US4** (CI run 40023240169): `RestoreNotice` (`Features/Saving/RestoreNotice.swift`); the
  router's `init` clears an unreadable save, replaces an unreadable record with an empty one that
  it saves, logs both and queues a notice each (`restoreNotice`, `dismissRestoreNotice()`); Home
  shows them one at a time from a `.task(id:)`, the saved game's first. **#202** (T030): the
  engine's SC-004 check times the counting thread's CPU time (`clock_gettime_nsec_np`), not the
  wall clock.
- **CI**: `.github/workflows/ci.yml` on every push except to `main`; Markdown-only pushes skip the
  build (about 20 s); code pushes take 22–30 minutes with the UI tests and audits
  (`build-and-test` has a 45-minute limit since #204). Since E4 US2 a
  second job, `engine-strength`, runs the Release-only strength matches in parallel, and
  `CI gate` requires both (`scripts/ci/gate.sh` takes four results).
- **Backlog**: 8 epics, 41 features, 156 tasks (#1–#206; #188 is a PR) on the project board.
  **E1 Project foundation, E2 Rules engine, E3 Game experience, E7 Accessibility, E4 Computer
  opponent, E5 Saving and statistics and E6 Settings, themes, sound and rules are done** (E6:
  #132, final CI run 40130998987, 313 tests). **E8 Release 1.0 (#169)** is the last epic and is
  in progress: F8.0 (#170: specify, clarify, plan, tasks, reconcile) is done; in F8.1 #179
  (traceability) and #192 (diagnostics) are done and #177 and #178 wait for the owner's checks;
  in F8.2 #206 (the engine's speed check on the development Mac) is done and #181 and #182 (US2)
  wait for the phone (T021); in F8.3 #184 to #187 (icon, store page, TestFlight, submission) are
  In Progress, their code written and waiting for the owner and Apple; #205 (validation) is open
  (38/41 features, 147/156 tasks, 10 items In Progress).
  Progress and the full list are in `EXECUTION_PLAN.md`.
- **Spec Kit**: E1's slice is `specs/001-project-foundation/` (validation log in
  `checklists/validation.md`), E2's `specs/002-rules-engine/` and E3's
  `specs/003-game-experience/` (60 tasks, validation in `checklists/validation.md`; a hand-played
  game and a visual review at large text are left for the user) and E7's
  `specs/004-accessibility/` (26 tasks, validation in `checklists/validation.md`; a VoiceOver game
  by hand is left for the user). E4's slice is `specs/005-computer-opponent/`: spec (3
  clarifications), plan with measured research R1–R14, contracts `computer-player.md` and
  `computer-turn.md`, 35 tasks, **all done** (final CI run 39861850824, landed on `main`);
  measurements, results and the checks left for the user are in `checklists/validation.md`.
  E5's slice is `specs/006-saving-and-statistics/`: spec (4 user stories, 26 requirements, 3
  clarifications), plan with measured research R1–R14, data model, contracts `saved-game.md`
  (format version 1, validity, stores, save points, recording) and `screens.md` (Continue, the
  abandon and restore-failure alerts, Statistics, audit), quickstart and **`tasks.md` (29 tasks,
  analyzed: 15 findings fixed, among them FR-STAT-06 and four existing tests the slice breaks;
  plus T030 added for the timing check; **all done**, final CI run 40040004817, landed on
  `main`)**; results, measurements and the checks left for the user in
  `checklists/validation.md`. **E6's slice is `specs/007-settings-themes-sound-and-rules/`**:
  spec (4 user stories: move hints, Rules, board themes, sound; 27 requirements; 4
  clarifications: the sounds are original and generated by a script, a theme changes only the
  board, an unreadable setting takes its default without an alert, Rules is one scrolling page),
  plan with measured research R1–R13, data model, contracts `settings-and-sound.md` (three
  `UserDefaults` keys, hints, the Modern and Playful colors, the sound rules and recipes),
  `screens.md` and `rules-content.md` (the seven sections, their engine-built pictures and
  texts), quickstart, and **`tasks.md` (35 tasks, analyzed: 12 findings applied: a sound that
  cannot play shows "Sound effects aren't available right now." in Settings and the next sound
  tries again, FR-SND-05 and spec FR-017; `BoardTheme`'s names move to US3; the Rules pictures
  ring the other movable pieces)**. **E8's slice is `specs/008-release-1-0/`**: spec (6 user
  stories: every promise verified, fast and smooth on a real iPhone, diagnostics after release,
  icon and store page, TestFlight beta round, submitted and approved; 32 requirements traced to
  #177–#179, #192, #181, #182, #184–#187; 10 success criteria) and its quality checklist. Settled
  with the user before specifying: paid developer account (team 5RH237UKVE); device checks on
  their iPhone "HKH16"; an original icon drawn by a script; privacy and support pages on GitHub
  Pages (`iglooo101.github.io/checkers`, support through GitHub Issues); the store name chosen in
  App Store Connect, "Checkers" on the Home Screen; bundle ID `Hussein-Helmy.checkers` kept; free
  everywhere; uploads with an App Store Connect API key kept in `../secrets`; TestFlight with a
  few external testers; one release checklist that gathers every open hand check of E3–E7 and
  gates submission; manual release, E8 done at approval. Clarified: Xcode 26.3 builds 1.0 and the
  constitution is amended (FR-032); the iPhone 16 counts as evidence for VII.1 (FR-014); one iPad
  compatibility smoke check per release build (FR-005); diagnostics only logged on the phone
  (FR-009). **Plan** (2026-10-25): research R1–R17 measured on the phone (Xcode 26.3 debugs,
  runs UI tests and records Instruments on iOS 27.0.1; Release cold launch median 231 ms over
  five; no hitches in a Rules scroll), a new `checkers-device` scheme and `Device` and
  `Screenshots` test plans, a MetricKit `DiagnosticsSubscriber` that logs each diagnostic's kind
  and time, two timing log lines read through `devicectl --console`, the name "Checkers" and the
  encryption key, a scripted icon in three variants, and scripts for the device checks,
  screenshots, traceability and releases (contracts `diagnostics.md`, `release-tooling.md`,
  `store-listing.md`). **Tasks** (#174): 57, tests first; tasks for the owner, Apple and the
  phone are marked **Owner:**, **Apple:**, **Phone:**. `.specify/feature.json` (local,
  git-ignored) points at it.

## Lessons learned

- **Spec Kit was initialized twice** (repo root and `checkers/`). The root install is canonical;
  the nested copy was deleted. Run Spec Kit commands and scripts from the repo root.
- **The existing app does not yet comply with the constitution**: UI is HTML in a web view
  (Principle I), `SWIFT_VERSION = 5.0` (Principle IV), no tests or CI (Principle III). Expect the
  first plan's Constitution Check to flag all of these.
- **Template customizations go in `.specify/templates/overrides/`**, which Spec Kit resolves
  before the core `.specify/templates/` files, so an upgrade cannot silently revert them. The
  tasks template override (#26) makes tests mandatory and test-first; if Spec Kit's core
  `tasks-template.md` changes, merge those changes into the override by hand.
- **The app target defaults to `MainActor` isolation** (`SWIFT_DEFAULT_ACTOR_ISOLATION`), so heavy
  work such as game AI must be explicitly moved off the main actor.
- **No Claude/AI attribution** in commits, PRs, code or docs. This is an absolute rule, enforced
  in `~/.claude/settings.json` and `~/.claude/CLAUDE.md`.
- **iglooo101 is the only identity** on this Mac and in this repo. Commits are authored as
  `iglooo101 <12980807+iglooo101@users.noreply.github.com>` (global git config; GitHub's no-reply
  address, so they link to the account). The whole history was rewritten to this identity on
  2026-10-16.
- **`gh` was installed manually** in `~/.local/bin` (no Homebrew on this Mac); it does not
  auto-update.

## Lessons learned (FRD session, 2026-10-15)

- **The user prefers question-and-answer sessions**: one multiple-choice question at a time
  (the `AskUserQuestion` picker), with a recommended option first. Batch the agreed decisions into
  one summary table, list any gaps you filled in separately, and confirm before writing.
- **The FRD describes the target product, not the prototype.** The current `Play.html` differs from
  it (single-tap multi-jumps, no AI, no draws, no saving), so don't treat existing behavior as
  required.
- **The user's file location overrides skill defaults**: the FRD lives at the repo root, not in
  `docs/superpowers/specs/`.
- **Rules gaps to watch**: resignation-only endings let king-vs-king games run forever, so
  automatic draws (threefold repetition, 40 moves per side without progress) were added. Similar
  edge cases (undo mid-chain, undo while the AI thinks, resume during the AI's turn) are now
  pinned down in FRD sections 10 and 12.
- **Work happens on a branch**: commits go on a feature branch, not straight to `main`, and land
  by a local fast-forward merge (no PR unless needed).

## Lessons learned (backlog session, 2026-10-16)

- **Backlog decisions**: native rewrite (rules engine and AI in a Swift package, screens in
  SwiftUI, HTML screens deleted at the end); one Spec Kit slice per epic, each opened by an
  `Fx.0 Specification` feature; accessibility has its own epic plus an accessibility pass task in
  every UI feature.
- **Board fields**: "Type" is a reserved field name on GitHub project boards, so the level field
  is called **Level**. `gh project field-create --single-select-options` splits on commas, so
  option names with commas must be set through the GraphQL `updateProjectV2Field` mutation.
- **`gh` scopes**: the token now has `project`. `gh auth refresh` cannot run through the `!`
  prefix (not interactive); run `gh auth refresh -h github.com -s <scope> -c` in the background
  and give the user the one-time code from its output.
- **Moving an item on the board**: `gh project item-list 1 --owner iglooo101 --format json` gives
  item IDs, `gh project field-list 1 --owner iglooo101` gives field and option IDs, and
  `gh project item-edit --project-id <id> --id <item> --field-id <Status> --single-select-option-id <option>`
  sets the status. Set Done explicitly as well as closing the issue.
- **Board ordering and links**: sub-issue order is set with
  `PATCH repos/iglooo101/checkers/issues/<parent>/sub_issues/priority` (`sub_issue_id`,
  `after_id`), and blocked-by links with
  `POST repos/iglooo101/checkers/issues/<n>/dependencies/blocked_by` (`issue_id` is the numeric
  issue ID, not the number). Every implementation feature is blocked by its epic's `Fx.0`.
- **The board auto-adds pull requests**: merged PR #188 appeared on it in Done.
- **The GitHub MCP connector failed to authenticate** in this session; the `gh` CLI covers
  everything needed.

## Lessons learned (E1 implementation, 2026-10-16)

- **GitHub access uses the token in `../secrets/github.txt`** (outside the repo), passed only as
  `GH_TOKEN`; never print or commit it. It has `repo`, `workflow`, `project`, `read:org`. Pushing a
  file under `.github/workflows/` needs the `workflow` scope.
- **UI test targets keep nonisolated default isolation.** `XCTestCase` initializers are
  nonisolated, so a MainActor default breaks compilation; mark UI test methods `@MainActor`.
- **Package test targets in a test plan need a project navigator reference to the package**
  (a folder file reference next to the `XCLocalSwiftPackageReference`). Without it `xcodebuild`
  silently skips them; check with `xcrun xcresulttool get test-results tests`.
- **Command-line builds never update `Localizable.xcstrings`**; only Xcode does. CI syncs a copy
  with `xcrun xcstringstool sync` and fails on any difference. When building only from the command
  line, sync the catalog the same way and commit it.
- **The SwiftLint plugin uses the topmost `.swiftlint.yml` in the project folder**
  (`checkers/.swiftlint.yml`); nested configs in test folders relax rules; the engine package has
  its own config with `parent_config`. Command-line builds need `-skipPackagePluginValidation`.
- **CI probes go on throwaway `probe/*` branches** (one deliberate defect each) so they run in
  parallel without cancelling the slice branch's run; delete them afterwards.
- **Launch baselines are per machine** in `checkers/launch-baselines.json` (Intel Mac and arm64
  runner differ); Xcode's own baselines are tied to one machine and could not be created from the
  command line.
- **Script pitfalls**: macOS ships bash 3.2, so expand possibly empty arrays as
  `${arr[@]+"${arr[@]}"}`; with `pipefail`, `cmd | grep -q` can report the producer's failure, so
  capture output first and grep the variable.

## Lessons learned (E2 specification and session close-out, 2026-10-16)

- **The board and plan helpers now live in `scripts/project/`** (committed at the user's request
  after the scratchpad copies proved session-only): `board_move.py` moves items and confirms the
  new status; `update_plan.py` rewrites only the `GENERATED` sections of `EXECUTION_PLAN.md`, so
  hand-written parts survive; `gh_client.py` reads the token from `GH_TOKEN` or
  `../secrets/github.txt`. GitHub's GraphQL API exposes `subIssues` and `blockedBy`, so a full
  plan refresh takes about 10 seconds instead of minutes of REST calls.
- **Closing order on the board**: close a task when its work is verified in CI, a feature when all
  its tasks are closed, and an epic when all its features are; move each to Done as it closes.
- **Close-outs land fast**: Markdown-only commits pass `CI gate` in about 20 seconds, so every
  close-out can go branch → CI → `git push origin <sha>:refs/heads/main` in one step.
- **Clarify works best as a few picker questions**, each with a one-line "why it matters" and a
  recommended option; three questions settled E2. Questions that only affect implementation are
  left to the plan.
- **The auto-mode safety check blocks destructive git** (history rewrites, `reflog expire`,
  `gc --prune`). When the user asks for one, give them the exact command to run with `!` and
  verify the result afterwards.
- **Spec decisions that later epics depend on**: every applied step returns a step result
  (FR-027, used by E3 sounds, E7 announcements, E4 jump-by-jump display); a win by no legal moves
  beats a same-turn draw; repetition counts turn starts and undo uncounts.

## Lessons learned (E2 plan and tasks, 2026-10-21)

- **Check reference data with a throwaway prototype.** A 100-line Python perft in the scratchpad
  confirmed the published counts to depth 9 and showed what they cover: no king moves within 8
  turns, crowning from turn 7, and a wrong crowning-mid-chain rule only from depth 9. That set the
  test depth (7) and showed which rules need their own tests.
- **Check scripted test positions before writing tasks.** The same prototype found that a naive
  80-turn king shuffle repeats a position three times by turn 21, and that one test position left
  the side to move with no legal move; both were fixed in `tasks.md` before implementation.
- **Whole-engine checks belong with the story that completes them**, not in a final phase:
  analyze flags tests placed after the code they check (Constitution III.1). The reference counts
  fail at depth 7 until chains and crowning exist, so they are written with US3.
- **Moving an issue to Done on the board closes it automatically**, sometimes before
  `gh issue close --comment` runs, which then posts nothing. Post the summary with
  `gh issue comment` (or before the move) and check that it landed.

## Lessons learned (E2 implementation, 2026-10-21)

- **`swift test` did not run SwiftLint** (out of date since 2026-10-22: it does now, see the E4
  lessons). The SwiftLint plugin's prebuild command did not run under `swift build`/`swift test`;
  only the Xcode build linted the engine (`scripts/test.sh`, CI).
  For fast feedback, run the binary directly from `checkers/CheckersEngine`:
  `BUILD_WORKSPACE_DIRECTORY="$PWD" .build/artifacts/swiftlintplugins/SwiftLintBinary/SwiftLintBinary.artifactbundle/macos/swiftlint lint --quiet --force-exclude --no-cache $(find Sources Tests -name '*.swift')`.
- **A push cancels the branch's running CI.** The cancelled commit's `CI gate` reports failure.
  Push again only after a run finishes, or rely on the last commit's run before fast-forwarding.
- **`identifier_name` accepts `to`** (`Step(from:to:)`), set in `checkers/.swiftlint.yml`; other
  short names (`a1`, `at`) still warn, so tests use longer names.
- **Engine speed in Debug builds**: the 7-turn reference count takes about 20 s and the 6-turn
  count 5 s (SC-004 budget 10 s). Each turn end generates the opponent's moves and scans the
  history. E4's search will need faster generation; profile first (Constitution VII.4).
- **Swift Testing details**: `#expect(throws: RuleError.x) { try state.apply(step) }` works with
  typed throws and a mutating closure; failure messages do not show the value of a `try`
  expression, so assign it first when the value matters.

## Lessons learned (E3 implementation, 2026-10-21)

- **String extraction misses switch expressions with optional results.** The compiler extracted
  only one literal from `switch` expressions returning `LocalizedStringResource?`; use explicit
  `return`s there. Check `*.stringsdata` under `.build/DerivedData` when a string seems missing.
  `scripts/sync-string-catalog.sh` updates the catalog after command-line builds;
  `xcstringstool sync` drops untranslated keys that are no longer extracted.
- **On iOS 26, a confirmation dialog from a toolbar item is a popover without Cancel.** Use an
  alert for confirmations. In UI tests, alert buttons are found by label (`alerts.buttons[...]`
  with `firstMatch`, since Cancel appears twice), and menu items by label too.
- **Closing a menu in a UI test**: tap near the bottom edge, not on content the open menu covers
  (a tap on the turn indicator hit Resign).
- **Long forms at large text sizes create rows lazily**: UI tests must scroll to an element before
  asserting on it (`AppScreens.scrolledTo`).
- **Large-text checks**: `xcrun simctl ui <device> content_size accessibility-extra-extra-extra-large`
  and `appearance dark`, then run the UI tests with `-destination id=<device>`; reset afterwards.
  The `-UIPreferredContentSizeCategoryName` launch argument does the same inside one test.
- **Previews need public API**: the app target cannot use `@testable`, so the engine's
  custom-position initializers were made public for previews of kings, captures and chains.

## Lessons learned (E7 implementation, 2026-10-22)

- **The accessibility audit fails system defaults**: system blue on bordered and prominent
  buttons, `.secondary` text, Form header and footer gray, and text over a material that shows
  the board. The app now has its own `AccentColor` and `OnAccent`, primary text and an opaque
  result panel. Inside a Form header, `.foregroundStyle(.primary)` keeps the header's gray; use
  `Color.primary`.
- **The audit's Dynamic Type check misfires on scrolling forms**: it reports "partially
  unsupported" on whichever line the form cuts at the bottom edge once it enlarges the text, and
  the report moves when the layout moves. Check with a screenshot at the largest size before
  changing code; the allow-list rule is narrow (`isAllowed` in `US5AccessibilityAuditUITests`)
  and logs every allowed issue as a test activity.
- **System banners break audits on CI**: a fresh CI simulator showed "Ready for Apple
  Intelligence" over the app, and the audit read it as inaccessible text with no element. The
  audit helper re-audits a screen with problems after 8 s and fails only on problems found both
  times. CI keeps the result bundle (`test-results` artifact), whose screen recording shows such
  overlays.
- **XCUITest cannot drive VoiceOver.** Announcements are tested through the `Announcer` seam and
  focus through `GameSession.focusSquare`; a VoiceOver game by hand stays with the user.
- **Visual checks**: `ImageRenderer` leaves out the board's square cells, so use simulator
  screenshots (an `XCTAttachment` in a throwaway UI test, then
  `xcrun xcresulttool export attachments`). `simctl` has no grayscale filter; convert with
  `sips -m "/System/Library/ColorSync/Profiles/Generic Gray Profile.icc"`.
- **Parameterized Swift Testing arguments** in the MainActor-default test target must be
  `nonisolated`, and so must the app types they hold (`Palette`).
- **Push once the previous CI run finished**: commit stories locally while a run is going; a push
  cancels the branch's running run.

## Lessons learned (E4 specification to US1, 2026-10-22)

- **Profile before designing a search.** Through the public API the engine applies about 175,000
  steps per second in Release and 11,000 in Debug; Time Profiler showed allocation, not rules, as
  the cost. A throwaway allocation-free prototype in the scratchpad reproduced the published
  counts to 10 turns at about 25 million turns per second, which justified a second generator for
  the search (research R1). Keep `GameState` as the referee: the computer's root turns come from
  it and every step it plays goes through `apply`.
- **Hot loops: take a buffer out of its array before filling it** (`var turns = buffers[ply];
  buffers[ply] = []`), or copy-on-write copies it on every node. The finished search runs at
  3.3–4.6 million nodes per second in Release.
- **Approachable concurrency is on in the app**: a `nonisolated async` function runs on its
  caller's actor, so off-main work needs `@concurrent nonisolated`, and the static constants it
  reads need `nonisolated` too. Store a non-escaping closure in a struct for one call with
  `withoutActuallyEscaping`.
- **Member import visibility is on**: a file that calls `Logger` methods must `import OSLog`
  itself, even if another file of the target does.
- **`swift test` does run SwiftLint now**: a lint error in an engine test file failed
  `swift test` on 2026-10-22 (the E2 lesson below is out of date). SwiftLint caps functions at five
  parameters; group them into a small value (`Search.Node`, `TurnGenerator.Mover`).
- **Testing timed behavior without waiting**: `ScriptedComputerOpponent` (held until released)
  and `ManualPacer` (records pauses, resumes on demand), with `waitUntil` and `settle` in
  `checkersTests/Support/ManualPacer.swift`, which yield the main actor until a condition holds.
- **UI tests cannot see sub-second states**: after a tap XCUITest waits for the app to go idle
  and `XCTNSPredicateExpectation` polls about once a second, so the half-second "Dark is
  thinking…" header is tested in unit tests and previews (research R12).
- **The audit's edge-cut false positive moves with the layout**: with Computer chosen, setup is
  longer and Start became the cut row, so the exception now covers Start too (E4 plan, audit
  allow-list).
- **Debug-run engine tests must stay shallow**: the blocking plan runs the engine in Debug on the
  simulator, so its tests use small internal `SearchLimits`; Hard at full strength belongs in the
  Release strength target (found by `/speckit-analyze`).
- **New issues can be auto-added to the board**: `gh project item-add` failed with "Content
  already exists" for #200; look the item up instead and set its fields.
- **The auto-mode safety check blocks deleting remote branches** (`git push --delete`); give the
  user the command.

## Lessons learned (E4 US2, 2026-10-22)

- **Release-only suites**: SwiftPM defines `DEBUG` in debug builds, so
  `@Suite(.enabled(if: isOptimized))` with `#if DEBUG` skips the strength matches in a plain
  `swift test` (hours in Debug) and runs them with `swift test -c release`, which keeps
  `@testable import` working.
- **Find test positions with a throwaway search, not by hand.** A scratch package with a copy of
  the engine scored every root turn at several depths over thousands of random positions, then
  removed pieces one at a time while the property held. That found the four-turn position (Easy
  against Medium) and the six-turn win (Medium against Hard) in seconds; checking deeper depths
  showed the six-turn win stays best up to depth 14.
- **Ties by construction** make "only the best turns" testable without depending on evaluation
  weights: a king that takes four men by two routes ending on the same board.
- **Time turns alone, not in parallel matches.** With 100 games running on 16 threads a Hard turn
  took up to 3.5 times longer than alone; the matches replay their slowest turns by state and
  seed, and the 0.5 s budget was checked by timing every Hard turn of 12 games one at a time.
- **Pipes in GitHub Actions**: the default `run` shell has no `pipefail`, so `swift test | tee`
  would hide a failure; `shell: bash` adds `-o pipefail`.
- **`Duration / Duration`** failed to type-check inside a larger expression with `Double`; divide
  in integer milliseconds instead.

## Lessons learned (E4 US3 to Polish, 2026-10-22)

- **Do not time the main actor in parallel unit tests.** The app's unit tests share it, and on
  CI's 3-core runner other suites held it through a whole 0.8 s search. Test that work leaves the
  main actor by order instead: queue it, then a probe, and require the probe to run first.
- **Check new tests catch the bug with a mutation**: removing `@concurrent` made the order test
  fail, which the timed version had not shown on CI.
- **SwiftLint's limits bite at 250 lines of class body**: `GameSession` reached 249. Read-only
  queries went to `GameSession+Display.swift` and the computer's turn to an extension in the same
  file (it shares private state there); new E5 and E6 behavior should follow that pattern.
- **The system spinner ignores Reduce Motion**, so the game shows a still hourglass then.
  `accessibilityReduceMotion` cannot be set in a preview; check on a simulator: turn it on with
  `xcrun simctl spawn <udid> defaults write com.apple.Accessibility ReduceMotionEnabled -bool YES`
  and reboot it, record with `xcrun simctl io <udid> recordVideo`, then extract frames (an
  `AVAssetImageGenerator` script, with Vision to find the frames by their text) and compare a
  region between frames.
- **XCUITest cannot act inside sub-second states**: after a tap it waits for the app to settle,
  so pressing Home "while the computer thinks" happens after the reply.
- **Commit the next story locally while CI runs**, and push once the run has finished: a push
  cancels the branch's running run.
- **`didSet` works on an `@Observable` property**: the router updates `setCovered` from `path`
  that way, including when the navigation stack pops.

## Lessons learned (E5 specification to tasks, 2026-10-22)

- **Spec Kit makes no branch here**: `create_new_feature.py` creates the spec folder and
  `.specify/feature.json` but no git branch (no git hook is installed). Create it by hand from an
  up-to-date `main` (`git checkout main && git checkout -b 006-…`) before committing the spec.
- **Measure before choosing storage**: a 220-turn game is about 23 KB as JSON and codes in about
  2 ms, and a `UserDefaults` write takes microseconds, so files, actors and background tasks were
  not needed. Seeded random play ends games fast (47 turns for most seeds); a long test game
  needs steps that end it refused, across many seeds.
- **The compiler's `Codable` for `GameState` is a poor save format**: a side encodes as
  `{"light":{}}`, and `private(set)` properties can only be set from their own file, so custom
  decoding needs an internal initializer in `GameState.swift`.
- **`UserDefaults` launch arguments set test data without app switches**: `-key <hex bytes>` makes
  `data(forKey:)` return those bytes for the whole launch, and writes do not replace them
  (checked on the Mac; research R10).
- **Persisted data changes UI testing**: saved games and the record outlive each test, the record
  cannot be reset, so UI tests compare counts before and after, the start helpers answer
  "Abandon current game?", and audits that need a known state set it with launch arguments.
- **The GitHub API can drop a connection** (`update_plan.py` failed once with "connection reset by
  peer"); rerunning it worked.

## Lessons learned (E5 analysis, 2026-10-22)

- **Grep the test targets for everything a slice removes or puts in the way.** Research said no
  UI test used the leave alert; a grep for its texts, identifiers and router members found two
  more tests, one of them a UI test, and the Statistics placeholder's message was checked by three
  tests. A new question in a flow (the abandon alert) breaks every test that taps through that
  flow without the shared helpers, so search for direct taps too.
- **Check every "tell the player nothing" decision against Constitution IV.3.** The silent reset
  of an unreadable record passed clarify and the plan's Constitution Check; `/speckit-analyze`
  flagged it. The fix changed product behavior, so it went into the FRD first (FR-STAT-06,
  version 1.2), then spec, plan, contracts and tasks.
- **Test changes go in the test tasks, not in the implementation task that causes them**
  (Constitution III.1), so they are seen failing first.
- **Order of save and cancel matters**: leaving between the computer's jumps must take the
  snapshot before cancelling its turn, or the save holds a half-played computer chain that
  Continue cannot resume.

## Lessons learned (E5 Setup to US1, 2026-10-22)

- **Launch arguments work in the simulator** (checked first, T001): `-key <hex bytes>` makes
  `data(forKey:)` return those bytes for the launch, writes during it still reach the stored
  value, and a text value such as `-savedGame none` reads as no data. `launch(replacing:with:)` in
  `AppScreens` builds the argument from JSON text.
- **XCUITest sees the app in the background before SwiftUI does**: after
  `XCUIDevice.shared.press(.home)` and `wait(for: .runningBackground)`, the scene phase has not
  changed yet, so a test that terminates at once loses the background save. Wait about two
  seconds first.
- **Save order without order bugs**: `GameSession` keeps `computerTurnStart` from the start of the
  computer's turn until its last step or an undo, not until a cancel, so the snapshot is right
  whether the router saves before or after cancelling the computer's turn.
- **SwiftLint's 400-line file limit** hit `GameSession.swift`; extensions that need no private
  state go in their own file (`GameSession+Saving.swift`). A session that starts mid-chain now
  selects the chain's piece in its initializer, which made that possible.
- **Check that a damaged-data test rejects for the intended reason**: turning the validity check
  off for one run made exactly the expected eight cases fail. `#expect(throws: DecodingError.self)`
  returns the error, so the test can require `.dataCorrupted`.
- **Do not write into a target's folder while `xcodebuild` builds**: with file-system
  synchronized groups a new file joins the target. Wait until the log shows testing has started,
  or keep drafts in the scratchpad; a throwaway probe test must be deleted before committing.
- **`build-for-testing` lists only the first errors of a failing batch**; it is still the fastest
  way (about 2 minutes) to see new tests fail to compile before the implementation.

## Lessons learned (E5 US2 and US3, 2026-10-23)

- **A board move to Done does not always close the issue**: after `board_move.py Done 127 72`
  both issues were still open a few seconds later. Check each issue's state after the move and
  close it with `gh issue close --reason completed` if needed (the comment goes first).
- **`gh run list --commit` wants the full SHA**: a short one finds nothing. Filter
  `gh run list --branch <branch>` on `headSha` instead.
- **swift-format flags a long string literal on the same line as `@Test(`**, not one on its own
  line: wrap long test names as `@Test(\n "…"\n)`, or run `xcrun swift-format format --in-place`
  on the file. `scripts/check-format.sh --strict` is what CI runs.
- **`scripts/check-string-catalog.sh` takes the catalog and the derived data**:
  `scripts/check-string-catalog.sh checkers/checkers/Localizable.xcstrings .build/DerivedData`
  after a build. `LocalizationTests` catches a missing string too: it failed on exactly the
  alert's three texts until the catalog was synced.
- **Plural variations go into the catalog by hand** after a command-line sync, which adds the key
  empty: an `en` entry with `variations.plural.one` and `other`, each a `stringUnit` with state
  `translated`, in the catalog's two-space layout. The catalog check then confirms a sync keeps
  them, and `String(localized:)` in a unit test reads "1 win" and "3 wins" from the app's compiled
  catalog. Rewriting the file with a JSON library would reorder it; edit the text instead.
- **CI's `changes` job compares the whole push** (`github.event.before` to `HEAD`), so a code
  commit and a docs commit pushed together still run the full build and tests. At a close-out,
  push both at once rather than pushing the docs after the code, which would cancel the run.
- **The record cannot be reset in UI tests either**: `testUS3_finishedGameCounts` reads Easy's
  losses before and after a resigned game, and the empty-state test and the Statistics audit
  launch with `-record` holding an empty record (`StoredValues.emptyRecord` in
  `checkersUITests/Support/AppScreens.swift`).
- **SourceKit reports "No such module 'CheckersEngine'"** for new test files before the first
  build; it is noise, the build compiles them.

## Lessons learned (E5 US4, 2026-10-23)

- **One alert after another needs a later update.** Presenting the next alert in the update that
  closed the previous one (a binding read false, then true again) never showed it; Home now
  presents each notice from `.task(id:)`, which runs after that update. A test with both values
  damaged found it; the stories' own tests had passed.
- **XCUITest does not see identifiers on alert buttons** (`home.restoreFailure.ok`): find them by
  label inside the alert, with `firstMatch`, since iOS can expose a button twice.
- **Wall-clock budgets fail on a slow runner.** The engine's SC-004 check failed at 10.5 s on a
  runner about three times slower than usual (every suite slower, same image, engine unchanged).
  Reproduce with every core busy (`yes > /dev/null &` once per logical core, killed afterwards):
  the wall clock failed at 10.02 s, the counting thread's CPU time (`clock_gettime_nsec_np
  (CLOCK_THREAD_CPUTIME_ID)`, valid because a synchronous test stays on one thread) was 6.92 s.
- **`gh run rerun <id> --failed`** reruns only the failed jobs of a commit; the `CI gate` of the
  rerun counts for the branch protection. Use it only once the cause is known not to be the code.
- **Do not push while a rerun runs**: a push to the branch cancels it like any other run.

## Lessons learned (E5 Polish, 2026-10-23)

- **`launch(replacing:with:)` always passes bytes**: `"none"` through it is four bytes of damaged
  data, which shows the restore alert. A text value that reads as no data needs the plain
  argument (`app.launchArguments = ["-savedGame", "none"]`).
- **System alerts fail the Dynamic Type audit** ("partially unsupported" on their title, message
  and unnamed elements), though their text grows several times at the largest size. Check on
  screen first: `xcrun simctl launch <udid> Hussein-Helmy.checkers -savedGame "<6e6f6e65>"` sets
  the same launch argument as a UI test, and `xcrun simctl ui <udid> content_size …` with
  `xcrun simctl io <udid> screenshot` shows the result. The allow-list rule applies only while an
  alert shows, to its static texts or to unnamed elements.
- **`xcodebuild test` leaves the simulator shut down**: boot it (`xcrun simctl boot`, then
  `bootstatus`) and install the built app before `simctl launch`.
- **A throwaway probe can report numbers through a failing test**: `Issue.record("…")` puts them in
  the log; copy the probe into the test folder only when no build is running, run it alone with
  `-only-testing`, and delete it before committing (`git status` to confirm).

## Lessons learned (E6 specification to tasks, 2026-10-23)

- **Deleted prototypes live in git history.** Board issue #144 said the themes are "ported from
  the HTML mockups", which E3 deleted; `git log --all --diff-filter=D -- <path>` found the commit
  (`e3c0c2b`), and `git show e3c0c2b^:checkers/checkers/Modern.html` gave the designs back.
- **Measure contrast with the test's own pairs, and reproduce a known result first.** The first
  reading compared the dark piece's fill with its square (1.11:1 for Modern) and overstated the
  problem: `US4ContrastTests` separates a dark piece from its square by its edge. A throwaway
  script with the test's 8 pairs reproduced Classic's E7 numbers exactly before it judged the new
  palettes (`specs/007-…/research.md` R4).
- **Typed `UserDefaults` launch arguments**: `-moveHints NO` reads as the string "NO"
  (`object(forKey:) as? Bool` is nil); the property-list forms `<false/>`, `<true/>` and
  `<string>…</string>` read as typed values. Checked with a command-line probe (R10).
- **`AVAudioPlayer` is slow to set up and to call on the Mac**: loading four short files took
  107 ms and each `play()` call 11–69 ms, so playback belongs in an actor, never on the main
  actor (R7). An actor holding `AVAudioPlayer`s compiles cleanly in Swift 6 strict mode.
- **Check claims about positions with the real engine**: a scratch SwiftPM package with
  `.package(path: "…/checkers/CheckersEngine")` builds in about 5 s and confirmed every Rules
  picture's targets and the blocked ending (it even reports the ending's outcome).
- **Generated assets need a reproducibility check**: the sound script is seeded and writes
  byte-identical files; its `--check` allows one sample step of difference because another
  platform's maths library may round differently. Keep a recipe in the contract detailed enough
  to rebuild the script, since scratchpad prototypes do not survive the session.
- **A string added early can break a test written for a later story**: syncing the catalog after
  adding `BoardTheme`'s names in Foundational would add "Classic", "Modern" and "Playful", which
  `prototypeStringsRemoved` (E3) forbids until US3 changes it. Put strings in the story whose test
  changes (found by `/speckit-analyze`).
- **App value types need `nonisolated` (and `Sendable`)** when the nonisolated `Palette`, an actor
  or a parameterized test uses them: the app target's default isolation is the main actor
  (`GameSetup`, `Record` and `Palette` already follow this).
- **Grep for every use of an API a slice changes**, including previews: `Palette.….color` is also
  used by `ResultPanel`'s previews, which the task list had missed.
- **`cd` inside one shell command changes the session's directory**: later relative paths then
  point into the wrong folder. Use absolute paths, or a subshell `( cd … && … )`.

## Lessons learned (E6 analysis fixes, 2026-10-24)

- **Place a fix where the spec already talks about it**: the handoff put the sound-failure
  sentence in FR-018 (what makes no sound), but FR-017 (when no sound plays) was its home; adding
  it there kept the count at 27 requirements, while the FRD gained its own ID (FR-SND-05) for
  traceability.
- **A failure that cannot be caused in a UI test needs a testable rule**: the Settings notice
  depends on `AppRouter.showsSoundNotice`, tested with a recording player whose `isAvailable` the
  test sets, and the bank's file errors with a temporary directory; only the look is left to a
  preview.
- **`update_plan.py` sets the "Last updated" date** in `EXECUTION_PLAN.md`'s header itself, so a
  hand edit of that line must start from the regenerated text.

## Lessons learned (E6 implementation, 2026-10-24)

- **Draft in the scratchpad while a build runs, copy in once it ends**: a whole story's tests
  and code were written while the 15-minute baseline ran, then copied in, seen failing with
  `build-for-testing` and completed. Scratchpad files do not outlive the session, so drafts
  that are not yet in the targets go into the repository before a close-out (the WIP branch's
  `wip-drafts/`).
- **Commit the next story while CI runs, push after it finishes**: US2 was implemented and
  committed while US1's 40-minute CI run went on, and pushed only once it passed.
- **`UserDefaults` skips a write equal to the stored value**, and the number 0 equals `false`:
  a test that stores an unreadable 0 over `false` must remove the key first.
- **Booleans in `UserDefaults`**: `as? Bool` accepts the numbers 0 and 1; the store checks
  `CFGetTypeID(number) == CFBooleanGetTypeID()`, so only real booleans (including `<true/>` and
  `<false/>` launch arguments) count.
- **XCUITest and form switches**: a toggle in a `Form` fills its row, so tapping its middle hits
  the label; `setSwitch(_:isOn:)` taps near the trailing edge and waits for the value ("1"/"0").
  Inline picker rows expose `isSelected`, found by their identifiers.
- **`@Bindable` cannot bind through a `let`** of another observed object (`$router.settings.x`
  fails); bind in the body with `@Bindable var settings = router.settings`.
- **Contract texts can be the test's source**: `US2RulesTests` parses the Rules contract and
  compares every string, so the 364 words are not typed twice; `LocalizationTests` derives the
  Rules strings from `RulesContent`.
- **Preview strings go into the catalog too**: a preview's own description added a key; reuse a
  real string. A catalog diff can look like a removal when two keys swap lines; check the file.
- **The audit can flag a picker row with a picture in it**: the Classic theme row (preview and
  name in one frame) fails the contrast audit with no named element. A throwaway UI test with a
  screenshot attachment and the issue's `element?.frame` found it (exported with `xcrun
  xcresulttool export attachments`).
- **The sound recipe in the contract is complete**: a fresh `make-sounds.py` written from it
  reproduced research R6's lengths, sizes and RMS levels exactly.
- **Foreground `sleep` is blocked**: wait for a run with `run_in_background` and its
  notification, or an `until` loop.

## Lessons learned (E6 US2's CI and US3, 2026-10-24)

- **A cancelled job can be a time limit, not a push**: US2's run showed "cancelled" on Launch
  timing with every test passed; the job had reached `timeout-minutes`. Compare the job's start
  and end with the limit before rerunning, and compare per-test durations between two runs'
  `test-results` artifacts (`gh run download <id> -n test-results`, then
  `xcrun xcresulttool get test-results tests`) to tell new tests from a slow runner.
- **An inline picker row is one text element**: SwiftUI merges a picker row's label into a
  static text whose frame covers everything in it, and ignores `accessibilityHidden` inside it.
  With a picture beside the name, the contrast audit measured the picture's colors as the
  text's. `.accessibilityElement(children: .contain)` exposed the picture's parts as elements
  instead. A `Button` per row, with `.isSelected` and a hidden checkmark, keeps the name its own
  element.
- **Try layout variants in one build**: a temporary `UserDefaults` key read by the view (a launch
  argument such as `-probeVariant A`) let one throwaway UI test audit three designs and print
  their element trees (`app.debugDescription`) in a single run. Remove both before committing.
- **`scripts/lib.sh` turns on `set -euo pipefail`**: after `source scripts/lib.sh` in a command,
  a `grep` that finds nothing ends the shell silently; add `set +e` when the command goes on.
- **Drafts written without a compiler need the full run, not only their own tests**: US4's drafts
  hid a test that tapped the selected piece again (deselecting it), and E3's
  `NoWebContentTests` banned every `.wav`, which only the full plan showed. Grep the tests for
  the file types and names a story adds, as for what it removes.
- **A new form section moves the audit's edge-cut report**: the Sound section pushed the Game
  section's header and footer to the bottom edge. Check at the largest size on screen (a UI test
  with `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL` and
  screenshots), then allow it like the setup row.
- **Keep `GameSession.swift` under 400 lines**: it was at 388, so US4 added only the stored
  property, the parameter and two calls there, and the helper went to `GameSession+Sound.swift`.

## Lessons learned (E6 Polish, 2026-10-24)

- **A CI runner can start before its simulators are ready**: "Unable to find a device matching
  the provided destination" two minutes in, with an empty list of destinations and nothing
  built. The image looked new, but a rerun of the failed jobs on the same image passed; check
  the log before blaming the code or the pins.
- **Never let a docs-only push stand in for an untested code commit**: CI's `changes` job
  compares the whole push, so pushing docs on top of a code commit whose run failed would turn
  the gate green without testing that code. Get a green full run on the code commit first.
- **Do not audit at an arbitrary scroll position**: wherever a swipe stops, large text can lie
  under the navigation bar, and the contrast check measures it there, sometimes without naming
  it; an opaque bar or a hard scroll edge does not stop it, because hidden text is measured too.
  It passed twice locally and failed on CI. Audit a screen at its top (or at its end, where
  nothing text-like sits under the bar), and cover the rest at the default size. A CI screen
  recording settles such questions: `gh run download <id> -n test-results`, export the
  attachments, and take frames with `AVAssetImageGenerator` at the audit's timestamps.
- **When a second app change is needed to quiet the same audit report, suspect the test**: the
  hard scroll edge, then the opaque bar, then a frame rule each moved the report without ending
  it; comparing with the audits that always passed (at rest) showed the scrolled position was
  the problem. Revert the app changes such a chase added once the test is fixed.
- **Check every coverage claim in the docs against the test names** before writing it: a quick
  grep of `@Test` and `func test` names confirmed the quickstart's "covered by" lines.
- **swift-format exempts test names only in the `XCTestCase` class body**: `testUS5_…` in an
  extension fails `AlwaysUseLowerCamelCase`; keep UI tests in the class.
- **Audits written for the default size cannot run at a system-wide largest size**: a test that
  expects every section on one screen times out there; use a launch argument
  (`-UIPreferredContentSizeCategoryName`) in its own test instead.

## Lessons learned (E8 specification and clarify, 2026-10-24)

- **Ask what a release slice depends on outside the repository before specifying**: a paid
  developer account, a device, credentials, public web pages and a store name decide which tasks
  can be closed at all. Eleven picker questions settled them, then specify and clarify needed only
  four more.
- **`xcrun xctrace list devices` can show a stale paired device**: it listed "HKH16" as offline on
  iOS 26.3.1. `xcrun devicectl list devices` and `xcrun devicectl device info details --device
  <id>` gave the truth: available, `iPhone17,3` (an iPhone 16, not a Pro), iOS 27.0.1.
- **Check the toolchain against the constitution at the start of a slice**: Xcode 27 shipped on
  2026-09-14 and needs Apple silicon and macOS Tahoe; this Mac is a 2019 Intel MacBook Pro
  (`MacBookPro15,3`) on macOS 15.8.1 and cannot run it, so "the latest stable Xcode" had been
  unmet for weeks. App Store Connect accepts iOS 26 SDK builds until April 2027
  (`sw_vers`, `sysctl -n machdep.cpu.brand_string`, `system_profiler SPHardwareDataType`).
- **The Home Screen name was the lowercase target name**: `PRODUCT_NAME = $(TARGET_NAME)` and no
  `CFBundleDisplayName`, so the icon would read "checkers" (spec FR-016).
- **Store defaults to turn off or plan for**: an iPhone app is offered on Apple silicon Macs and
  Apple Vision Pro unless turned off, and App Review may run it on an iPad in compatibility mode.
- **"Still running" from the user**: twice nothing was running; checking `gh run list` and the
  local processes (only the session's XcodeBuildMCP server, which is long-lived and normal) and
  saying so was the right answer.

## Lessons learned (E8 implementation, first batch, 2026-10-25)

- **Never send dependent steps in one batch of tool calls**: a file write and the command that
  ran it went out together twice, and the command ran before the file existed ("No such file or
  directory"). Write, then run, in separate steps.
- **A guard test can prove itself on every run**: `test-no-secrets.sh` and `test-no-network.sh`
  check the real repository, then plant each problem in a temporary directory and expect all of
  them to be found; that replaces a one-off mutation and keeps proving the check in CI.
- **`git grep` reads a pattern that starts with dashes as an option**: pass it with `-e`
  (`git grep -E -e "$HEADER"`); a key header begins with `-----BEGIN`.
- **Build the key pattern from parts**: a guard that searches for `PRIVATE KEY` matches its own
  source and every document that mentions it; matching the whole header line, assembled at run
  time, does not.
- **`devicectl list devices --json-output` is enough for a status check**: it carries the name,
  model, iOS version, `tunnelState` and `developerModeStatus`. A disconnected phone reports a
  stale Developer Mode ("disabled"), so check the tunnel first.
- **Regenerate the plan after every board move**: six items moved to In Progress without
  `update_plan.py`, and the user's "is the execution plan up to date?" caught it. Run it in the
  same step as `board_move.py`.
- **Look for an existing test before writing one**: T011 assumed `BoardLayoutTests` should check
  the board's fit, but that is a UI fact, and `testUS1_boardFitsAndShowsOnlyTheIndicator`
  already asserts it on whatever device it runs.
- **FRD IDs are named per test**: in `@Test` display names (app and engine) and in `///` comments
  above `func test…` (UI tests); parsing them per test gives the same 84 of 85 as a file grep.

## Lessons learned (E8 plan research on the iPhone, 2026-10-25)

- **Use `xcodebuild test` on the phone, never `test-without-building`**: with an `.xctestrun`
  file the runner starts but every `XCUIApplication().launch()` fails ("The process identifier of
  the launched application could not be determined"); the same tests pass through the scheme.
- **A Release test build of the `checkers` scheme fails** on the engine's `@testable` tests, and
  `-only-testing` does not narrow what gets built; a scheme whose build action leaves out
  `CheckersEngineTests` works (E8 plan: `checkers-device`). A throwaway user scheme in
  `xcuserdata/` (git-ignored) is a safe way to probe this.
- **`xctrace export` crashes on traces recorded on iOS 27** (segmentation fault on every table)
  while simulator traces export; read phone traces in the Instruments app.
- **The app's log reaches the Mac**: `xcrun devicectl device process launch --console
  --environment-variables '{"OS_ACTIVITY_DT_MODE":"YES"}' <bundle id> -- <app arguments>` prints
  its `Logger` lines with microsecond times (the `--` keeps `devicectl` from parsing the app's
  arguments). A UI test can then drive that same process with `XCUIApplication().activate()`;
  UI test result bundles do not contain the app's log.
- **`XCTHitchMetric(application:)`** (iOS 26 SDK) gives the hitch-time ratio, hitch count and
  total hitch time on the phone; a total under 0.25 s also rules out a 250 ms hang.
- **The first debugger attach to a new iOS copies its symbols** (6.6 GB, several minutes) and
  looks like a silent failure meanwhile; retry after it finishes.
- **Developer Mode can be off without warning** (`devicectl` error 10005; Instruments says "The
  device is missing the required developer tools"); check `developerModeStatus` first.
- **Apple's dates are announcements, not patterns**: the April 2027 iOS 27 SDK cut-off in the spec
  had been inferred; Apple's upcoming-requirements page lists only the iOS 26 SDK (since
  2026-04-28). Quote the page before writing a date.

## Lessons learned (first run on the iPhone, 2026-10-25)

- **"The latest Xcode" means the latest this Mac runs**: the user expected an update; Apple's
  table at developer.apple.com/support/xcode lists each release's minimum macOS, and
  support.apple.com/122867 lists the Macs Tahoe supports. Check both before promising an update.
  Xcode is an App Store install here (`Contents/_MASReceipt`), so the App Store offers only what
  the Mac can run.
- **Running on the phone from the command line**: `xcodebuild build -project
  checkers/checkers.xcodeproj -scheme checkers -configuration Debug -destination id=<udid>
  -derivedDataPath .build/DerivedData -skipPackagePluginValidation -allowProvisioningUpdates`,
  then `xcrun devicectl device install app --device <identifier>
  .build/DerivedData/Build/Products/Debug-iphoneos/checkers.app` and `xcrun devicectl device
  process launch --device <identifier> Hussein-Helmy.checkers`. `xcodebuild` takes the hardware
  UDID (`udid` in `xcrun devicectl device info details`), `devicectl` the CoreDevice identifier
  from `xcrun devicectl list devices`. Keep both out of the repository.
- **Check the phone before building**: `devicectl device info details` shows `tunnelState`,
  `developerModeStatus` and `ddiServicesAvailable`; all three were good on iOS 27.0.1.
- **A paid team's development profile lasts a year**, not seven days (that is the free tier):
  `security cms -D -i <app>/embedded.mobileprovision` shows its `ExpirationDate`.

## Lessons learned (first E8 batch finished, 2026-10-25)

- **Screenshots of a passing UI test without a throwaway test**: the plans keep attachments only
  on failure, but a copy of the built `.xctestrun` (in `.build/DerivedData/Build/Products/`, so
  its `__TESTROOT__` paths still resolve) with `SystemAttachmentLifetime` set to `keepAlways` and
  `PreferredScreenCaptureFormat` to `screenshots` on `checkersUITests`, run with
  `xcodebuild test-without-building -xctestrun <copy> -destination id=<simulator>
  -only-testing:…`, keeps a screenshot and a UI snapshot of every step. `xcrun xcresulttool
  export attachments` writes them with a `manifest.json`; the UI snapshots are binary property
  lists whose `plutil -p` output holds every element's frame next to its identifier. This works
  on simulators only (on the phone `test-without-building` cannot launch the app).
- **A build-products folder keeps old products**: `.build/DeviceDerivedData` still held the
  research probe's `CheckersEngineTests.xctest`; judge what a build compiled from its log and
  the file times, not from what the folder contains.
- **The smallest iPhone is close to the 44-point limit**: the board's squares are 44.9 points on
  the iPhone SE, while CI runs only the iPhone 17, so a layout change can break the SE silently
  (risk in `EXECUTION_PLAN.md`).
- **`cd` in a command moves the session's directory**: it happened twice more (after `cd` into
  the spec folder and into the build products); use subshells or absolute paths.
- **Read the gate itself before a fast-forward**: `gh api
  repos/iglooo101/checkers/commits/<full sha>/check-runs --jq '.check_runs[] | select(.name=="CI
  gate") | .status + " " + (.conclusion // "")'` gives the required check for that exact commit;
  a 10-second `until` loop on it waits for a docs-only run (done in about a minute).
- **"Is the execution plan up to date?"** is answered by `update_plan.py --check` (the board's
  numbers) and a read of the hand-written Next up, Risks and change log, which the check cannot
  see.

## Lessons learned (E8 US3, 2026-10-26)

- **A thread's CPU time is not immune to load on this Mac**: the 6-turn count takes 4.8 s alone
  and 9.6 s beside the other engine suites (`swift test` in `checkers/CheckersEngine`), and 10.2
  s of CPU time failed the full plan. A busy twin hardware thread and a lower clock slow the
  counting thread itself; #202's CPU-time measure only stops other threads' work from being
  counted. CI's arm64 runner is not affected. (The #206 lessons below show this was only part
  of the cause.)
- **Write fixture key names out**: the diagnostics fixtures spell `crashDiagnostics` and the
  others literally instead of reading the parser's `arrayKey`, so a wrong key fails the test; a
  mutation (a wrong launch key) proved it.
- **Mutations in one run must not overlap**: dropping the sorted keys fails every case that
  compares a detail, which would hide a second mutation in the per-kind test; run such a
  mutation alone. Back up untracked files before mutating them (git cannot restore them).
- **Typed throws suit a parser**: `init(json:) throws(DiagnosticError)` with `do throws(…)` at
  the caller keeps the failure path explicit; `JSONSerialization` with `.sortedKeys` and
  `.fragmentsAllowed` gives a stable detail text for any metadata value.
- **SwiftLint warns on `String(decoding:as:)` for `Data`** (`optional_data_string_conversion`):
  use the failable `String(bytes:encoding:)`.
- **A follow-up found mid-story gets its own board task and `tasks.md` entry before the push**,
  so one push carries the code, the docs and the issue number (a later docs push would cancel the
  code's CI run).
- **Apple's simulated MetricKit payloads** (Debug › Simulate MetricKit Payloads, only while Xcode
  debugs the app on the phone) carry all five kinds with sample metadata (`pid` 123,
  "testEventName", `lowPowerModeEnabled` true) and time stamps without a zone; filter Xcode's
  console with `reported`. The system messages around them (PointerUI, "AX Safe category") are
  noise.

## Lessons learned (#206 investigation, 2026-10-26)

- **Measure the first hypothesis before writing it into an issue**: #206's body blamed parallel
  tests; one more run of the count alone in the simulator (9.2 s at full speed, 11.1 s hot)
  showed the main causes were elsewhere. Time the suspect alone, in each environment that runs
  it (`swift test` on the Mac and the simulator differ by 2.3 times), before choosing a fix.
- **This Mac throttles itself when hot**: `pmset -g therm` shows `CPU_Speed_Limit` (100 at full
  speed; 54–62 right after an `xcodebuild` build). A timed test that runs after a build can lose
  half the clock. Read it before and after every timing run, and use `xcodebuild
  test-without-building -xctestrun .build/DerivedData/Build/Products/<name>.xctestrun
  -destination … -only-testing:…` (simulator only) to time without the build's heat.
- **`pmset -g therm` separates name and value with a tab**: `grep "CPU_Speed_Limit *= 100"` never
  matches; use `grep -E "CPU_Speed_Limit[[:space:]]*= 100"`. A wait loop on the wrong pattern
  ran ten minutes before it was noticed.
- **The blocking plan gathers code coverage**: `xcrun xccov view --report --only-targets
  .build/TestResults/<name>.xcresult` lists coverage for the run, so the code under test is
  instrumented. It does not slow the count (measured in the next session: 4.47 s with and
  without instrumentation); the 2.3 times was the simulator booting.
- **A temporary probe in a tracked test file** (a `print` of the measured value) is quick and
  safe when `git checkout -- <file>` removes it before any commit; check with `git status`.

## Lessons learned (#206 cause and fix, 2026-10-26)

- **Check that the build under test is what the hypothesis needs**: the plan was to rerun the
  built tests with `-enableCodeCoverage NO`, but the binary was already instrumented
  (`otool -l <binary> | grep __llvm_prf` lists the profile sections), so that run would still
  have timed instrumented code. Testing coverage needed a second `build-for-testing
  -enableCodeCoverage NO` into its own derived data (41 s here), then timing both builds.
- **A simulator boot is a load storm**: `xcodebuild test` and `test-without-building` boot a
  shut-down simulator and shut it down afterwards, and a boot drives this Mac's load average to
  about 50 and its clock down to `CPU_Speed_Limit` 68 for about four minutes. Before timing
  anything in the simulator, boot it (`xcrun simctl boot <udid>`, then `bootstatus`) and wait
  until `sysctl -n vm.loadavg` settles; `test-without-building` then leaves it booted (after
  `scripts/test.sh` it was shut down again).
- **Alternate the two variants when comparing builds**: a single coverage-on run followed by a
  coverage-off run made coverage-off look slower (7.8 s against 9.6 s) because the Mac was
  drifting; A/B/A/B pairs with `pmset -g therm` before and after each run show the drift.
- **The result bundle's action log is a timeline**: `xcrun xcresulttool get log --path
  <xcresult> --type action` gives each test target's start time (JSON `startTime`, `duration`,
  nested `subsections`). It showed that the blocking plan runs the app's unit tests and UI tests
  at the same time and the engine bundle last; its durations did not add up (the engine bundle's
  ran past the end of the run), so rely on the start times.
- **Swift Testing's in-process parallelism follows the test plan**: `"parallelizable" : false`
  on a target becomes `InProcessParallelizationEnabled` 0 in the built `.xctestrun` and runs that
  bundle's tests one at a time; `-parallel-testing-enabled NO` does the same for one run.
  `-parallel-testing-enabled YES` instead runs the bundle on a new simulator clone ("Clone 1 of
  iPhone 17"), and the tests' `print` output does not come back from it. On the Mac, `swift
  test --no-parallel` runs the engine suites one at a time.
- **On this Intel Mac a thread's CPU time is not private**: the counting thread's own CPU time
  grows when other tests keep the cores busy (3.8–4.4 s one at a time, 6.8–7.9 s beside the
  other suites; most likely the twin hardware thread and a lower turbo clock, not measured), so
  CPU time only keeps other threads' work out (#202); only running alone removes their effect.

## Lessons learned (landing #206 and US4's first batch, 2026-10-26)

- **`board_move.py Done` closes the issue a few seconds later** (the board's workflow): `gh issue
  view` right after it still said OPEN, and `gh issue close` then reported it already closed.
  Re-read the state after a short wait instead of closing by hand.
- **SF Symbols are not allowed in app icons** (Apple's symbol license), so the icon draws its own
  crown instead of the app's `crown.fill`; any later icon change must keep it a drawn shape.
- **A guard test on the generated Info.plist can be proven with a temporary `INFOPLIST_FILE`**:
  with `GENERATE_INFOPLIST_FILE` on, Xcode merges that file's keys into the generated ones, so a
  plist adding `UILaunchScreen` › `UIColorName` failed the launch-screen test. Put the file next
  to the `.xcodeproj` (outside the synchronized folders, which would copy it as a resource), set
  it in one configuration of the app target only (a command-line setting reaches every target,
  packages included), back up `project.pbxproj` first and restore it after.
- **Don't edit what a running build reads**: the red run of a test was building in the
  background, so the project edit waited for it; the script-only parts (`release.sh`) went
  ahead meanwhile.
- **Xcode's JSON layouts**: an asset catalog's `Contents.json` round-trips byte for byte through
  `json.dumps(…, indent=2, separators=(",", " : "), sort_keys=True)` plus a newline; string
  catalogs (`.xcstrings`) have the same layout but no final newline.
- **Pure-Python drawing is fast enough with spans**: per sample row, each shape gives x
  intervals; merged per color and added to a per-pixel difference row, then
  `itertools.accumulate` gives the coverage. Three 1024 × 1024 icons with 4 × 4 samples take 1.4
  s, and a per-row cache keeps the compositing cheap.
- **A check that reads PNG files must undo row filters**: our files use filter 0, but `sips`
  (and any optimizer) writes filters 1–4; decoding a `sips` re-encode to the same pixels proved
  the reader.
- **`cd` in a command moved the session's directory again** (into the spec folder while reading
  `tasks.md`); use `sed -n … <path>` or `(cd … && …)`.

## Lessons learned (US4's second batch, 2026-10-28)

- **The auto-mode safety check blocks enabling GitHub Pages** ("Create Public Surface"); give
  the user the exact `gh api -X POST …/pages` command to run with `!`, then check the build
  (`gh api repos/iglooo101/checkers/pages/builds/latest`, 36 s here) and the URLs.
- **App Store Connect keeps line breaks**: the listing's texts are one line per paragraph or
  list item; wrapping them at 100 characters like the other docs would paste broken sentences.
  The limits test counts the text as it is pasted (comments removed, blank runs collapsed).
- **A store screenshot without alpha needs no Python**: redraw `XCUIScreen.main.screenshot()`
  on a `UIGraphicsImageRenderer` with `opaque = true`, the image's scale and `preferredRange =
  .standard`; `pngData()` then gives an 8-bit RGB sRGB PNG, and two runs gave byte-identical
  files. Decoding 1206 × 2622 PNGs byte by byte in Python would have taken minutes.
- **Find game positions for UI tests with the engine**: a scratch package playing seeded random
  games found a chain, a crowning and a mid-game position in 0.2 s; print them as text boards
  before using them. A saved game for a UI test may leave `turns` empty (undo is then off).
- **`sed -n '/^f() {/,/^}/p'` cuts a shell function short** when a heredoc inside it has a `}`
  at column 0 (a Python dict); extract the heredoc between its markers instead.
- **`cd` in a command moved the session's directory again** (into the fixtures folder); use
  subshells or absolute paths.

## Lessons learned (US2's code and a slow runner, 2026-10-28)

- **`XCUIApplication.activate()` launches an app that is not running**, without its launch
  arguments; a test that must attach to an app started elsewhere checks `app.state !=
  .notRunning` first.
- **`TEST_RUNNER_<NAME>` reaches the test as `<NAME>`**: `TEST_RUNNER_SESSION_GAME=<hex>
  xcodebuild test-without-building …` gave the UI test the saved game's bytes, so a script can
  hand a test data from a file without a Swift copy.
- **`measure(metrics:options:)` with `iterationCount = 1` runs its block twice** (the rehearsal
  logged six computer turns per level for three moves each); a measured block must start and end
  in the same state.
- **The simulator reports no `XCTHitchMetric` values**, even for an app the test launched (a
  throwaway probe); hitches can only be measured on the phone.
- **`simctl launch --console-pty` with `SIMCTL_CHILD_OS_ACTIVITY_DT_MODE=YES`** mirrors the app's
  `Logger` lines like `devicectl --console` on the phone, so a device script can be rehearsed on
  the simulator; the capture held 215,000 lines of system noise around 71 of ours.
- **A run that is slow everywhere points at the runner**: compare the image version (`Runner
  Image` in the job log) and the unchanged suites' times with the last green run before blaming
  the code; then check each failure's own history (the sound test's durations in four runs showed
  its 5-second wait was the weak point).
- **Stub the real tools before a script test's first red run**: `test-release-guards.sh`'s first
  run started a real `xcodebuild archive`, because `release.sh` did not have its dry-run mode
  yet; a stub `xcodebuild` beside the stub `gh` on `PATH` makes every case harmless whatever the
  script does, and lets a refusal check that the stub was never called.
- **`xcodebuild` prints its whole command line** ("Command line invocation"), so secrets passed as
  arguments must be filtered from its output (`release.sh upload` pipes it through `sed`).
- **A close-out during a code run stays local**: pushing Markdown on top of a running code run
  cancels it and the docs-only run turns the gate green without testing the code; commit the
  close-out, push it after the code run is green.

## Lessons learned (landing the release tooling, 2026-10-28)

- **Save a job's log through `gh run view`**: `gh api …/actions/jobs/<id>/logs` refused to write
  output with terminal escape sequences in it (an empty file); `gh run view <run> --job <id> --log
  | tr -d '\033' > <scratchpad file>` saved all 9,567 lines. Get job IDs from `gh api
  …/actions/runs/<run>/jobs`.
- **Swift Testing's result lines interleave with the app's log lines in CI**, so a test's own
  "passed after" can be cut off; read its time from its "started" and "✔" time stamps.
- **Wait for a gate in the background**: foreground `sleep` is blocked; a `run_in_background`
  loop polling the commit's `check-runs` every 10 s until `CI gate` completes notifies the
  session when it is done.
- **`gh issue view` takes `--comments` or `--json`, not both**; read the last comment with
  `--json comments --jq '.comments[-1].body'`.
- **Owner-only steps get exact steps, not attempts**: the App Store Connect key needs the
  owner's Apple Account (two-factor) and downloads once, so the session gives the clicks and
  the commands to run, then checks the files' names and modes without printing their values.

## Lessons learned (key, record, build 1 and listing, 2026-10-29)

- **Keys in Certificates, Identifiers & Profiles are not App Store Connect keys**: those are
  for push, Sign in with Apple and the like. The upload key comes from App Store Connect ›
  Users and Access › Integrations › App Store Connect API › Team Keys (Request Access first;
  granted at once for an individual Account Holder).
- **Check a new key with a read-only call**: a JWT signed with `openssl dgst -sha256 -sign`
  (DER signature converted to raw r‖s) and Python's standard library, then `GET /v1/apps`;
  200 proves the Key ID, issuer and key agree before any upload depends on them. The helper
  printed statuses and safe attributes only, never the token. Python modules beside a script
  run with `-I` need `sys.path.insert(0, <script dir>)`.
- **Automatic signing in Xcode does not register an explicit App ID**: device runs used the
  team's wildcard profile, so `Hussein-Helmy.checkers` did not exist and the New App dialog
  could not offer it. `POST /v1/bundleIds` with the App Manager key registered it (Apple
  stores it as Universal).
- **The App Manager key uploads but cannot make the App Store profile** ("Cloud signing
  permission error", "No profiles … were found"). One `xcodebuild -exportArchive` with
  `destination` `export` and `-allowProvisioningUpdates` but no key used the Xcode account (the
  Account Holder) to make the profile with the Mac's Apple Distribution certificate; after
  that `release.sh upload` with the key worked unchanged. Processing took about 2 minutes.
- **Read `tasks.md`'s ordering rules before an outward step**: T054 (the full local checks) was
  due before the first upload and ran after it; it passed, so build 1 stands, but the order was
  missed. The `appintentsmetadataprocessor` "Metadata extraction skipped" lines are an Xcode
  notice in every build without App Intents, not a project warning.
- **The record's language comes from the New App dialog**: the owner picked English (Canada)
  first; changing the primary language to English (U.S.) left an empty en-CA localization,
  which had to be deleted (`DELETE /v1/appStoreVersionLocalizations/<id>`) so only en-US
  remains.
- **The API enters almost the whole listing**: app info and version localizations, copyright,
  release type, categories (`GAMES`, `GAMES_BOARD`), the review notes, the age rating
  declaration (13 frequency answers `NONE`, 10 yes/no `false`; Apple then shows `FOUR_PLUS`),
  the price schedule (the free USA price point, others automatic), `POST /v2/appAvailabilities`
  with all 175 territories, What to Test (`betaBuildLocalizations`) and screenshots
  (`APP_IPHONE_61` takes 1206 × 2622; reserve, PUT the parts, commit with the MD5; the first
  took about 10 minutes to reach `COMPLETE`). An invalid enum value in a POST returns the list
  of valid ones. The privacy label, the Mac and Vision Pro switches and the review contact are
  web-only or the owner's data; the review contact can be confirmed as filled through the API
  without reading its values, and the first save of it did not take.
- **Moving an issue to Done closes it**: the board's workflow closed #185 before `gh issue
  close`, which then reported "Could not close the issue"; check the state rather than retry.
- **A feature moves with its first task**: E8's F8.1, F8.2 and F8.3 stayed in Todo while their
  tasks were In Progress or Done, and `update_plan.py --check` cannot see that (it compares the
  plan with the board, not the board with itself). When a task starts, move its feature (and
  epic) to In Progress in the same `board_move.py` call.

## Next steps

`EXECUTION_PLAN.md` holds the ordered work, what is in progress and what is left. A change in
product behavior is made in `FRD.md` first. Move each board item to In Progress before starting it
and to Done when complete, and mirror it in `EXECUTION_PLAN.md`.

1. **Recommended next, for the user: one phone sitting with build 1 from TestFlight**. Build 1
   (`363f98e`) is in the owner's internal group ("checkers test flight group", one tester
   invited, automatic distribution). On HKH16: install TestFlight from the App Store, accept the
   invitation and install Checkers. Then on that install: T034 (approve the icon in light, dark
   and tinted with Home Screen › Edit › Customize; the name reads "Checkers"; launching in light
   and dark shows a plain screen, then Home, without a flash), T012 (Settings › Privacy &
   Security › App Privacy Report on, every screen, both kinds of game, rotation; T012's text
   names a `device.sh launch` install; a TestFlight install of the same commit in Release is the
   build players get, so note which was used) and the release checklist rows for build 1 (T046;
   `checklists/release.md`, RC-01 to RC-27, each passed or accepted with a reason). Last, with
   the phone connected and Low Power Mode off, the agent runs US2's T021 (`scripts/device.sh
   launch`, then `session`; record every number in `validation.md` §5, and whether the hitches
   came from the attached or a launched run; on a miss, T022). `device.sh` installs a
   development-signed build over the TestFlight one, so do it after the TestFlight items and
   reinstall from TestFlight afterwards. Then `release.sh record 1 "TestFlight internal"`.
2. **For the user, at the Mac**: T013, open the build 1 archive (`open
   .build/Release/Checkers-1.0-1.xcarchive`; it carries the icon and the name, unlike T010's)
   in Xcode's Organizer and Generate Privacy Report; T014, the iPad smoke check on the "iPad
   (A16) E8" simulator with that archive's app. With T012 they close #177 and #178; with T034,
   #184.
3. **The external round (T047)**: two to five external testers, at least one new to checkers
   (the rest of T044; the external group "test flight checkers outside group" has one, not
   invited); the What to Test text is already on build 1; the beta app description, feedback
   email and Beta App Review contact are still to enter; submit build 1 (or a later one) for
   Beta App Review (about a day), then a week of testing, the longest wait left.
4. **Without the owner only the slice's polish is left** (T053, T055–T057), best done once the
   owner's checks are in; T048 applies only if the beta finds a problem. T054 ran on `363f98e`
   after build 1's upload (all pass) and runs again before submission. A later build:
   `scripts/release.sh archive <n>` then `upload`; if the export again says "Cloud signing
   permission error", run the local export once with the Xcode account (lessons above). With
   #206 landed, a local `scripts/test.sh` failure on the speed check points to a real slowdown
   (alone the count takes about 4 s; even at this Mac's lowest clock seen, `CPU_Speed_Limit`
   54, that scales to about 8 s, an estimate); time other checks in a settled simulator (#206
   lessons).
5. **The App Store Connect record is complete for submission except the build**: the listing,
   screenshots, privacy label, age rating, price, availability and review contact are in
   (`validation.md` §4); the build is chosen on the version page at submission (US6).
6. **The open hand checks of E3–E8** are the 27 rows of
   `specs/008-release-1-0/checklists/release.md` (RC-01 to RC-27; the earlier slices'
   `validation.md` files point to them), run on TestFlight builds; each must be passed or
   accepted in writing on the submitted build, which `scripts/release.sh submit-check <build>`
   enforces (FR-028).
7. Follow-ups: if the iPhone check of a sound's delay misses 0.1 s, move `SoundBank` to
   `AVAudioEngine` (E6 research R7); keep the CI Xcode pin (26.3) in step with the development
   Mac; any update after Apple requires the iOS 27 SDK (expected around April 2027) needs an Apple
   silicon Mac and Xcode 27.
