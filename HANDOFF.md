# Handoff

Last updated: 2026-10-15

## Current state

- **Repo**: `github.com/iglooo101/checkers`. The repo root is this folder; the Xcode project lives
  in `checkers/` (see `checkers/CLAUDE.md`).
- **Unmerged branch**: `docs/frd` holds the FRD and these handoff updates, local only (not pushed,
  not merged into `main`). Merge or open a PR before starting new work.
- **Constitution**: `.specify/memory/constitution.md`, v1.0.0, ratified 2026-10-15. Nine
  principles (SwiftUI, Swift 6 strict concurrency, test-first, accessibility, privacy, performance,
  dependencies, observability) plus workflow and governance gates.
- **App**: a SwiftUI shell around bundled HTML/JS checkers screens in a `WKWebView`. No test
  target, no CI.
- **Functional requirements**: `FRD.md` at the repo root, v1.0, approved 2026-10-15. It specifies
  how players interact with the target product (vs computer at three levels and two players on one
  device, American rules, undo, auto-save, win/loss record, themes, VoiceOver). Requirements have
  IDs such as `FR-MOVE-03`; section 19 lists what is out of scope.

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
- **Work happens on a branch**: commits go on a feature branch, not straight to `main`.

## Next steps

Every `/speckit-specify` for a user-facing feature MUST take its scope from `FRD.md` and list the
requirement IDs it covers, so coverage of the FRD can be traced. A change in product behavior is
made in `FRD.md` first.

1. Merge `docs/frd` into `main` (fast-forward) or push it and open a PR, as the user prefers.
2. Confirm the constitution values inferred from the codebase: the app description, iPad support,
   and the 400 ms cold-launch budget.
3. Run `/speckit-specify` for a **project foundation** feature: unit and UI test targets, CI that
   blocks on failing tests, warnings and SwiftLint errors, `SWIFT_VERSION = 6` with complete strict
   concurrency, SwiftLint and swift-format, and `PrivacyInfo.xcprivacy`.
4. Decide the future of the HTML/web view UI (migrate to SwiftUI or justify it) and record the
   decision in that plan's Constitution Check.
5. Amend `.specify/templates/tasks-template.md` so tests are mandatory.
6. Clean up template leftovers: the unused `checkers/checkers/Item.swift` and the stray
   `checkers/checkers/Assets.xcassets/CheckersApp.swift`.
7. Split the FRD into Spec Kit features, each specified from its FRD sections: rules engine and
   two-player game (sections 5–10), computer opponent (11), saving and statistics (12–13), then
   settings, themes, sound and the rules screen (14–16). Accessibility (17) and platform/privacy
   (18) apply to every feature.
