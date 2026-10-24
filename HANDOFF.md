# Handoff

Last updated: 2026-10-24

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
  `006-saving-and-statistics` were merged and deleted (the auto-mode safety check blocks branch
  deletion, so the user runs it once the next slice's branch exists). `main` (local and GitHub)
  is at `977f5e6`, E5's close-out plus a plan fix. **E6 is under way on
  `007-settings-themes-sound-and-rules`** (pushed, `CI gate` green on every commit): spec,
  clarify and plan done, `tasks.md` written and analyzed, the 12 analysis findings applied
  (#137, 9b881b9) and the board reconciled (#138; F6.0 done). **Implementation**: Setup,
  Foundational and US1 (T001–T010) are on the branch, CI run 40069158202 green; US2 (T011–T015)
  passed every test in CI run 40071432056, but `build-and-test` reached its 30-minute limit, so
  **#204 (T036) raises it to 45 minutes and re-runs CI for US2**. **US3 (T016–T020) and the
  US4 drafts are only on the local branch `wip/007-us3-themes`** (commit `ca00675`, not pushed):
  US3's tests pass except `testUS5_auditSettings`. The slice branch's working tree is clean.
- **Constitution**: `.specify/memory/constitution.md`, v1.1.0 (ratified 2026-10-15, amended
  2026-10-16: iPhone only, portrait). Nine principles plus workflow and governance gates.
- **Functional requirements**: `FRD.md` v1.3 (1.1: iPhone only, portrait; 1.2: FR-STAT-06, an
  unreadable record is reported once; 1.3: FR-SND-05, sounds that cannot play are reported in
  Settings and retried with the next sound). Requirement IDs such as
  `FR-MOVE-03`; section 19 lists what is out of scope.
- **App**: **fully native SwiftUI** (E3): Home, Game setup, a two-player game screen (tap and
  drag, hints, chains, crowning, undo, resign, result panel, Play again), Statistics (E5), and
  since E6 Settings (move hints so far) and Rules (seven sections with engine-built pictures);
  the placeholders and the web prototype are gone. **E6 so far**: `SettingsValues` and
  `AppSettings` (`Features/Settings/`) in `UserDefaults` under `boardTheme`, `soundEffects` and
  `moveHints`, read per key (an unreadable one takes its default, logged); the router hands
  `settings` to every session, and with hints off `hintedPieces` and `targets` are empty;
  `RulesContent` and `RulesView` (`Features/Rules/`), whose texts a test checks against
  `specs/007-…/contracts/rules-content.md`; `BoardPicture` (`Features/Game/`) draws still
  boards; UI tests pass settings as typed launch arguments (`launch(settings:)`,
  `setSwitch(_:isOn:)` in `AppScreens`). `GameSession` and
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
- **Backlog**: 8 epics, 41 features, 153 tasks (#1–#203; #188 is a PR) on the project board.
  E6: #140 Done; #141, #142, #144, #145, #150–#152 and #203 In Progress, with F6.1, F6.2 and
  F6.4.
  **E1 Project foundation, E2 Rules engine, E3 Game experience, E7 Accessibility and E4 Computer
  opponent and E5 Saving and statistics are done** (E5: #114, final CI run 40040004817, 264
  tests). **E6 (#132) is in progress**: F6.0 (#133) is done (#134–#138); F6.1 to F6.4 are under
  way, with #203 (validate the slice and update docs) under F6.4; E8 is left (33/41 features,
  128/153 tasks). Progress and the full list are in
  `EXECUTION_PLAN.md`.
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
  ring the other movable pieces)**. `.specify/feature.json` (local, git-ignored) points at it.

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

## Next steps

`EXECUTION_PLAN.md` holds the ordered work, what is in progress and what is left. Every
`/speckit-specify` takes its scope from `FRD.md` and lists the requirement IDs it covers. A change
in product behavior is made in `FRD.md` first. Move each board item to In Progress before starting
it and to Done when complete, and mirror it in `EXECUTION_PLAN.md`.

1. **E6: check the CI run for #204** (the 45-minute limit, which also re-checks US2). If it is
   green, comment on and close #204, #151 (T012, T013, T015 are all done) and #150 (T011, T014,
   T015), and fast-forward `main`; #152 waits for T029–T030.
2. **E6 US3** with `/speckit-implement`: bring `wip/007-us3-themes` onto the slice branch
   (`git checkout 007-settings-themes-sound-and-rules && git merge --squash wip/007-us3-themes`,
   then move `wip-drafts/` out of the commit), fix the Settings audit's contrast issues on the
   Classic theme row (see Risks in `EXECUTION_PLAN.md`), mark T016–T020 done, push, and run T021
   (the user's visual review of Modern and Playful, with screenshots). Then US4 (T022–T028) from
   the drafts in `wip-drafts/` (`make-sounds.py` to `scripts/`, the three sound files to
   `Features/Sound/`, the tests to their targets; then `GameSession`, the router, `CheckersApp`
   and the Sound section of Settings per T027), the user's listening review (T028), and Polish
   (T029–T035). Board tasks per story are in `tasks.md` "Board Mapping"; #141 closes after T020
   and T027, #142 and #152 after T029–T030. Delete `wip/007-us3-themes` once merged (the user
   runs `git branch -D`).
3. **During E6 implementation the user approves** the Modern and Playful colors (T021, quickstart
   §4) and the four sounds (T028: `afplay` the files T025 generates). On an iPhone: a sound's delay,
   silent mode and other apps' music (quickstart §5). Then E8 (#169).
4. Open for the user:
   - Play the computer at each level: the playtest (`specs/005-computer-opponent/quickstart.md`
     §4, SC-004) checks that a beginner can beat Easy and that Hard challenges an experienced
     casual player. If Easy proves too strong, widen its margin, or revisit random blunders as
     research R4 notes.
   - A VoiceOver game by hand (`specs/004-accessibility/quickstart.md` §3), and from E3 a
     hand-played game and a visual review at the largest text size.
   - E4's SC-005 needs a recent iPhone with a Release build; without one, the Mac measurement is
     recorded as the closest proxy (Hard's slowest turn 419 ms in Release).
   - E4 quickstart §3, last step: press Home while the computer thinks and come back; it should
     make exactly one reply. UI tests cannot press Home inside the half-second thinking.
   - E4 quickstart §6: a few moves against the computer with VoiceOver on.
   - E5 (`specs/006-saving-and-statistics/checklists/validation.md`): close the app from the app
     switcher and Continue; press Home while the computer thinks, then Continue; finish games by
     hand at Easy and Medium and check Statistics; VoiceOver reads each Statistics block as one
     sentence.
5. Follow-ups: #192 (MetricKit, which can report E6's `sound` and `settings` errors) and #181
   (400 ms on a real iPhone) are in E8; if the iPhone check of a sound's delay misses 0.1 s, move
   `SoundBank` to `AVAudioEngine` (E6 research R7); keep the CI Xcode pin (26.3) in step with the
   development Mac.
