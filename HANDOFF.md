# Handoff

Last updated: 2026-10-21

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
  branches). `001-project-foundation` was merged and deleted; `002-rules-engine` is merged into
  `main` (level with it) and can be deleted once E3's branch exists.
- **Constitution**: `.specify/memory/constitution.md`, v1.1.0 (ratified 2026-10-15, amended
  2026-10-16: iPhone only, portrait). Nine principles plus workflow and governance gates.
- **Functional requirements**: `FRD.md` v1.1 (iPhone only, portrait). Requirement IDs such as
  `FR-MOVE-03`; section 19 lists what is out of scope.
- **App**: still the SwiftUI shell around the bundled HTML/JS screens (replaced in E3), with
  Swift 6, unit/UI/engine test targets, a privacy manifest, a shared logger, a string catalog and
  iPhone-only portrait settings. The **`CheckersEngine` package holds the complete rules engine**
  (E2): `GameState` with `apply`, `resign`, `undo` and the legal-step queries; public API in
  `specs/002-rules-engine/contracts/engine-api.md`.
- **CI**: `.github/workflows/ci.yml` on every push except to `main`; Markdown-only pushes skip the
  build (about 20 s); code pushes take 5–13 minutes.
- **Backlog**: 8 epics, 41 features, 145 tasks (#1–#195; #188 is a PR) on the project board.
  **E1 Project foundation and E2 Rules engine are done**. **E3 Game experience** (#57) is in
  progress: its specification feature F3.0 is done (#59–#63); implementation is next. Progress
  and the full list are in `EXECUTION_PLAN.md`.
- **Spec Kit**: E1's slice is `specs/001-project-foundation/` (validation log in
  `checklists/validation.md`). The active slice is E2's `specs/002-rules-engine/` on branch
  `002-rules-engine`: spec, plan, 37 tasks and validation are all done. The active slice is
  E3's `specs/003-game-experience/` on branch `003-game-experience`: spec (7 stories, 42
  requirements, 3 clarifications), plan (research R1–R14, data model, contracts
  `game-session.md` and `screens.md`, quickstart) and 60 analyzed tasks are done.
  `.specify/feature.json` is local and git-ignored; recreate it with
  `{"feature_directory": "specs/003-game-experience"}` if missing.

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

- **`swift test` does not run SwiftLint.** The SwiftLint plugin's prebuild command never runs
  under `swift build`/`swift test`; only the Xcode build lints the engine (`scripts/test.sh`, CI).
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

## Next steps

`EXECUTION_PLAN.md` holds the ordered work, what is in progress and what is left. Every
`/speckit-specify` takes its scope from `FRD.md` and lists the requirement IDs it covers. A change
in product behavior is made in `FRD.md` first. Move each board item to In Progress before starting
it and to Done when complete, and mirror it in `EXECUTION_PLAN.md`.

1. **E3 Game experience (#57)**, branch `003-game-experience`: **next is `/speckit-implement`**,
   story by story (setup and foundation, US1 → US7, polish). Move each story's board tasks to In
   Progress first (mapping at the end of `tasks.md`); push after each story and wait for CI.
   Spec Kit's `create_new_feature.py` creates no git branch; create slice branches with
   `git checkout -b`.
2. Epic order after E3: E7 → E4 → E5 → E6 → E8 (see `EXECUTION_PLAN.md`). E4's search should
   profile the engine first (see the speed risk in `EXECUTION_PLAN.md`).
3. Follow-ups: #71 or #140 adds the UserDefaults entry to the privacy manifest when first used;
   #192 (MetricKit) and #181 (400 ms on a real iPhone) are in E8; keep the CI Xcode pin (26.3)
   in step with the development Mac.
