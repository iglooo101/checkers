# Validation Log: Project Foundation

Results of the smoke checks (T001, T061) and the quickstart scenarios (T058). Plain tables, not
checkboxes, so this log never blocks `/speckit-implement`'s checklist gate.

## Starting state (T001, 2026-10-16)

| Check | Result |
|---|---|
| App builds and launches on the iPhone 17 simulator (iOS 26.3) | Pass (Debug build, no warnings or errors reported) |
| Segmented control shows Classic, Modern, Playful, Play | Pass (screenshot) |
| Classic board renders on launch | Pass (screenshot) |
| Play screen accepts a move | Not checked by hand (the enabled simulator tools cannot tap); covered by `testUS1_playScreenAcceptsAMove`, which passes |

## Quickstart scenarios (T058, 2026-10-16)

| § | Scenario | Result | Evidence |
|---|---|---|---|
| 1 | `scripts/test.sh` runs unit, UI and engine tests and passes | Pass | 10 tests in 3 bundles locally; CI runs 38985403283, 38986054555 |
| 1 | A failing expectation fails the run and names the test | Pass | Local probe: exit 65, `US1: the four screens are listed in order`; CI probe branch failed the same way |
| 2 | `swift test` in `CheckersEngine` passes without the app | Pass | `US4: each side's opponent is the other side` |
| 2 | `import SwiftUI` under `CheckersEngine/Sources/` fails | Pass | Build failed with `engine_no_ui_imports` |
| 3 | 0 compiler warnings | Pass | Local builds; CI builds with warnings as errors |
| 3 | Force unwrap, `ObservableObject`, `DispatchQueue`, `print(` are lint errors; `print(` allowed in tests | Pass | `test-lint-rules.sh` (all rules, plus `@Published`, `OperationQueue`, `Thread`); local build probe failed on `force_unwrapping` |
| 4 | Unformatted line: build warning, file unchanged; `scripts/format.sh` fixes it | Pass | Local build showed `[Indentation]` warning; `test-format-check.sh` |
| 5 | Failing test, compiler warning, lint error, unformatted line each fail `CI gate` with the cause named | Pass | Probe branches: failing test, `unusedProbe` warning, `force_unwrapping`, `[Indentation]` |
| 5 | Lint warning only: reported, passes | Pass | Probe branch: `todo` warning in the log, gate passed |
| 5 | Markdown-only push: gate passes within 2 minutes, no build | Pass | Commit c0f72a2: build skipped, run took 18 s |
| 5 | Unchecked commit pushed to `main` as owner is rejected | Pass | `GH006 … Required status check "CI gate" is expected` |
| 5 | Fast-forward of a checked branch commit to `main` is accepted, no pull request | Pass | `main` c0f72a2..0e3b084 pushed directly after 0e3b084 passed `CI gate` on its branch |
| 6 | Privacy manifest: no tracking, no domains, no collected data | Pass | `plutil -lint` OK; US5 manifest test. Archive privacy report deferred to #177 (needs signing) |
| 6 | Catalog check fails and names missing keys | Pass | Empty catalog: check listed Classic, Modern, Play, Playful, Screen; `test-string-catalog-check.sh`; CI: "String catalog is up to date" |
| 6 | Logger subsystem and category | Pass | US5 logging test |
| 6 | Missing screen logs an error under subsystem `Hussein-Helmy.checkers`, category `app` | Not run live | Code path added in `WebView.updateUIView`; exercising it needs a broken bundle |
| 6 | iPhone only, portrait only | Pass | US5 platform test reads the built Info.plist; device rotation not tried by hand |
| 7 | Template leftovers gone | Pass | `git grep` finds no `Item`, `SwiftData` or `modelContainer` |
| 7 | Launch duration reported against the baseline | Pass | Local: 3.635 s average (Debug, Intel simulator), baseline recorded; CI: Performance step and report step succeeded |
| 8 | Four screens load; Play accepts a move | Pass | `testUS1_launchShowsFourScreens`, `testUS1_playScreenAcceptsAMove`, locally and in CI |

## Final checks (T061)

| Check | Result |
|---|---|
| SC-005: 0 compiler warnings, 0 lint errors on `main` | Pass: `main` commits passed CI with warnings as errors and lint errors failing |
| SC-006: full code CI run under 20 minutes | Pass: 5–13 minutes |
| SC-007: same result as the T001 smoke check | Pass: UI tests above |
| FR-015: no network, account, analytics or permission code added | Pass: no matches in the slice's diff (68 files) |
