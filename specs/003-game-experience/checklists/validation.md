# Validation: Game Experience

Results of the scenarios in [../quickstart.md](../quickstart.md), recorded during implementation
on the development Mac (Intel Core i9-9980HK, Xcode 26.3, iPhone 17 simulator on iOS 26.3),
starting 2026-10-21.

## Baseline (T001–T006)

| Check | Result | Notes |
|---|---|---|
| `scripts/test.sh` after Phases 1–2 | Pass | 75 of 75 tests (app unit and UI, engine), 3 min 37 s; the app still shows the web prototype |
| `scripts/sync-string-catalog.sh` on the current catalog | Pass | "String catalog already matches the last build."; `check-string-catalog.sh` passes afterwards |
| Engine initializers public (T002) | Pass | `GamePositionsTests` failed to compile against the internal initializers, then passed; engine suite 63 of 63 |
| Launch baseline | Recorded | 3.635 s (local Intel simulator, Debug), from `checkers/launch-baselines.json` |

## 1. All automated tests (SC-002)

| Check | Result | Notes |
|---|---|---|
| `scripts/test.sh` after T055 | Pass | 130 of 130 (app unit and UI, engine), zero warnings, zero SwiftLint errors; 5 min 26 s locally |
| `scripts/tests/run.sh` | Pass | 6 of 6 script tests |
| `scripts/check-format.sh --strict` | Pass | |
| FRD IDs named by app tests | Pass | Every ID in the spec's traceability table: FR-NAV-01–04, FR-SETUP-01–03, 06, FR-GAME-01–07, FR-MOVE-01–05, FR-AID-01–04, FR-CHAIN-01–03, FR-RULE-07, FR-END-01–04, 06, 07, FR-UNDO-01, 02, 05, 06, FR-SND-04, FR-PLAT-01, 03, FR-A11Y-04; FR-006 by `NoWebContentTests` |

## 2. One story at a time (US1–US7)

| Story | Result | Notes |
|---|---|---|
| US1–US7 | Pass | Each story's unit suite and UI test class were run on their own while implementing it (`-only-testing`), observed failing first, then passing; all pass together in §1 |

## 3. Play a game by hand (SC-001)

| Check | Result | Notes |
|---|---|---|
| Two-player game from launch to the result panel by taps and drags | Automated | UI tests cover each step: tapped and dragged moves (US1, US3), the capture-required indicator and notice after `c3–d4, f6–e5` (US2), undo back to the start (US5), resign with confirm and cancel, the result panel and Play again (US4), setup choices across a relaunch (US6), Rules/Settings return and the leave confirmation (US7). Multi-jumps and crowning are covered by `US2CaptureChainTests` |
| A full game played by hand | *Moved to E8 release checklist RC-01* | Not done by the implementer; the quickstart §3 list is the script |

## 4. Screen sizes and text sizes (SC-003, SC-006)

| Check | Result | Notes |
|---|---|---|
| Game screen on iPhone SE (3rd generation), default text (T029) | Pass | `testUS1_boardFitsAndShowsOnlyTheIndicator` and `US2CaptureUITests`: board square, inside the window, squares at least 44 points |
| Game screen on iPhone 17 Pro Max, default text (T029) | Pass | Same tests |
| Game screen on iPhone SE at `accessibility-extra-extra-extra-large`, Dark Mode (T029) | Pass | `US1`, `US2` and `US3` UI tests all pass: board fits with 44-point squares, labels and indicator correct, tap and drag work |
| Previews (T029) | Written | `GameView`, `BoardView`, `PieceView`: start, capture required with notice, selection with targets, Dark at the bottom with kings, `accessibility5`, dark |
| Visual review of the large-text layout | *Moved to E8 release checklist RC-02* | The automated checks above show every control reachable and the board fitting; how it looks is for a person to judge (previews in Xcode, or the SE simulator at the largest size) |
| Result panel and resign alert on iPhone SE at `accessibility-extra-extra-extra-large`, Dark Mode (T035) | Pass | `US4GameEndUITests` passes: alert buttons, result text and both result buttons found and tapped; previews for all six results at `accessibility5` and dark |
| Resign confirmation as an alert (T035) | Changed | On iOS 26 a confirmation dialog from a toolbar item shows as a popover without Cancel (*measured*), so resign uses an alert; research R10 updated |
| Setup on iPhone SE at `accessibility-extra-extra-extra-large`, Dark Mode (T046) | Pass | `US6SetupUITests` passes after scrolling: the form is taller than the screen at this size and creates rows as they scroll into view, so the test scrolls to each choice; it also passes at default size on iPhone 17 |
| Home, navigation and placeholders on iPhone SE at `accessibility-extra-extra-extra-large`, Dark Mode (T053) | Pass | `US7NavigationUITests` (menu, Rules/Settings return, leave confirmation, placeholders, largest text size) and `US5UndoUITests` pass |
| Largest text size from a launch argument on iPhone 17 (T049) | Pass | `testUS7_largestTextSize`: Home, setup, the game menu and the result panel buttons all hittable; board inside the window |

## 5. No web content and launch time (SC-005, FR-006)

| Check | Result | Notes |
|---|---|---|
| `find checkers/checkers -name '*.html' -o -name '*.wav'` | Pass | 0 files |
| `grep -rn 'WebKit\|WKWebView' checkers/checkers` | Pass | 0 lines |
| Cold launch, Performance test plan | Pass | 2.108 s average of 5 runs, baseline 3.635 s (−42%), local Intel simulator, Debug |

## 6. Privacy and the string catalog

| Check | Result | Notes |
|---|---|---|
| String extraction (T054) | Fixed | From a `switch` expression with an optional result the compiler extracted only one literal (*measured* in the `.stringsdata`): `GameText.result` and `PlaceholderText` now use explicit `return`s, and all 9 strings are extracted |
| Old picker strings (T055) | Removed | `Classic`, `Modern`, `Play`, `Playful`, `Screen` are gone; untranslated keys that are no longer extracted are dropped by `xcstringstool sync` |
| `check-string-catalog.sh` after T055 | Pass | "String catalog is up to date." |
| `PrivacyManifestTests` (T041) | Pass | Exactly the user-defaults API, reason `CA92.1`; no tracking or collected data |

*Full scenario pending (T057).*

## 7. CI

| Check | Result | Notes |
|---|---|---|
| `CI gate` on `e3c0c2b` (US7, the last code commit) | Pass | Run 39708152757: on a clean build, 52 app unit tests in 16 suites, the 63 engine tests and every UI test passed with warnings as errors; "String catalog is up to date."; launch timing passed |
| Earlier story runs | Pass | 39693689326 (US1–US2), 39695274493 (US3), 39696916008 (US4), 39706223322 (US5–US6) |
