# Handoff

Last updated: 2026-10-16

## Working rules (set by the user, 2026-10-16)

- **Keep the board up to date.** Every backlog item's status on the
  [project board](https://github.com/users/iglooo101/projects/1/views/1) must match reality as
  work is processed.
- **Spec Kit for every slice.** Each epic is one Spec Kit slice: specify → clarify → plan →
  tasks (+ analyze) → implement. No implementation outside that flow.
- **Keep `EXECUTION_PLAN.md` current.** Update it with every board change, and review and revise
  the whole file at every close-out (task, feature, epic, slice, session).
- **No unnecessary pull requests.** This is a solo repo: work on a feature branch, fast-forward
  `main` locally (`git merge --ff-only`) and push.
- **No CI for documentation.** Markdown-only changes must not run build or tests (#10, #12).

## Current state

- **Repo**: `github.com/iglooo101/checkers`. The repo root is this folder; the Xcode project lives
  in `checkers/` (see `checkers/CLAUDE.md`).
- **Branches**: `main` holds everything (the FRD, execution plan and handoff work landed from
  `docs/frd` through PR #188 by fast-forward). Start new work on a fresh feature branch.
- **Constitution**: `.specify/memory/constitution.md`, v1.0.0, ratified 2026-10-15. Nine
  principles (SwiftUI, Swift 6 strict concurrency, test-first, accessibility, privacy, performance,
  dependencies, observability) plus workflow and governance gates.
- **App**: a SwiftUI shell around bundled HTML/JS checkers screens in a `WKWebView`. No test
  target, no CI.
- **Functional requirements**: `FRD.md` at the repo root, v1.0, approved 2026-10-15. It specifies
  how players interact with the target product (vs computer at three levels and two players on one
  device, American rules, undo, auto-save, win/loss record, themes, VoiceOver). Requirements have
  IDs such as `FR-MOVE-03`; section 19 lists what is out of scope.
- **Backlog**: 8 epics, 41 features, 138 tasks as issues #1–#187 in `iglooo101/checkers`, labeled
  `epic` / `feature` / `task`, nested with sub-issues, assigned to milestones M1–M5, and all on
  the project board (Status, Level, Epic, Priority, Size). Progress and the full list are in
  `EXECUTION_PLAN.md`. Nothing is started yet.

## Lessons learned

- **Spec Kit was initialized twice** (repo root and `checkers/`). The root install is canonical;
  the nested copy was deleted. Run Spec Kit commands and scripts from the repo root.
- **The existing app does not yet comply with the constitution**: UI is HTML in a web view
  (Principle I), `SWIFT_VERSION = 5.0` (Principle IV), no tests or CI (Principle III). Expect the
  first plan's Constitution Check to flag all of these.
- **`tasks-template.md` marks tests "OPTIONAL"**, which conflicts with Principle III. The
  constitution prevails until the template is amended.
- **The app target defaults to `MainActor` isolation** (`SWIFT_DEFAULT_ACTOR_ISOLATION`), so heavy
  work such as game AI must be explicitly moved off the main actor.
- **No Claude/AI attribution** in commits, PRs, code or docs. This is an absolute rule, enforced
  in `~/.claude/settings.json` and `~/.claude/CLAUDE.md`.
- **Commits are authored as `sharelarge <sharelarge@gmail.com>`** (global git identity), while the
  GitHub account is `iglooo101`. They are not linked on GitHub unless that email is added to the
  account.
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
  sets the status. Closing an issue moves it to Done through the board's built-in workflow.
- **The GitHub MCP connector failed to authenticate** in this session; the `gh` CLI covers
  everything needed.

## Next steps

`EXECUTION_PLAN.md` holds the ordered work, what is in progress and what is left. Every
`/speckit-specify` takes its scope from `FRD.md` (or the constitution, for E1) and lists the
requirement IDs it covers. A change in product behavior is made in `FRD.md` first.

1. Start E1 (#1) with its specification feature F1.0 (#2): #3 Specify → #4 Clarify → #5 Plan →
   #6 Tasks + analyze → #7 Reconcile the board with `tasks.md`. Move each item on the board and in
   `EXECUTION_PLAN.md` as it starts and finishes.
2. The earlier loose next steps are now board tasks: confirm constitution values (#27), the
   tasks-template amendment (#26), template leftover cleanup (#24), and the HTML removal (#67,
   after the native board ships).
