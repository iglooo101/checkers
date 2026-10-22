# Handoff

Last updated: 2026-10-22

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
  `git fetch origin main:main` before comparing branches. `001-project-foundation` was merged and
  deleted; `002-rules-engine`, `003-game-experience` and `004-accessibility` are merged into
  `main` and can be deleted (the auto-mode safety check blocked the deletion; the command is in
  Next steps). E4 is on **`005-computer-opponent`**.
- **Constitution**: `.specify/memory/constitution.md`, v1.1.0 (ratified 2026-10-15, amended
  2026-10-16: iPhone only, portrait). Nine principles plus workflow and governance gates.
- **Functional requirements**: `FRD.md` v1.1 (iPhone only, portrait). Requirement IDs such as
  `FR-MOVE-03`; section 19 lists what is out of scope.
- **App**: **fully native SwiftUI** (E3): Home, Game setup, a two-player game screen (tap and
  drag, hints, chains, crowning, undo, resign, result panel, Play again) and placeholder
  Statistics, Rules and Settings screens; the web prototype is gone. `GameSession` and
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
  of 100 against Medium. Setup defaults to Computer, Easy, Light and remembers choices when a
  game starts.
  **Accessibility** (E7): every dark square is a VoiceOver element with its state ("c3, Light
  man, can move"), double-tap plays square by square, each step, undo and resignation is
  announced once through the `Announcer` seam, and focus follows each step. Pieces and marks
  keep 3:1 contrast with side-specific crowns, and an audit test checks every screen (allow-list
  in `specs/004-accessibility/plan.md`).
- **CI**: `.github/workflows/ci.yml` on every push except to `main`; Markdown-only pushes skip the
  build (about 20 s); code pushes take 15–30 minutes with the UI tests and audits. Since E4 US2 a
  second job, `engine-strength`, runs the Release-only strength matches in parallel, and
  `CI gate` requires both (`scripts/ci/gate.sh` takes four results).
- **Backlog**: 8 epics, 41 features, 150 tasks (#1–#200; #188 is a PR) on the project board.
  **E1 Project foundation, E2 Rules engine, E3 Game experience and E7 Accessibility are done**;
  **E4 Computer opponent** (#95) is in progress. Progress and the full list are in
  `EXECUTION_PLAN.md`.
- **Spec Kit**: E1's slice is `specs/001-project-foundation/` (validation log in
  `checklists/validation.md`), E2's `specs/002-rules-engine/` and E3's
  `specs/003-game-experience/` (60 tasks, validation in `checklists/validation.md`; a hand-played
  game and a visual review at large text are left for the user) and E7's
  `specs/004-accessibility/` (26 tasks, validation in `checklists/validation.md`; a VoiceOver game
  by hand is left for the user). E4's slice is `specs/005-computer-opponent/`: spec (3
  clarifications), plan with measured research R1–R14, contracts `computer-player.md` and
  `computer-turn.md`, 35 tasks; **T001–T021 (Setup, Foundational, US1, US2) are done**,
  measurements and results in `checklists/validation.md`. `.specify/feature.json` (local, git-ignored) points at
  it.

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

## Next steps

`EXECUTION_PLAN.md` holds the ordered work, what is in progress and what is left. Every
`/speckit-specify` takes its scope from `FRD.md` and lists the requirement IDs it covers. A change
in product behavior is made in `FRD.md` first. Move each board item to In Progress before starting
it and to Done when complete, and mirror it in `EXECUTION_PLAN.md`.

1. **E4 Computer opponent (#95)**, branch `005-computer-opponent`, `specs/005-computer-opponent/`:
   - **US3 (T022–T023, #110)**: the UI stays responsive while the computer thinks (menu, Undo,
     Home).
   - Then US4 (T024–T026, #112, #113), US5 (T027–T028, #190) and Polish (T029–T035, #200), and
     fast-forward `main`. T031 runs the strength matches again, and T032 updates
     `checkers/CLAUDE.md` (its line saying `swift test` does not lint is out of date).
2. Epic order after E4: E5 → E6 → E8 (see `EXECUTION_PLAN.md`). New screens join
   `US5AccessibilityAuditUITests` (#131, #142, #152); E6's themes must pass `US4ContrastTests`
   (#144).
3. Open for the user:
   - Play the computer at each level: the playtest (`specs/005-computer-opponent/quickstart.md`
     §4, SC-004) checks that a beginner can beat Easy and that Hard challenges an experienced
     casual player. If Easy proves too strong, widen its margin, or revisit random blunders as
     research R4 notes.
   - A VoiceOver game by hand (`specs/004-accessibility/quickstart.md` §3), and from E3 a
     hand-played game and a visual review at the largest text size.
   - E4's SC-005 needs a recent iPhone with a Release build; without one, the Mac measurement is
     recorded as the closest proxy.
   - Delete the merged branches:
     `git branch -d 002-rules-engine 003-game-experience 004-accessibility && GH_TOKEN="$(tr -d '[:space:]' < ../secrets/github.txt)" git push origin --delete 002-rules-engine 003-game-experience 004-accessibility`.
4. Follow-ups: E5 replaces E3's leave confirmation with saving and Continue; E6 replaces the
   Settings and Rules placeholders; #192 (MetricKit) and #181 (400 ms on a real iPhone) are in
   E8; keep the CI Xcode pin (26.3) in step with the development Mac.
