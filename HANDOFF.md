# Handoff

Last updated: 2026-10-16

## Working rules (set by the user, 2026-10-16)

- **Keep the board up to date.** Before starting work on any item, move it to **In Progress** on
  the [project board](https://github.com/users/iglooo101/projects/1/views/1); once it is
  complete, move it to **Done** and close the issue.
- **Spec Kit for every slice.** Each epic is one Spec Kit slice: specify → clarify → plan →
  tasks (+ analyze) → implement. No implementation outside that flow.
- **Keep `EXECUTION_PLAN.md` current.** Update it with every board change, and review and revise
  the whole file at every close-out (task, feature, epic, slice, session).
- **No unnecessary pull requests.** This is a solo repo: work on a feature branch, fast-forward
  `main` locally (`git merge --ff-only`) and push.
- **No CI for documentation.** Markdown-only changes must not run build or tests (#10, #12).

## Current state

- **Repo**: `github.com/iglooo101/checkers`. The repo root is this folder; the Xcode project lives
  in `checkers/` (see `checkers/CLAUDE.md` for commands and layout).
- **Branches**: `main` is protected: a commit lands only if the `CI gate` check passed for that
  exact commit (admins included, no pull requests). Work on a feature branch, push it, wait for
  CI, then fast-forward `main` (`git push origin <sha>:main` works without switching branches).
  `001-project-foundation` is fully merged.
- **Constitution**: `.specify/memory/constitution.md`, v1.1.0 (ratified 2026-10-15, amended
  2026-10-16: iPhone only, portrait). Nine principles plus workflow and governance gates.
- **Functional requirements**: `FRD.md` v1.1 (iPhone only, portrait). Requirement IDs such as
  `FR-MOVE-03`; section 19 lists what is out of scope.
- **App**: still the SwiftUI shell around the bundled HTML/JS screens (replaced in E3), now with
  Swift 6, unit/UI/engine test targets, the `CheckersEngine` package (only `Side` so far), a
  privacy manifest, a shared logger, a string catalog and iPhone-only portrait settings.
- **CI**: `.github/workflows/ci.yml` on every push except to `main`; Markdown-only pushes skip the
  build (about 20 s); code pushes take 5–13 minutes.
- **Backlog**: 8 epics, 41 features, 142 tasks (#1–#192; #188 is a PR) on the project board.
  **E1 Project foundation is done** (22/22 board tasks). Progress and the full list are in
  `EXECUTION_PLAN.md`.
- **Spec Kit**: E1's slice is `specs/001-project-foundation/` (validation log in
  `checklists/validation.md`). The active slice is E2's `specs/002-rules-engine/` on branch
  `002-rules-engine` (#31 Specify done). `.specify/feature.json` is local and git-ignored; recreate
  it with `{"feature_directory": "specs/002-rules-engine"}` if missing.

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

## Next steps

`EXECUTION_PLAN.md` holds the ordered work, what is in progress and what is left. Every
`/speckit-specify` takes its scope from `FRD.md` and lists the requirement IDs it covers. A change
in product behavior is made in `FRD.md` first. Move each board item to In Progress before starting
it and to Done when complete, and mirror it in `EXECUTION_PLAN.md`.

1. **E2 Rules engine (#29)** on a new branch `002-rules-engine`: F2.0 specification first —
   #31 Specify (scope: FRD sections 8, 9, 10; done) → #32 Clarify (done) → #33 Plan → #34 Tasks + analyze →
   #35 Reconcile the board. Then implement test-first in `checkers/CheckersEngine`.
2. Epic order after that: E3 → E7 → E4 → E5 → E6 → E8 (see `EXECUTION_PLAN.md`).
3. Follow-ups noted during E1: #71 or #140 adds the UserDefaults entry to the privacy manifest
   when first used; #192 (MetricKit) and #181 (400 ms on a real iPhone) are in E8.
