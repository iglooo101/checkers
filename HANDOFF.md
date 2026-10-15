# Handoff

Last updated: 2026-10-15

## Current state

- **Repo**: `github.com/iglooo101/checkers`, branch `main`. The repo root is this folder; the Xcode
  project lives in `checkers/` (see `checkers/CLAUDE.md`).
- **Constitution**: `.specify/memory/constitution.md`, v1.0.0, ratified 2026-10-15. Nine
  principles (SwiftUI, Swift 6 strict concurrency, test-first, accessibility, privacy, performance,
  dependencies, observability) plus workflow and governance gates.
- **App**: a SwiftUI shell around bundled HTML/JS checkers screens in a `WKWebView`. No test
  target, no CI.

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

## Next steps

1. Confirm the constitution values inferred from the codebase: the app description, iPad support,
   and the 400 ms cold-launch budget.
2. Run `/speckit-specify` for a **project foundation** feature: unit and UI test targets, CI that
   blocks on failing tests, warnings and SwiftLint errors, `SWIFT_VERSION = 6` with complete strict
   concurrency, SwiftLint and swift-format, and `PrivacyInfo.xcprivacy`.
3. Decide the future of the HTML/web view UI (migrate to SwiftUI or justify it) and record the
   decision in that plan's Constitution Check.
4. Amend `.specify/templates/tasks-template.md` so tests are mandatory.
5. Clean up template leftovers: the unused `checkers/checkers/Item.swift` and the stray
   `checkers/checkers/Assets.xcassets/CheckersApp.swift`.
